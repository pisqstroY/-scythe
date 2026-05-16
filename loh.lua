
if not WYNF_OBFUSCATED then
    WYNF_ENC_STRING          = function(str) return str end
    WYNF_ENC_NUM             = function(num) return num end
    WYNF_JIT                 = function(fn)  return fn  end
    WYNF_JIT_MAX             = function(fn)  return fn  end
    WYNF_NO_VIRTUALIZE       = function(fn)  return fn  end
    WYNF_IS_CALLER_WYNFUSCATE = function()   return true end
    WYNF_LINE                = function()    return 0   end
    WYNF_CRASH               = function()    error("crash") end
    WYNF_SECURE_CALL         = function(fn)  return fn  end
    WYNF_SECURE_CALLBACK     = function(fn)  return fn  end
end

local Library = loadstring(game:HttpGet(
    WYNF_ENC_STRING('https://raw.githubusercontent.com/pisqstroY/-scythe/refs/heads/main/ScytheLib.lua')
))()

-- ══════════════════════════════════════════════════════════════════════════════
--  GLOW / WATERMARK CONFIG
-- ══════════════════════════════════════════════════════════════════════════════

local Cfg = {
    WmGlowOn       = true,
    WinGlowOn      = true,
    Speed          = 1.0,
    WmSpread       = 5,
    WmOpacity      = 0.55,
    WinOpacity     = 0.6,
    IsRainbowTheme = false,
}

-- ══════════════════════════════════════════════════════════════════════════════
--  SAVEMANAGER
-- ══════════════════════════════════════════════════════════════════════════════

local SaveManager = (function()
    local httpService = game:GetService('HttpService')
    local SaveManager = {}

    SaveManager.Folder = 'Scythe V2'
    SaveManager.Ignore = {}

    SaveManager.Parser = {
        Toggle = {
            Save = function(idx, object)
                return { type = 'Toggle', idx = idx, value = object.Value }
            end,
            Load = function(idx, data)
                if Toggles[idx] then
                    task.spawn(function()
                        pcall(function()
                            if Toggles[idx].Value ~= data.value then
                                Toggles[idx]:SetValue(data.value)
                            else
                                Toggles[idx]:SetValue(not data.value)
                                task.wait(0.05)
                                Toggles[idx]:SetValue(data.value)
                            end
                        end)
                    end)
                end
            end,
        },
        Slider = {
            Save = function(idx, object)
                return { type = 'Slider', idx = idx, value = object.Value }
            end,
            Load = function(idx, data)
                if Options[idx] then
                    task.spawn(function()
                        pcall(function()
                            local val = tonumber(data.value) or 0
                            Options[idx]:SetValue(val + 0.001)
                            task.wait(0.05)
                            Options[idx]:SetValue(val)
                        end)
                    end)
                end
            end,
        },
        Dropdown = {
            Save = function(idx, object)
                return { type = 'Dropdown', idx = idx, value = object.Value, mutli = object.Multi }
            end,
            Load = function(idx, data)
                if Options[idx] then
                    task.spawn(function()
                        pcall(function()
                            Options[idx]:SetValue(nil)
                            task.wait(0.05)
                            Options[idx]:SetValue(data.value)
                        end)
                    end)
                end
            end,
        },
        ColorPicker = {
            Save = function(idx, object)
                return { type = 'ColorPicker', idx = idx, value = object.Value:ToHex(), transparency = object.Transparency }
            end,
            Load = function(idx, data)
                if Options[idx] then
                    task.spawn(function()
                        pcall(function()
                            Options[idx]:SetValueRGB(Color3.fromHex(data.value), data.transparency)
                        end)
                    end)
                end
            end,
        },
        KeyPicker = {
            Save = function(idx, object)
                return { type = 'KeyPicker', idx = idx, mode = object.Mode, key = object.Value }
            end,
            Load = function(idx, data)
                if Options[idx] then
                    task.spawn(function()
                        pcall(function()
                            Options[idx]:SetValue({ data.key, data.mode })
                        end)
                    end)
                end
            end,
        },
        Input = {
            Save = function(idx, object)
                return { type = 'Input', idx = idx, text = object.Value }
            end,
            Load = function(idx, data)
                if Options[idx] and type(data.text) == 'string' then
                    task.spawn(function()
                        pcall(function()
                            Options[idx]:SetValue(data.text)
                        end)
                    end)
                end
            end,
        },
    }

    function SaveManager:SetIgnoreIndexes(list)
        for _, key in next, list do
            self.Ignore[key] = true
        end
    end

    function SaveManager:SetFolder(folder)
        self.Folder = folder
        self:BuildFolderTree()
    end

    function SaveManager:Save(name)
        if not name then return false, 'no config file is selected' end
        local fullPath = self.Folder .. '/settings/' .. name .. '.json'
        local data = { objects = {} }

        for idx, toggle in next, Toggles do
            if self.Ignore[idx] then continue end
            table.insert(data.objects, self.Parser[toggle.Type].Save(idx, toggle))
        end

        for idx, option in next, Options do
            if not self.Parser[option.Type] then continue end
            if self.Ignore[idx] then continue end
            table.insert(data.objects, self.Parser[option.Type].Save(idx, option))
        end

        local success, encoded = pcall(httpService.JSONEncode, httpService, data)
        if not success then return false, 'failed to encode data' end
        writefile(fullPath, encoded)
        return true
    end

    function SaveManager:Load(name)
        if not name then return false, 'no config file is selected' end
        local file = self.Folder .. '/settings/' .. name .. '.json'
        if not isfile(file) then return false, 'invalid file' end
        local success, decoded = pcall(httpService.JSONDecode, httpService, readfile(file))
        if not success then return false, 'decode error' end

        task.spawn(function()
            task.wait(0.1)
            for _, option in next, decoded.objects do
                if self.Parser[option.type] then
                    self.Parser[option.type].Load(option.idx, option)
                    task.wait(0.02)
                end
            end
        end)

        return true
    end

    function SaveManager:IgnoreThemeSettings()
        self:SetIgnoreIndexes({
            'BackgroundColor', 'MainColor', 'AccentColor', 'OutlineColor', 'FontColor',
            'ThemeManager_ThemeList',
        })
    end

    function SaveManager:BuildFolderTree()
        local paths = { self.Folder, self.Folder .. '/themes', self.Folder .. '/settings' }
        for i = 1, #paths do
            if not isfolder(paths[i]) then makefolder(paths[i]) end
        end
    end

    function SaveManager:RefreshConfigList()
        local list = listfiles(self.Folder .. '/settings')
        local out = {}
        for i = 1, #list do
            local file = list[i]
            if file:sub(-5) == '.json' then
                local pos   = file:find('.json', 1, true)
                local start = pos
                local char  = file:sub(pos, pos)
                while char ~= '/' and char ~= '\\' and char ~= '' do
                    pos  = pos - 1
                    char = file:sub(pos, pos)
                end
                if char == '/' or char == '\\' then
                    table.insert(out, file:sub(pos + 1, start - 1))
                end
            end
        end
        return out
    end

    function SaveManager:SetLibrary(library)
        self.Library = library
    end

    function SaveManager:LoadAutoloadConfig()
        if isfile(self.Folder .. '/settings/autoload.txt') then
            local name = readfile(self.Folder .. '/settings/autoload.txt')
            task.delay(0.5, function()
                local success, err = self:Load(name)
                if not success then
                    return self.Library:Notify('Failed to load autoload config: ' .. err)
                end
                self.Library:Notify(string.format('Auto loaded config %q', name))
            end)
        end
    end

    function SaveManager:BuildConfigSection(tab)
        assert(self.Library, 'Must set SaveManager.Library')
        local section = tab:AddRightGroupbox('Configuration')

        section:AddDropdown('SaveManager_ConfigList', {
            Text     = 'Config list',
            Values   = self:RefreshConfigList(),
            AllowNull = true,
        })
        section:AddInput('SaveManager_ConfigName', { Text = 'Config name' })
        section:AddDivider()

        section:AddButton('Create config', function()
            local name = Options.SaveManager_ConfigName.Value
            if name:gsub(' ', '') == '' then
                return self.Library:Notify('Invalid config name (empty)', 2)
            end
            local success, err = self:Save(name)
            if not success then return self.Library:Notify('Failed to save config: ' .. err) end
            self.Library:Notify(string.format('Created config %q', name))
            Options.SaveManager_ConfigList.Values = self:RefreshConfigList()
            Options.SaveManager_ConfigList:SetValues()
            Options.SaveManager_ConfigList:SetValue(nil)
        end):AddButton('Load config', function()
            local name = Options.SaveManager_ConfigList.Value
            local success, err = self:Load(name)
            if not success then return self.Library:Notify('Failed to load config: ' .. err) end
            self.Library:Notify(string.format('Loaded config %q', name))
        end)

        section:AddButton('Overwrite config', function()
            local name = Options.SaveManager_ConfigList.Value
            local success, err = self:Save(name)
            if not success then return self.Library:Notify('Failed to overwrite config: ' .. err) end
            self.Library:Notify(string.format('Overwrote config %q', name))
        end)

        section:AddButton('Autoload config', function()
            local name = Options.SaveManager_ConfigList.Value
            writefile(self.Folder .. '/settings/autoload.txt', name)
            SaveManager.AutoloadLabel:SetText('Current autoload config: ' .. name)
            self.Library:Notify(string.format('Set %q to auto load', name))
        end)

        section:AddButton('Refresh config list', function()
            Options.SaveManager_ConfigList.Values = self:RefreshConfigList()
            Options.SaveManager_ConfigList:SetValues()
            Options.SaveManager_ConfigList:SetValue(nil)
        end)

        section:AddDivider()

        section:AddButton('Force Apply', function()
            task.spawn(function()
                for _, toggle in pairs(Toggles) do
                    pcall(function()
                        local state = toggle.Value
                        toggle:SetValue(not state)
                        task.wait(0.05)
                        toggle:SetValue(state)
                    end)
                    task.wait(0.02)
                end
                for _, option in pairs(Options) do
                    pcall(function()
                        if option.Type == 'Slider' then
                            local val = option.Value
                            option:SetValue(val + 0.001)
                            task.wait(0.05)
                            option:SetValue(val)
                        elseif option.Type == 'Dropdown' then
                            local val = option.Value
                            option:SetValue(nil)
                            task.wait(0.05)
                            option:SetValue(val)
                        elseif option.Type == 'ColorPicker' then
                            option:SetValueRGB(option.Value, option.Transparency)
                        elseif option.Type == 'KeyPicker' then
                            option:SetValue({ option.Value, option.Mode })
                        end
                    end)
                    task.wait(0.02)
                end
                self.Library:Notify('Config Force Applied!', 3)
            end)
        end)

        SaveManager.AutoloadLabel = section:AddLabel('Current autoload config: none', true)
        if isfile(self.Folder .. '/settings/autoload.txt') then
            local name = readfile(self.Folder .. '/settings/autoload.txt')
            SaveManager.AutoloadLabel:SetText('Current autoload config: ' .. name)
        end

        SaveManager:SetIgnoreIndexes({ 'SaveManager_ConfigList', 'SaveManager_ConfigName' })
    end

    SaveManager:BuildFolderTree()
    return SaveManager
end)()

-- ══════════════════════════════════════════════════════════════════════════════
--  THEMEMANAGER  — built-in themes only, no file system
-- ══════════════════════════════════════════════════════════════════════════════

local ThemeManager = (function()
    local httpService = game:GetService('HttpService')
    local ThemeManager = {}

    ThemeManager.Library = nil
    ThemeManager.BuiltInThemes = {
        ['Default']     = { 1, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"1c1c1c","AccentColor":"ffffff","BackgroundColor":"141414","OutlineColor":"323232"}') },
        ['BBot']        = { 2, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"1e1e1e","AccentColor":"7e48a3","BackgroundColor":"232323","OutlineColor":"141414"}') },
        ['Fatality']    = { 3, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"1e1842","AccentColor":"c50754","BackgroundColor":"191335","OutlineColor":"3c355d"}') },
        ['Jester']      = { 4, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"242424","AccentColor":"db4467","BackgroundColor":"1c1c1c","OutlineColor":"373737"}') },
        ['Mint']        = { 5, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"242424","AccentColor":"3db488","BackgroundColor":"1c1c1c","OutlineColor":"373737"}') },
        ['Tokyo Night'] = { 6, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"191925","AccentColor":"6759b3","BackgroundColor":"16161f","OutlineColor":"323232"}') },
        ['Ubuntu']      = { 7, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"3e3e3e","AccentColor":"e2581e","BackgroundColor":"323232","OutlineColor":"191919"}') },
        ['Quartz']      = { 8, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"232330","AccentColor":"426e87","BackgroundColor":"1d1b26","OutlineColor":"27232f"}') },
        ['Rainbow']     = { 9, { _rainbow = true } },
    }

    function ThemeManager:ApplyTheme(theme)
        local data = self.BuiltInThemes[theme]
        if not data then return end
        local scheme = data[2]

        if scheme._rainbow then
            local rainbowColors = {
                FontColor       = "ffffff",
                MainColor       = "000000",
                BackgroundColor = "000000",
                OutlineColor    = "000000",
                AccentColor     = "ffffff",
            }
            for idx, col in next, rainbowColors do
                self.Library[idx] = Color3.fromHex(col)
                if Options[idx] then Options[idx]:SetValueRGB(Color3.fromHex(col)) end
            end
            Cfg.IsRainbowTheme = true
        else
            Cfg.IsRainbowTheme = false
            for idx, col in next, scheme do
                self.Library[idx] = Color3.fromHex(col)
                if Options[idx] then Options[idx]:SetValueRGB(Color3.fromHex(col)) end
            end
        end

        self:ThemeUpdate()
    end

    function ThemeManager:ThemeUpdate()
        local fields = { "FontColor", "MainColor", "AccentColor", "BackgroundColor", "OutlineColor" }
        for _, field in next, fields do
            if Options and Options[field] then
                self.Library[field] = Options[field].Value
            end
        end
        self.Library.AccentColorDark = self.Library:GetDarkerColor(self.Library.AccentColor)
        self.Library:UpdateColorsUsingRegistry()
    end

    function ThemeManager:CreateThemeManager(groupbox)
        groupbox:AddLabel('Background color'):AddColorPicker('BackgroundColor', { Default = self.Library.BackgroundColor })
        groupbox:AddLabel('Main color'):AddColorPicker('MainColor',             { Default = self.Library.MainColor })
        groupbox:AddLabel('Accent color'):AddColorPicker('AccentColor',         { Default = self.Library.AccentColor })
        groupbox:AddLabel('Outline color'):AddColorPicker('OutlineColor',       { Default = self.Library.OutlineColor })
        groupbox:AddLabel('Font color'):AddColorPicker('FontColor',             { Default = self.Library.FontColor })

        local ThemesArray = {}
        for Name in next, self.BuiltInThemes do
            table.insert(ThemesArray, Name)
        end
        table.sort(ThemesArray, function(a, b)
            return self.BuiltInThemes[a][1] < self.BuiltInThemes[b][1]
        end)

        groupbox:AddDivider()
        groupbox:AddDropdown('ThemeManager_ThemeList', {
            Text    = 'Theme list',
            Values  = ThemesArray,
            Default = 1,
        })

        Options.ThemeManager_ThemeList:OnChanged(function()
            self:ApplyTheme(Options.ThemeManager_ThemeList.Value)
        end)

        Options.ThemeManager_ThemeList:SetValue('Default')

        local function UpdateTheme() self:ThemeUpdate() end
        Options.BackgroundColor:OnChanged(UpdateTheme)
        Options.MainColor:OnChanged(UpdateTheme)
        Options.AccentColor:OnChanged(UpdateTheme)
        Options.OutlineColor:OnChanged(UpdateTheme)
        Options.FontColor:OnChanged(UpdateTheme)
    end

    function ThemeManager:SetLibrary(lib) self.Library = lib end
    function ThemeManager:CreateGroupBox(tab) return tab:AddLeftGroupbox('Themes') end
    function ThemeManager:ApplyToTab(tab) self:CreateThemeManager(self:CreateGroupBox(tab)) end
    function ThemeManager:ApplyToGroupbox(groupbox) self:CreateThemeManager(groupbox) end

    return ThemeManager
end)()

-- ══════════════════════════════════════════════════════════════════════════════
--  WINDOW
-- ══════════════════════════════════════════════════════════════════════════════

Library.AccentColor     = Color3.fromRGB(255, 255, 255)
Library.AccentColorDark = Library:GetDarkerColor(Library.AccentColor)
Library.Font            = Enum.Font.GothamBold

local Window = Library:CreateWindow({
    Title      = 'Scythe V2',
    Center     = true,
    AutoShow   = true,
    TabPadding = 8,
})

-- ══════════════════════════════════════════════════════════════════════════════
--  TABS
-- ══════════════════════════════════════════════════════════════════════════════

local Tabs = {
    Combat          = Window:AddTab('Combat'),
    Visuals         = Window:AddTab('Visuals'),
    World           = Window:AddTab('World'),
    Misc            = Window:AddTab('Misc'),
    ['UI Settings'] = Window:AddTab('UI Settings'),
}

-- ══════════════════════════════════════════════════════════════════════════════
--  GLOW SYSTEM
--  OPTIMIZED: single RenderStepped, cached references, ColorSequence reuse
-- ══════════════════════════════════════════════════════════════════════════════

do
    -- Cache service references at top level — avoids GetService() per frame
    local RunService         = game:GetService('RunService')
    local Players            = game:GetService('Players')
    local Stats              = game:GetService('Stats')
    local TextService        = game:GetService('TextService')
    local MarketplaceService = game:GetService('MarketplaceService')
    local LocalPlayer        = Players.LocalPlayer
    local ScreenGui          = Library.ScreenGui

    local Hue       = 0
    local SEG_STEPS = 16

    -- Build a rainbow gradient ColorSequence for one border segment
    local function buildSegGradient(hueFrom, hueTo)
        local kps = table.create(SEG_STEPS + 1)
        for i = 0, SEG_STEPS do
            local t    = i / SEG_STEPS
            local h    = (hueFrom + (hueTo - hueFrom) * t) % 1
            if h < 0 then h = h + 1 end
            kps[i + 1] = ColorSequenceKeypoint.new(t, Color3.fromHSV(h, 1, 1))
        end
        return ColorSequence.new(kps)
    end

    local function buildSolidColorSequence(color)
        return ColorSequence.new(color)
    end

    -- Hide the library's own watermark
    if Library.Watermark then Library.Watermark.Visible = false end

    -- Watermark root frame
    local WmRoot = Instance.new('Frame')
    WmRoot.BackgroundTransparency = 1
    WmRoot.Position               = UDim2.new(0, 12, 0, 8)
    WmRoot.Size                   = UDim2.new(0, 420, 0, 26)
    WmRoot.ZIndex                 = 500
    WmRoot.Parent                 = ScreenGui

    -- Glow blob layers
    local WmGlowLayers = {}
    for i = 6, 1, -1 do
        local s  = i * math.max(Cfg.WmSpread / 2, 2)
        local fr = Instance.new('Frame')
        fr.BackgroundColor3       = Color3.new(1, 1, 1)
        fr.BackgroundTransparency = 1
        fr.BorderSizePixel        = 0
        fr.Position               = UDim2.new(0, -s, 0, -s)
        fr.Size                   = UDim2.new(1, s * 2, 1, s * 2)
        fr.ZIndex                 = 493 + i
        fr.Parent                 = WmRoot
        Instance.new('UICorner', fr).CornerRadius = UDim.new(0, 8 + s / 2)
        table.insert(WmGlowLayers, fr)
    end

    -- Main dark background panel
    local WmMain = Instance.new('Frame')
    WmMain.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
    WmMain.BorderSizePixel  = 0
    WmMain.Size             = UDim2.new(1, 0, 1, 0)
    WmMain.ZIndex           = 501
    WmMain.Parent           = WmRoot
    Instance.new('UICorner', WmMain).CornerRadius = UDim.new(0, 5)

    -- Border segments (top / right / bottom / left)
    local function makeBorderSeg(pos, size, rot)
        local f = Instance.new('Frame')
        f.BackgroundColor3       = Color3.new(1, 1, 1)
        f.BackgroundTransparency = 0
        f.BorderSizePixel        = 0
        f.Position               = pos
        f.Size                   = size
        f.ZIndex                 = 503
        f.Parent                 = WmMain
        local g = Instance.new('UIGradient', f)
        g.Rotation = rot
        return f, g
    end

    local _bTop,    gTop    = makeBorderSeg(UDim2.new(0, 0, 0, 0),    UDim2.new(1, 0, 0, 2),  0)
    local _bRight,  gRight  = makeBorderSeg(UDim2.new(1, -2, 0, 2),   UDim2.new(0, 2, 1, -4), 90)
    local _bBottom, gBottom = makeBorderSeg(UDim2.new(0, 0, 1, -2),   UDim2.new(1, 0, 0, 2),  0)
    local _bLeft,   gLeft   = makeBorderSeg(UDim2.new(0, 0, 0, 2),    UDim2.new(0, 2, 1, -4), 90)

    -- Cached "all white" sequence for when glow is disabled
    local WHITE_SEQ = ColorSequence.new(Color3.new(1, 1, 1))

    -- Text label
    local WmLabel = Instance.new('TextLabel')
    WmLabel.BackgroundTransparency = 1
    WmLabel.Position               = UDim2.new(0, 10, 0, 0)
    WmLabel.Size                   = UDim2.new(1, -20, 1, 0)
    WmLabel.Font                   = Library.Font
    WmLabel.TextColor3             = Color3.new(1, 1, 1)
    WmLabel.TextSize               = 13
    WmLabel.TextXAlignment         = Enum.TextXAlignment.Left
    WmLabel.TextStrokeTransparency = 0.7
    WmLabel.ZIndex                 = 504
    WmLabel.Parent                 = WmMain

    Library:MakeDraggable(WmRoot)

    -- Window glow image (library-created)
    local WinGlowImage = ScreenGui:FindFirstChild('Glow', true)

    -- OPTIMIZED: One RenderStepped handles the entire glow system
    table.insert(Library.Signals, RunService.RenderStepped:Connect(function(dt)
        Hue = (Hue + dt * 0.2 * Cfg.Speed) % 1

        local useRainbow = Cfg.IsRainbowTheme
        local glowColor  = useRainbow and nil or Library.AccentColor

        -- Border segments
        if Cfg.WmGlowOn then
            if useRainbow then
                gTop.Color    = buildSegGradient(Hue,        Hue + 0.25)
                gRight.Color  = buildSegGradient(Hue + 0.25, Hue + 0.5)
                gBottom.Color = buildSegGradient(Hue + 0.75, Hue + 0.5)
                gLeft.Color   = buildSegGradient(Hue + 1.0,  Hue + 0.75)
            else
                local solidSeq = buildSolidColorSequence(glowColor)
                gTop.Color    = solidSeq
                gRight.Color  = solidSeq
                gBottom.Color = solidSeq
                gLeft.Color   = solidSeq
            end
        else
            gTop.Color    = WHITE_SEQ
            gRight.Color  = WHITE_SEQ
            gBottom.Color = WHITE_SEQ
            gLeft.Color   = WHITE_SEQ
        end

        -- Glow blob layers
        local n = #WmGlowLayers
        if Cfg.WmGlowOn then
            for i, layer in ipairs(WmGlowLayers) do
                if useRainbow then
                    local blobHue = (Hue + (i - 1) / n * 0.15) % 1
                    layer.BackgroundColor3       = Color3.fromHSV(blobHue, 0.9, 1)
                    layer.BackgroundTransparency = 1 - (Cfg.WmOpacity * (n - i + 1) / n * 0.5)
                else
                    layer.BackgroundColor3       = glowColor
                    layer.BackgroundTransparency = 1 - (Cfg.WmOpacity * i / n * 0.5)
                end
            end
        else
            for _, layer in ipairs(WmGlowLayers) do
                layer.BackgroundTransparency = 1
            end
        end

        -- Window glow image
        if WinGlowImage then
            if Cfg.WinGlowOn then
                WinGlowImage.ImageColor3       = useRainbow and Color3.fromHSV(Hue, 0.85, 1) or glowColor
                WinGlowImage.ImageTransparency = 1 - Cfg.WinOpacity
            else
                WinGlowImage.ImageTransparency = 1
            end
        end
    end))

    -- Marketplace name fetch
    local PlaceName = game.Name
    task.spawn(function()
        local ok, info = pcall(function()
            return MarketplaceService:GetProductInfo(game.PlaceId, Enum.InfoType.Asset)
        end)
        if ok and info and info.Name then
            PlaceName = info.Name
        end
    end)

    -- OPTIMIZED: rolling average FPS buffer — add/remove one element per frame
    local fpsBuf = {}
    local fpsSum = 0
    table.insert(Library.Signals, RunService.RenderStepped:Connect(function(dt)
        local v = 1 / math.max(dt, 0.001)
        if #fpsBuf >= 20 then
            fpsSum = fpsSum - fpsBuf[1]
            table.remove(fpsBuf, 1)
        end
        table.insert(fpsBuf, v)
        fpsSum = fpsSum + v
    end))

    -- Watermark text update (0.5s interval — no need every frame)
    task.spawn(function()
        while task.wait(0.5) do
            local fps  = math.floor(fpsSum / math.max(#fpsBuf, 1))
            local ping = 0
            pcall(function()
                ping = math.floor(Stats.Network.ServerStatsItem['Data Ping']:GetValue())
            end)
            local text   = string.format('Scythe V2  |  %s  |  %d fps  |  %d ms  |  %s', LocalPlayer.Name, fps, ping, PlaceName)
            WmLabel.Text = text
            local bounds = TextService:GetTextSize(text, 13, Library.Font, Vector2.new(9999, 9999))
            WmRoot.Size  = UDim2.new(0, bounds.X + 24, 0, 26)
        end
    end)

    -- UI Settings: Glow controls
    local GlowGroup = Tabs['UI Settings']:AddLeftGroupbox('Glow & Watermark')

    GlowGroup:AddToggle('Scythe_WmVisible', { Text = 'Show watermark', Default = true })
    Toggles.Scythe_WmVisible:OnChanged(function(v) WmRoot.Visible = v end)

    GlowGroup:AddDivider()

    GlowGroup:AddToggle('Scythe_WmGlow', { Text = 'Watermark glow', Default = true })
    Toggles.Scythe_WmGlow:OnChanged(function(v) Cfg.WmGlowOn = v end)

    GlowGroup:AddToggle('Scythe_WinGlow', { Text = 'Window glow', Default = true })
    Toggles.Scythe_WinGlow:OnChanged(function(v) Cfg.WinGlowOn = v end)

    GlowGroup:AddDivider()

    GlowGroup:AddSlider('Scythe_Speed', { Text = 'RGB speed', Default = 10, Min = 1, Max = 50, Rounding = 0 })
    Options.Scythe_Speed:OnChanged(function(v) Cfg.Speed = v / 10 end)

    GlowGroup:AddSlider('Scythe_WmOpacity', { Text = 'Watermark glow opacity', Default = 55, Min = 5, Max = 95, Rounding = 0 })
    Options.Scythe_WmOpacity:OnChanged(function(v) Cfg.WmOpacity = v / 100 end)

    GlowGroup:AddSlider('Scythe_WmSpread', { Text = 'Watermark glow spread', Default = 5, Min = 1, Max = 12, Rounding = 0 })
    Options.Scythe_WmSpread:OnChanged(function(v)
        Cfg.WmSpread = v
        for i, layer in ipairs(WmGlowLayers) do
            local s = i * math.max(v / 2, 2)
            layer.Position = UDim2.new(0, -s, 0, -s)
            layer.Size     = UDim2.new(1, s * 2, 1, s * 2)
        end
    end)

    GlowGroup:AddSlider('Scythe_WinOpacity', { Text = 'Window glow opacity', Default = 60, Min = 5, Max = 95, Rounding = 0 })
    Options.Scythe_WinOpacity:OnChanged(function(v) Cfg.WinOpacity = v / 100 end)
end

-- ══════════════════════════════════════════════════════════════════════════════
--  MENU KEYBIND / UNLOAD
-- ══════════════════════════════════════════════════════════════════════════════

local MenuGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu')
MenuGroup:AddButton('Unload', function() Library:Unload() end)
MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', {
    Default = 'End',
    NoUI    = true,
    Text    = 'Menu keybind',
})
Library.ToggleKeybind = Options.MenuKeybind

Library:OnUnload(function()
    warn('Unloaded')
    Library.Unloaded = true
end)

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })

SaveManager:BuildConfigSection(Tabs['UI Settings'])
ThemeManager:ApplyToTab(Tabs['UI Settings'])
SaveManager:LoadAutoloadConfig()

-- ══════════════════════════════════════════════════════════════════════════════
--  SERVICES  (cached once — never call GetService in hot loops)
-- ══════════════════════════════════════════════════════════════════════════════

local UserInputService  = game:GetService("UserInputService")
local CoreGui           = game:GetService("CoreGui")
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local Stats             = game:GetService("Stats")
local Lighting          = game:GetService("Lighting")
local HttpService       = game:GetService("HttpService")
local TweenService      = game:GetService("TweenService")
local TextService       = game:GetService("TextService")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

-- ══════════════════════════════════════════════════════════════════════════════
--  CUSTOM KEYBIND SYSTEM
--  OPTIMIZED: keylist text update throttled to 10×/sec via Heartbeat
-- ══════════════════════════════════════════════════════════════════════════════

local KeybindSystem = { Binds = {} }

local KeylistGui = Instance.new("ScreenGui")
KeylistGui.Name              = "SimpleKeylist"
KeylistGui.Parent            = CoreGui
KeylistGui.IgnoreGuiInset    = true
KeylistGui.ZIndexBehavior    = Enum.ZIndexBehavior.Sibling

local BlackBox = Instance.new("Frame")
BlackBox.Size                 = UDim2.new(0, 180, 0, 200)
BlackBox.Position             = UDim2.new(0, 15, 0.5, -100)
BlackBox.BackgroundColor3     = Color3.fromRGB(0, 0, 0)
BlackBox.BackgroundTransparency = 0.3
BlackBox.BorderSizePixel      = 0
BlackBox.Parent               = KeylistGui

local HeaderLabel = Instance.new("TextLabel")
HeaderLabel.Size              = UDim2.new(1, -10, 0, 20)
HeaderLabel.Position          = UDim2.new(0, 5, 0, 5)
HeaderLabel.BackgroundTransparency = 1
HeaderLabel.TextColor3        = Color3.fromRGB(255, 255, 255)
HeaderLabel.Font              = Enum.Font.GothamBold
HeaderLabel.TextSize          = 13
HeaderLabel.TextXAlignment    = Enum.TextXAlignment.Center
HeaderLabel.Text              = "keybinds"
HeaderLabel.Parent            = BlackBox

local BindText = Instance.new("TextLabel")
BindText.Size                 = UDim2.new(1, -10, 1, -30)
BindText.Position             = UDim2.new(0, 5, 0, 28)
BindText.BackgroundTransparency = 1
BindText.TextColor3           = Color3.fromRGB(200, 200, 200)
BindText.Font                 = Enum.Font.GothamBold
BindText.TextSize             = 12
BindText.TextXAlignment       = Enum.TextXAlignment.Left
BindText.TextYAlignment       = Enum.TextYAlignment.Top
BindText.LineHeight            = 1.6
BindText.Text                 = "none"
BindText.Parent               = BlackBox

function KeybindSystem:Register(name, keyGetter, toggleRef, mode)
    table.insert(self.Binds, {
        name    = name,
        getKey  = keyGetter,
        toggle  = toggleRef,
        mode    = mode or "Toggle",
        isHeld  = false,
    })
end

-- Helper: resolve key string → Enum.KeyCode (cached per-call)
local function resolveKey(currentKey)
    if type(currentKey) == "string" then
        if currentKey ~= "None" and currentKey ~= "" then
            return Enum.KeyCode[currentKey]
        end
        return nil
    end
    return currentKey
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    for _, bind in ipairs(KeybindSystem.Binds) do
        if not bind.toggle or not bind.getKey then continue end
        local ok, currentKey = pcall(bind.getKey)
        if not ok then continue end
        local expectedEnum = resolveKey(currentKey)
        if expectedEnum and input.KeyCode == expectedEnum then
            if bind.mode == "Toggle" then
                bind.toggle:SetValue(not bind.toggle.Value)
            elseif bind.mode == "Hold" then
                bind.isHeld = true
                bind.toggle:SetValue(true)
            end
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    for _, bind in ipairs(KeybindSystem.Binds) do
        if bind.mode ~= "Hold" or not bind.toggle or not bind.getKey then continue end
        local ok, currentKey = pcall(bind.getKey)
        if not ok then continue end
        local expectedEnum = resolveKey(currentKey)
        if expectedEnum and input.KeyCode == expectedEnum then
            bind.isHeld = false
            bind.toggle:SetValue(false)
        end
    end
end)

-- OPTIMIZED: Heartbeat at 10×/sec instead of every render frame
local lastKeylistUpdate = 0
RunService.Heartbeat:Connect(function()
    if tick() - lastKeylistUpdate < 0.1 then return end
    lastKeylistUpdate = tick()

    local text    = ""
    local hasAny  = false
    local menuOpen = false
    pcall(function() menuOpen = Library.Open end)

    for _, bind in ipairs(KeybindSystem.Binds) do
        local isToggled = false
        pcall(function() isToggled = bind.toggle.Value end)
        if isToggled or bind.isHeld or menuOpen then
            hasAny = true
            local keyName = "???"
            pcall(function()
                local k = bind.getKey()
                keyName = type(k) == "string" and k or (k.Name or "???")
            end)
            local status = isToggled and "ON" or ("[" .. keyName .. "]")
            text = text .. bind.name .. "  " .. status .. "\n"
        end
    end

    BindText.Text = hasAny and text or "none"
end)

-- ══════════════════════════════════════════════════════════════════════════════
--  BULLET TRACE
-- ══════════════════════════════════════════════════════════════════════════════

local BulletTrace = {
    Enabled     = false,
    Color       = Color3.fromRGB(255, 255, 255),
    Style       = "Default",
    LifeTime    = 1.0,
    Transparency = 0.1,
}
local CreateBulletTrace = nil

local function setupBulletTrace()
    local section     = Tabs.Visuals:AddRightGroupbox('Bullet Trace')
    local TraceStyles = {
        "Default","Neon","Laser","Wave","Rainbow","Electric",
        "Thin","Lightning","Heartrate","Chain","Glitch","Swirl",
        "Fire beam", "Ice beam", "Super laser" 
    }
    local TraceTextures = {
        Wave      = "rbxassetid://446111271",
        Electric  = "rbxassetid://446111271",
        Lightning = "rbxassetid://446111271",
        Heartrate = "rbxassetid://5830549480",
        Chain     = "rbxassetid://9632168658",
        Glitch    = "rbxassetid://8089467613",
        Swirl     = "rbxassetid://5638168605",
        
        -- ВНИМАНИЕ НА СКОБКИ И КАВЫЧКИ ЗДЕСЬ:
        ["Fire beam"]    = "rbxassetid://18654087326",    
        ["Ice beam"]     = "rbxassetid://139016452637318", 
        ["Super laser"]  = "rbxassetid://16396227851"     
    }

    section:AddToggle('BulletTrace_Enabled', {
        Text     = 'Enabled',
        Default  = false,
        Callback = function(v) BulletTrace.Enabled = v end,
    })
    section:AddLabel('Color'):AddColorPicker('BulletTrace_Color', {
        Default  = BulletTrace.Color,
        Title    = 'Trace Color',
        Callback = function(c) BulletTrace.Color = c end,
    })
    section:AddDropdown('BulletTrace_Style', {
        Values   = TraceStyles,
        Default  = "Default",
        Text     = 'Style',
        Callback = function(name) BulletTrace.Style = name end,
    })
    section:AddSlider('BulletTrace_LifeTime', {
        Text     = 'Life Time (s)',
        Default  = 1,
        Min      = 0.1,
        Max      = 10,
        Rounding = 1,
        Callback = function(v) BulletTrace.LifeTime = v end,
    })
    section:AddSlider('BulletTrace_Transparency', {
        Text     = 'Transparency',
        Default  = 10,
        Min      = 0,
        Max      = 100,
        Rounding = 0,
        Callback = function(v) BulletTrace.Transparency = v / 100 end,
    })

    local function createBulletTrace(startPos, endPos)
        if not BulletTrace.Enabled then return end

        local part = Instance.new("Part")
        part.Anchored    = true
        part.CanCollide  = false
        part.Transparency = 1
        part.Size        = Vector3.new(0.1, 0.1, 0.1)
        part.Parent      = Workspace

        local att0 = Instance.new("Attachment", part)
        att0.WorldPosition = startPos
        local att1 = Instance.new("Attachment", part)
        att1.WorldPosition = endPos

        local beam = Instance.new("Beam", part)
        beam.Attachment0   = att0
        beam.Attachment1   = att1
        beam.FaceCamera    = true
        beam.LightInfluence = 0
        beam.Color         = ColorSequence.new(BulletTrace.Color)
        beam.Width0        = 1.1
        beam.Width1        = 1.1
        beam.Transparency  = NumberSequence.new(BulletTrace.Transparency)

        local s = BulletTrace.Style
        if s == "Neon" then
            beam.LightEmission = 1
        elseif s == "Laser" then
            beam.LightEmission = 0.7
            local b2 = Instance.new("Beam", part)
            b2.Attachment0   = att0
            b2.Attachment1   = att1
            b2.FaceCamera    = true
            b2.LightInfluence = 0
            b2.Color         = ColorSequence.new(Color3.new(1, 1, 1))
            b2.Width0        = 0.5
            b2.Width1        = 0.5
            b2.Transparency  = NumberSequence.new(math.clamp(BulletTrace.Transparency * 0.5 + 0.025, 0, 1))
            b2.LightEmission = 0.6
        elseif s == "Rainbow" then
            beam.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0,   Color3.fromRGB(255, 0,   0)),
                ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 165, 0)),
                ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 255, 0)),
                ColorSequenceKeypoint.new(0.6, Color3.fromRGB(0,   255, 0)),
                ColorSequenceKeypoint.new(0.8, Color3.fromRGB(0,   0,   255)),
                ColorSequenceKeypoint.new(1,   Color3.fromRGB(148, 0,   211)),
            })
            beam.LightEmission = 1
        elseif TraceTextures[s] then
            beam.Texture      = TraceTextures[s]
            beam.TextureLength = 2
            beam.TextureSpeed  = 2
            beam.LightEmission = 1
        end

        task.delay(BulletTrace.LifeTime, function()
            if part and part.Parent then part:Destroy() end
        end)
    end

    CreateBulletTrace = createBulletTrace
end
setupBulletTrace()

-- ══════════════════════════════════════════════════════════════════════════════
--  PLAYER ESP
--  OPTIMIZED: frame skip (process every 2nd render frame per player)
-- ══════════════════════════════════════════════════════════════════════════════

local function setupESP()
    local ESPSection = Tabs.Visuals:AddLeftGroupbox('Player ESP')
    ESPSection:AddToggle('ESP_Enabled',    { Text = 'ESP Enabled', Default = true,  Callback = function() end })
    ESPSection:AddToggle('ESP_Names',      { Text = 'Names',       Default = true,  Callback = function() end })
    ESPSection:AddToggle('ESP_Distance',   { Text = 'Distance',    Default = true,  Callback = function() end })
    ESPSection:AddToggle('ESP_Weapon',     { Text = 'Weapon',      Default = true,  Callback = function() end })
    ESPSection:AddToggle('ESP_Healthbar',  { Text = 'Healthbar',   Default = true,  Callback = function() end })
    ESPSection:AddSlider('ESP_MaxDistance', {
        Text     = 'Max Distance',
        Default  = 200,
        Min      = 100,
        Max      = 2000,
        Rounding = 0,
        Callback = function() end,
    })

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name          = "ESP_Rework"
    ScreenGui.ResetOnSpawn  = false
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.Parent        = CoreGui

    local camera = Workspace.CurrentCamera
    local CT     = 2
    local FONT   = Font.new("rbxassetid://16658237174")

    local function makeLine(parent)
        local f = Instance.new("Frame", parent)
        f.BackgroundColor3 = Color3.new(1, 1, 1)
        f.BorderSizePixel  = 0
        f.Visible          = false
        return f
    end

    local function makeLabel(parent)
        local l = Instance.new("TextLabel", parent)
        l.BackgroundTransparency = 1
        l.TextColor3             = Color3.new(1, 1, 1)
        l.TextStrokeTransparency = 0.5
        l.TextStrokeColor3       = Color3.new(0, 0, 0)
        l.TextSize               = 11
        l.FontFace               = FONT
        l.AnchorPoint            = Vector2.new(0.5, 0.5)
        l.Visible                = false
        return l
    end

    local function CreateESP(plr)
        if plr == LocalPlayer then return end

        local folder = Instance.new("Folder", ScreenGui)
        folder.Name  = plr.Name

        local corners = {}
        for i = 1, 8 do corners[i] = makeLine(folder) end

        local nameLabel   = makeLabel(folder)
        local distLabel   = makeLabel(folder)
        local weaponLabel = makeLabel(folder)
        weaponLabel.TextColor3 = Color3.new(1, 1, 1)

        local barBG = Instance.new("Frame", folder)
        barBG.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
        barBG.BorderSizePixel  = 0
        barBG.Visible          = false
        Instance.new("UICorner", barBG).CornerRadius = UDim.new(0, 2)

        local barFill = Instance.new("Frame", barBG)
        barFill.BorderSizePixel = 0
        barFill.AnchorPoint     = Vector2.new(0, 1)
        barFill.Position        = UDim2.new(0, 0, 1, 0)
        Instance.new("UICorner", barFill).CornerRadius = UDim.new(0, 2)

        local barGradient = Instance.new("UIGradient", barFill)
        barGradient.Rotation = -90
        barGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0,   Color3.fromRGB(255, 0,   0)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 0)),
            ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,   255, 0)),
        })

        local dying      = false
        local deathAlpha = 0

        local function hideAll()
            for _, c in ipairs(corners) do c.Visible = false end
            nameLabel.Visible   = false
            distLabel.Visible   = false
            weaponLabel.Visible = false
            barBG.Visible       = false
        end

        -- OPTIMIZED: skip every other frame
        local frameCounter = 0
        local conn
        conn = RunService.RenderStepped:Connect(function(dt)
            frameCounter = frameCounter + 1
            if frameCounter % 2 ~= 0 then return end

            if not Toggles.ESP_Enabled.Value then hideAll(); return end

            local char = plr.Character
            local hum  = char and char:FindFirstChildOfClass("Humanoid")
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")

            if char and hum and hum.Health <= 0 and not dying then
                dying = true
                task.spawn(function()
                    for i = 0, 20 do
                        deathAlpha = i / 20
                        task.wait(0.015)
                    end
                    hideAll()
                    dying      = false
                    deathAlpha = 0
                end)
            end

            if dying then
                for _, c in ipairs(corners) do c.BackgroundTransparency = deathAlpha end
                nameLabel.TextTransparency   = deathAlpha
                distLabel.TextTransparency   = deathAlpha
                weaponLabel.TextTransparency = deathAlpha
                barBG.BackgroundTransparency = deathAlpha
                return
            end

            if not (char and hum and hum.Health > 0 and hrp) then hideAll(); return end

            local p3, onScreen = camera:WorldToViewportPoint(hrp.Position)
            if not onScreen then hideAll(); return end

            local dist = (camera.CFrame.Position - hrp.Position).Magnitude
            local maxD = Options.ESP_MaxDistance.Value or 200
            if dist > maxD then hideAll(); return end

            local px, py = p3.X, p3.Y
            local scale  = camera.ViewportSize.Y / p3.Z
            local w      = scale * 1.5
            local h      = scale * 2.8
            local x1, y1 = px - w / 2, py - h / 2
            local x2, y2 = px + w / 2, py + h / 2
            local cs     = math.clamp(w * 0.25, 4, 12)

            local function sc(f, x, y, sw, sh)
                f.Visible               = true
                f.BackgroundTransparency = 0
                f.Position              = UDim2.fromOffset(x, y)
                f.Size                  = UDim2.fromOffset(sw, sh)
            end

            sc(corners[1], x1,       y1,       cs, CT)
            sc(corners[2], x1,       y1,       CT, cs)
            sc(corners[3], x2 - cs,  y1,       cs, CT)
            sc(corners[4], x2 - CT,  y1,       CT, cs)
            sc(corners[5], x1,       y2 - CT,  cs, CT)
            sc(corners[6], x1,       y2 - cs,  CT, cs)
            sc(corners[7], x2 - cs,  y2 - CT,  cs, CT)
            sc(corners[8], x2 - CT,  y2 - cs,  CT, cs)

            if Toggles.ESP_Names.Value then
                nameLabel.Visible          = true
                nameLabel.TextTransparency = 0
                nameLabel.Text             = plr.Name
                nameLabel.Position         = UDim2.fromOffset(px, y1 - 9)
                nameLabel.Size             = UDim2.fromOffset(w + 60, 14)
            else
                nameLabel.Visible = false
            end

            if Toggles.ESP_Distance.Value then
                distLabel.Visible          = true
                distLabel.TextTransparency = 0
                distLabel.Text             = string.format("%.0fm", dist)
                distLabel.Position         = UDim2.fromOffset(px, y2 + 9)
                distLabel.Size             = UDim2.fromOffset(w + 60, 14)
            else
                distLabel.Visible = false
            end

            if Toggles.ESP_Weapon.Value then
                local weapon = ""
                for _, c in ipairs(char:GetChildren()) do
                    if c:IsA("Tool") then weapon = c.Name; break end
                end
                if weapon ~= "" then
                    weaponLabel.Visible          = true
                    weaponLabel.TextTransparency = 0
                    weaponLabel.Text             = weapon
                    weaponLabel.Position         = UDim2.fromOffset(px, y2 + 9 + 14 + 4)
                    weaponLabel.Size             = UDim2.fromOffset(w + 60, 14)
                else
                    weaponLabel.Visible = false
                end
            else
                weaponLabel.Visible = false
            end

            if Toggles.ESP_Healthbar.Value then
                barBG.Visible               = true
                barBG.BackgroundTransparency = 0
                barBG.Position              = UDim2.fromOffset(x1 - 6, y1)
                barBG.Size                  = UDim2.fromOffset(3, h)
                local hp = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                barFill.Size = UDim2.new(1, 0, hp, 0)
            else
                barBG.Visible = false
            end
        end)

        plr.AncestryChanged:Connect(function()
            if not plr.Parent then
                hideAll()
                conn:Disconnect()
                folder:Destroy()
            end
        end)
    end

    for _, p in ipairs(Players:GetPlayers()) do CreateESP(p) end
    Players.PlayerAdded:Connect(CreateESP)
end
setupESP()

-- ══════════════════════════════════════════════════════════════════════════════
--  HITMARKER
-- ══════════════════════════════════════════════════════════════════════════════

local HitMarkerSection = Tabs.Visuals:AddRightGroupbox('Hitmarker')

local HitMarker = {
    Enabled  = false,
    Color    = Color3.fromRGB(100, 200, 255),
    Size     = 1.5,
    Lifetime = 1.0,
    FadeIn   = true,
    FadeOut  = true,
}

HitMarkerSection:AddToggle('HitMarker_Enabled', {
    Text     = 'Hitmarker Enabled',
    Default  = false,
    Callback = function(v) HitMarker.Enabled = v end,
})
HitMarkerSection:AddLabel('Color'):AddColorPicker('HitMarker_Color', {
    Default  = HitMarker.Color,
    Callback = function(c) HitMarker.Color = c end,
})
HitMarkerSection:AddSlider('HitMarker_Size', {
    Text     = 'Size',
    Rounding = 1,
    Default  = 1.5,
    Min      = 0.5,
    Max      = 5.0,
    Callback = function(v) HitMarker.Size = v end,
})
HitMarkerSection:AddSlider('HitMarker_Lifetime', {
    Text     = 'Lifetime',
    Rounding = 1,
    Default  = 1.0,
    Min      = 0.5,
    Max      = 3,
    Callback = function(v) HitMarker.Lifetime = v end,
})
HitMarkerSection:AddToggle('HitMarker_FadeIn', {
    Text     = 'Fade In',
    Default  = true,
    Callback = function(v) HitMarker.FadeIn = v end,
})
HitMarkerSection:AddToggle('HitMarker_FadeOut', {
    Text     = 'Fade Out',
    Default  = true,
    Callback = function(v) HitMarker.FadeOut = v end,
})

local function createHitMarker(position)
    if not HitMarker.Enabled then return end

    local part = Instance.new("Part")
    part.Anchored    = true
    part.CanCollide  = false
    part.Transparency = 1
    part.Size        = Vector3.new(0.1, 0.1, 0.1)
    part.Position    = position
    part.Parent      = workspace

    local crossSize = math.floor(HitMarker.Size * 20)
    local billboard = Instance.new("BillboardGui")
    billboard.Adornee     = part
    billboard.Size        = UDim2.new(0, crossSize, 0, crossSize)
    billboard.AlwaysOnTop = true
    billboard.Parent      = part

    local gap     = crossSize * 0.1
    local lineLen = crossSize * 0.35
    local offset  = gap + (lineLen / 2)

    local arms = {
        { -offset, -offset, 45  },
        {  offset, -offset, -45 },
        { -offset,  offset, -45 },
        {  offset,  offset, 45  },
    }

    local lines = {}
    for _, arm in ipairs(arms) do
        local outline = Instance.new("Frame")
        outline.Size            = UDim2.new(0, lineLen, 0, 4)
        outline.Position        = UDim2.new(0.5, arm[1], 0.5, arm[2])
        outline.AnchorPoint     = Vector2.new(0.5, 0.5)
        outline.BackgroundColor3 = Color3.new(0, 0, 0)
        outline.BorderSizePixel = 0
        outline.Rotation        = arm[3]
        outline.Parent          = billboard
        table.insert(lines, outline)

        local line = Instance.new("Frame")
        line.Size            = UDim2.new(0, lineLen, 0, 2)
        line.Position        = UDim2.new(0.5, arm[1], 0.5, arm[2])
        line.AnchorPoint     = Vector2.new(0.5, 0.5)
        line.BackgroundColor3 = HitMarker.Color
        line.BorderSizePixel = 0
        line.Rotation        = arm[3]
        line.Parent          = billboard
        table.insert(lines, line)
    end

    local startTime = tick()
    local connection
    connection = RunService.RenderStepped:Connect(function()
        local elapsed = tick() - startTime
        if elapsed >= HitMarker.Lifetime then
            connection:Disconnect()
            part:Destroy()
            return
        end

        local alpha    = 1
        local fadeTime = HitMarker.Lifetime * 0.2

        if HitMarker.FadeIn and elapsed < fadeTime then
            alpha = elapsed / fadeTime
        elseif HitMarker.FadeOut and elapsed > HitMarker.Lifetime - fadeTime then
            alpha = (HitMarker.Lifetime - elapsed) / fadeTime
        end

        local scale = 1 + (elapsed / HitMarker.Lifetime) * 0.5
        billboard.Size = UDim2.new(0, crossSize * scale, 0, crossSize * scale)

        for _, frame in ipairs(lines) do
            frame.BackgroundTransparency = 1 - alpha
        end
    end)
end

task.spawn(function()
    local ok, gunClient = pcall(function()
        return require(ReplicatedStorage.Gun.Scripts.GunClient)
    end)
    if ok and gunClient and not gunClient._hitMarkerHooked then
        gunClient._hitMarkerHooked = true
        local oldHit = gunClient.hit
        gunClient.hit = function(self, hitResult, ...)
            if oldHit then oldHit(self, hitResult, ...) end
            if hitResult and hitResult.Position and hitResult.Instance then
                local model = hitResult.Instance
                while model and not Players:GetPlayerFromCharacter(model) do
                    model = model.Parent
                end
                if model then createHitMarker(hitResult.Position) end
            end
        end
    end
end)

-- ══════════════════════════════════════════════════════════════════════════════
--  TESLA HIT EFFECT
-- ══════════════════════════════════════════════════════════════════════════════

local TeslaEffect = {
    Enabled         = false,
    Color           = Color3.fromRGB(100, 200, 255),
    BeamCount       = 12,
    Radius          = 10,
    Duration        = 0.75,
    Width           = 0.2,
    ElectricTexture = "rbxassetid://446111271",
    TextureSpeed    = 2,
}

local function createTeslaEffect(position)
    if not TeslaEffect.Enabled then return end

    local root = Instance.new("Part")
    root.Anchored    = true
    root.CanCollide  = false
    root.Transparency = 1
    root.Size        = Vector3.new(0.1, 0.1, 0.1)
    root.Position    = position
    root.Parent      = Workspace

    local att0 = Instance.new("Attachment", root)
    att0.WorldPosition = position

    for i = 1, TeslaEffect.BeamCount do
        local offset = Vector3.new(
            math.random(-TeslaEffect.Radius * 10, TeslaEffect.Radius * 10) / 10,
            math.random(-TeslaEffect.Radius * 10, TeslaEffect.Radius * 10) / 10,
            math.random(-TeslaEffect.Radius * 10, TeslaEffect.Radius * 10) / 10
        )

        local endPart = Instance.new("Part")
        endPart.Anchored    = true
        endPart.CanCollide  = false
        endPart.Transparency = 1
        endPart.Size        = Vector3.new(0.1, 0.1, 0.1)
        endPart.Position    = position + offset
        endPart.Parent      = root

        local att1 = Instance.new("Attachment", endPart)
        att1.WorldPosition = position + offset

        local beam = Instance.new("Beam", root)
        beam.Attachment0    = att0
        beam.Attachment1    = att1
        beam.Color          = ColorSequence.new(TeslaEffect.Color)
        beam.Width0         = TeslaEffect.Width
        beam.Width1         = 0
        beam.LightEmission  = 1
        beam.LightInfluence = 0
        beam.FaceCamera     = true
        beam.Texture        = TeslaEffect.ElectricTexture
        beam.TextureMode    = Enum.TextureMode.Wrap
        beam.TextureLength  = 2
        beam.TextureSpeed   = TeslaEffect.TextureSpeed
        beam.Transparency   = NumberSequence.new({
            NumberSequenceKeypoint.new(0,   0),
            NumberSequenceKeypoint.new(0.7, 0.3),
            NumberSequenceKeypoint.new(1,   1),
        })
        beam.Segments   = math.random(8, 15)
        beam.CurveSize0 = math.random(-4, 4)
        beam.CurveSize1 = math.random(-4, 4)

        task.delay(math.random(0, 100) / 1000, function()
            if beam and beam.Parent then beam.Enabled = true end
        end)
    end

    local sound = Instance.new("Sound", root)
    sound.SoundId = "rbxassetid://130818250"
    sound.Volume  = 0.3
    sound:Play()

    task.delay(TeslaEffect.Duration, function()
        if root and root.Parent then root:Destroy() end
    end)
end

local TeslaSection = Tabs.Visuals:AddRightGroupbox('Tesla Hit Effect')
TeslaSection:AddToggle('Tesla_Enabled',      { Text = 'Enabled',         Default = false, Callback = function(v) TeslaEffect.Enabled = v end })
TeslaSection:AddLabel('Color'):AddColorPicker('Tesla_Color', { Default = TeslaEffect.Color, Callback = function(c) TeslaEffect.Color = c end })
TeslaSection:AddSlider('Tesla_Beams',        { Text = 'Beam Count',      Default = 12,  Min = 1,  Max = 30,  Rounding = 0, Callback = function(v) TeslaEffect.BeamCount = v end })
TeslaSection:AddSlider('Tesla_Radius',       { Text = 'Radius',          Default = 10,  Min = 1,  Max = 30,  Rounding = 0, Callback = function(v) TeslaEffect.Radius = v end })
TeslaSection:AddSlider('Tesla_Duration',     { Text = 'Duration (s)',    Default = 75,  Min = 10, Max = 300, Rounding = 0, Callback = function(v) TeslaEffect.Duration = v / 100 end })
TeslaSection:AddSlider('Tesla_Width',        { Text = 'Beam Width',      Default = 20,  Min = 1,  Max = 100, Rounding = 0, Callback = function(v) TeslaEffect.Width = v / 100 end })
TeslaSection:AddSlider('Tesla_TextureSpeed', { Text = 'Electric Speed',  Default = 2,   Min = 0,  Max = 10,  Rounding = 1, Callback = function(v) TeslaEffect.TextureSpeed = v end })

task.delay(1, function()
    local gcp = ReplicatedStorage:FindFirstChild("Gun")
        and ReplicatedStorage.Gun:FindFirstChild("Scripts")
        and ReplicatedStorage.Gun.Scripts:FindFirstChild("GunClient")

    if gcp then
        local ok, gc = pcall(require, gcp)
        if ok and gc and not gc._teslaHooked then
            gc._teslaHooked = true
            local oldHit = gc.hit
            gc.hit = function(self, hitResult, ...)
                if oldHit then oldHit(self, hitResult, ...) end
                if hitResult and hitResult.Position then
                    local part = hitResult.Instance
                    if part then
                        local model = part:FindFirstAncestorOfClass("Model")
                        if model and model:FindFirstChildOfClass("Humanoid") then
                            createTeslaEffect(hitResult.Position)
                        end
                    end
                end
            end
        end
    end
end)

-- ══════════════════════════════════════════════════════════════════════════════
--  INVENTORY VIEWER
--  OPTIMIZED: Heartbeat update at 2×/sec
-- ══════════════════════════════════════════════════════════════════════════════

local function setupInventoryViewer()
    local InventorySection = Tabs.Visuals:AddRightGroupbox('Inventory Viewer')

    local InventoryViewer = {
        Enabled       = false,
        GUI           = nil,
        Container     = nil,
        TitleLabel    = nil,
        CurrentTarget = nil,
    }

    local IV_ACCENT = Color3.fromRGB(255, 255, 255)

    local function createInventoryGUI()
        if InventoryViewer.GUI then return end

        local gui = Instance.new("ScreenGui")
        gui.Name          = "InventoryViewer"
        gui.ResetOnSpawn  = false
        gui.DisplayOrder  = 998
        gui.Parent        = CoreGui

        local mainFrame = Instance.new("Frame")
        mainFrame.Size                 = UDim2.new(0, 400, 0, 120)
        mainFrame.Position             = UDim2.new(0.5, -200, 0, 20)
        mainFrame.BackgroundColor3     = Color3.fromRGB(20, 20, 20)
        mainFrame.BackgroundTransparency = 0.1
        mainFrame.BorderSizePixel      = 0
        mainFrame.Active               = true
        mainFrame.Draggable            = true
        mainFrame.Parent               = gui
        Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)

        local stroke = Instance.new("UIStroke")
        stroke.Color              = IV_ACCENT
        stroke.Thickness          = 2
        stroke.Transparency       = 0.3
        stroke.ApplyStrokeMode    = Enum.ApplyStrokeMode.Border
        stroke.Parent             = mainFrame

        local titleBar = Instance.new("Frame")
        titleBar.Size                 = UDim2.new(1, 0, 0, 24)
        titleBar.BackgroundColor3     = Color3.fromRGB(15, 15, 15)
        titleBar.BackgroundTransparency = 0.3
        titleBar.BorderSizePixel      = 0
        titleBar.Parent               = mainFrame
        Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 8)

        local titleLabel = Instance.new("TextLabel")
        titleLabel.Size               = UDim2.new(1, 0, 1, 0)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Text               = "Inventory"
        titleLabel.TextColor3         = IV_ACCENT
        titleLabel.Font               = Enum.Font.GothamBold
        titleLabel.TextSize           = 13
        titleLabel.Parent             = titleBar

        local scrollFrame = Instance.new("ScrollingFrame")
        scrollFrame.Size                   = UDim2.new(1, -8, 1, -30)
        scrollFrame.Position               = UDim2.new(0, 4, 0, 26)
        scrollFrame.BackgroundTransparency = 1
        scrollFrame.BorderSizePixel        = 0
        scrollFrame.ScrollBarThickness     = 5
        scrollFrame.ScrollBarImageColor3   = IV_ACCENT
        scrollFrame.ScrollBarImageTransparency = 0.2
        scrollFrame.ScrollingDirection     = Enum.ScrollingDirection.X
        scrollFrame.CanvasSize             = UDim2.new(0, 0, 0, 0)
        scrollFrame.ElasticBehavior        = Enum.ElasticBehavior.Never
        scrollFrame.Parent                 = mainFrame

        local layout = Instance.new("UIListLayout")
        layout.FillDirection       = Enum.FillDirection.Horizontal
        layout.Padding             = UDim.new(0, 6)
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
        layout.VerticalAlignment   = Enum.VerticalAlignment.Center
        layout.SortOrder           = Enum.SortOrder.LayoutOrder
        layout.Parent              = scrollFrame

        local padding = Instance.new("UIPadding")
        padding.PaddingLeft   = UDim.new(0, 4)
        padding.PaddingRight  = UDim.new(0, 4)
        padding.PaddingTop    = UDim.new(0, 4)
        padding.PaddingBottom = UDim.new(0, 4)
        padding.Parent        = scrollFrame

        InventoryViewer.GUI        = gui
        InventoryViewer.Container  = scrollFrame
        InventoryViewer.TitleLabel = titleLabel
    end

    InventorySection:AddToggle('Vis_Inventory_Enabled', {
        Text     = 'Inventory Viewer',
        Default  = false,
        Tooltip  = 'Shows target player inventory',
        Callback = function(v)
            InventoryViewer.Enabled = v
            if v then
                createInventoryGUI()
            elseif InventoryViewer.GUI then
                InventoryViewer.GUI:Destroy()
                InventoryViewer.GUI = nil
            end
        end,
    })

    local function parseCountFromToolTip(toolTipText)
        if not toolTipText or toolTipText == "" then return 1 end
        local num = tonumber(toolTipText:match("%d+"))
        return num or 1
    end

    local function updateInventory(player)
        if not InventoryViewer.Enabled or not InventoryViewer.GUI then return end
        local container = InventoryViewer.Container
        if not container then return end

        for _, child in ipairs(container:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end

        local char = player and player.Character
        if not char then
            InventoryViewer.TitleLabel.Text = "No target"
            return
        end

        InventoryViewer.TitleLabel.Text = player.Name .. "'s Inventory"

        local items = {}
        local function processTool(tool)
            if not tool:IsA("Tool") then return end
            local count = parseCountFromToolTip(tool.ToolTip)
            items[tool.Name] = (items[tool.Name] or 0) + count
        end

        local backpack = player:FindFirstChild("Backpack")
        if backpack then
            for _, tool in ipairs(backpack:GetChildren()) do processTool(tool) end
        end
        for _, tool in ipairs(char:GetChildren()) do processTool(tool) end

        local itemCount = 0
        for name, count in pairs(items) do
            itemCount = itemCount + 1

            local asset = ReplicatedStorage:FindFirstChild(name)
            if not asset then
                for _, folder in ipairs(ReplicatedStorage:GetChildren()) do
                    if folder:IsA("Folder") and folder:FindFirstChild(name) then
                        asset = folder:FindFirstChild(name)
                        break
                    end
                end
            end

            local textureId = ""
            if asset then
                if asset:IsA("Tool") and asset.TextureId ~= "" then
                    textureId = asset.TextureId
                elseif asset:IsA("Decal") or asset:IsA("Texture") then
                    textureId = asset.Texture
                elseif asset:IsA("Model") then
                    local decal = asset:FindFirstChildOfClass("Decal")
                    if decal then textureId = decal.Texture end
                end
            end

            local iconFrame = Instance.new("Frame")
            iconFrame.Size                 = UDim2.new(0, 50, 0, 50)
            iconFrame.BackgroundColor3     = Color3.fromRGB(25, 25, 25)
            iconFrame.BackgroundTransparency = 0.2
            iconFrame.BorderSizePixel      = 0
            iconFrame.Parent               = container
            Instance.new("UICorner", iconFrame).CornerRadius = UDim.new(0, 6)

            local iconStroke = Instance.new("UIStroke")
            iconStroke.Color        = IV_ACCENT
            iconStroke.Thickness    = 1.5
            iconStroke.Transparency = 0.5
            iconStroke.Parent       = iconFrame

            local icon = Instance.new("ImageLabel")
            icon.Size                 = UDim2.new(0, 38, 0, 38)
            icon.Position             = UDim2.new(0.5, -19, 0, 2)
            icon.BackgroundTransparency = 1
            icon.Image                = textureId
            icon.ImageColor3          = Color3.fromRGB(255, 255, 255)
            icon.Parent               = iconFrame

            local amountBg = Instance.new("Frame")
            amountBg.Size                 = UDim2.new(1, -4, 0, 16)
            amountBg.Position             = UDim2.new(0, 2, 1, -18)
            amountBg.BackgroundColor3     = Color3.fromRGB(10, 10, 10)
            amountBg.BackgroundTransparency = 0.3
            amountBg.BorderSizePixel      = 0
            amountBg.Parent               = iconFrame
            Instance.new("UICorner", amountBg).CornerRadius = UDim.new(0, 4)

            local amountLabel = Instance.new("TextLabel")
            amountLabel.Size                   = UDim2.new(1, 0, 1, 0)
            amountLabel.BackgroundTransparency = 1
            amountLabel.Text                   = "x" .. count
            amountLabel.TextColor3             = IV_ACCENT
            amountLabel.Font                   = Enum.Font.GothamBold
            amountLabel.TextSize               = 11
            amountLabel.TextStrokeTransparency = 0.6
            amountLabel.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
            amountLabel.Parent                 = amountBg
        end

        local totalWidth = (itemCount * 50) + (math.max(itemCount - 1, 0) * 6) + 8
        container.CanvasSize = UDim2.new(0, totalWidth, 0, 0)
    end

    local function findTargetPlayer()
        local silentTarget = rawget(_G, "CurrentAimTarget") or CurrentAimTarget
        if silentTarget and silentTarget.Parent then
            local model = silentTarget:FindFirstAncestorOfClass("Model")
            if model then
                local player = Players:GetPlayerFromCharacter(model)
                if player then return player end
            end
        end

        local closestDist = 500
        local center      = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        local target      = nil

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local root = player.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position)
                    if onScreen then
                        local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                        if dist < closestDist then
                            closestDist = dist
                            target      = player
                        end
                    end
                end
            end
        end

        return target
    end

    -- OPTIMIZED: Heartbeat at 2×/sec
    local lastInventoryUpdate = 0
    RunService.Heartbeat:Connect(function()
        if not InventoryViewer.Enabled or not InventoryViewer.GUI then return end
        if tick() - lastInventoryUpdate < 0.5 then return end
        lastInventoryUpdate = tick()

        local target = findTargetPlayer()
        if target then
            InventoryViewer.CurrentTarget = target
            updateInventory(target)
        else
            if InventoryViewer.CurrentTarget then
                InventoryViewer.CurrentTarget = nil
                updateInventory(nil)
            end
        end
    end)

    Library:OnUnload(function()
        if InventoryViewer.GUI then
            InventoryViewer.GUI:Destroy()
            InventoryViewer.GUI = nil
        end
    end)
end
setupInventoryViewer()

-- ══════════════════════════════════════════════════════════════════════════════
--  STAFF INDICATOR
--  OPTIMIZED: animation via Heartbeat at 30fps, not RenderStepped
-- ══════════════════════════════════════════════════════════════════════════════

local StaffIndicatorSection = Tabs.Visuals:AddLeftGroupbox('Staff Indicator')
local UI_ACCENT = Color3.fromRGB(255, 255, 255)

local staffIndicator = Drawing.new("Text")
staffIndicator.Text         = "Staff on server!"
staffIndicator.Size         = 28
staffIndicator.Color        = UI_ACCENT
staffIndicator.Outline      = true
staffIndicator.OutlineColor = Color3.fromRGB(0, 0, 0)
staffIndicator.Font         = 2
staffIndicator.Center       = true
staffIndicator.Visible      = false

local function updateIndicatorPosition()
    local cam = workspace.CurrentCamera
    if cam then
        staffIndicator.Position = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2 - 120)
    end
end
updateIndicatorPosition()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateIndicatorPosition)

local StaffDetector = {
    Enabled       = true,
    StaffOnline   = false,
    LastCheck     = 0,
    CheckInterval = 10,
}

local GROUP_ID   = WYNF_ENC_NUM(15631191)
local StaffRoles = { "Admin", "Admin+", "Cool coconut", "Developer", "Secret agent", "Lead developer", "Bob" }

local statusLabel = StaffIndicatorSection:AddLabel('Status: Checking...')

StaffIndicatorSection:AddToggle('StaffIndicator_Enabled', {
    Text    = 'Show Staff Indicator',
    Default = true,
    Tooltip = 'Shows warning when staff is online',
})
Toggles.StaffIndicator_Enabled:OnChanged(function()
    StaffDetector.Enabled = Toggles.StaffIndicator_Enabled.Value
    if not StaffDetector.Enabled then staffIndicator.Visible = false end
end)

StaffIndicatorSection:AddSlider('StaffCheck_Interval', {
    Text     = 'Check Interval',
    Default  = 10,
    Min      = 5,
    Max      = 60,
    Rounding = 0,
    Suffix   = 's',
    Compact  = false,
})
Options.StaffCheck_Interval:OnChanged(function()
    StaffDetector.CheckInterval = Options.StaffCheck_Interval.Value
end)

StaffIndicatorSection:AddButton({
    Text = 'Check Now',
    Func = function()
        if StaffDetector.Enabled then
            Library:Notify('Checking for staff...', 2)
            task.spawn(checkStaffOnline)
        end
    end,
})

function checkStaffOnline()
    if not StaffDetector.Enabled then staffIndicator.Visible = false; return end

    local http    = game:GetService("HttpService")
    local players = Players:GetPlayers()
    local staffIds = {}

    local success, rolesJson = pcall(function()
        return game:HttpGet("https://groups.roblox.com/v1/groups/" .. GROUP_ID .. "/roles")
    end)
    if not success or not rolesJson or rolesJson == "" then
        StaffDetector.StaffOnline = false
        staffIndicator.Visible = false
        if statusLabel then statusLabel:SetText('Status: Error fetching roles') end
        return
    end

    local ok, rolesData = pcall(http.JSONDecode, http, rolesJson)
    if not ok or not rolesData or not rolesData.roles then
        StaffDetector.StaffOnline = false
        staffIndicator.Visible = false
        if statusLabel then statusLabel:SetText('Status: Error parsing roles') end
        return
    end

    for _, role in ipairs(rolesData.roles) do
        if table.find(StaffRoles, role.name) then
            local s, usersJson = pcall(function()
                return game:HttpGet("https://groups.roblox.com/v1/groups/" .. GROUP_ID .. "/roles/" .. role.id .. "/users?limit=100")
            end)
            if s and usersJson and usersJson ~= "" then
                local ok2, usersData = pcall(http.JSONDecode, http, usersJson)
                if ok2 and usersData and usersData.data then
                    for _, member in ipairs(usersData.data) do
                        staffIds[member.userId] = true
                    end
                end
            end
            task.wait(0.2)
        end
    end

    local anyOnline = false
    local staffNames = {}
    for _, player in ipairs(players) do
        if staffIds[player.UserId] then
            anyOnline = true
            table.insert(staffNames, player.Name)
        end
    end
    StaffDetector.StaffOnline = anyOnline

    if anyOnline then
        if statusLabel then statusLabel:SetText('Status: STAFF ONLINE (' .. #staffNames .. ')') end
        Library:Notify('Staff detected: ' .. table.concat(staffNames, ', '), 5)
    else
        if statusLabel then statusLabel:SetText('Status: No staff detected') end
    end
end

-- OPTIMIZED: animation at 30fps via Heartbeat instead of every render frame
local lastStaffAnim = 0
RunService.Heartbeat:Connect(function()
    if Library.Unloaded then return end
    if tick() - lastStaffAnim < 0.033 then return end
    lastStaffAnim = tick()

    if not StaffDetector.Enabled or not StaffDetector.StaffOnline then
        staffIndicator.Visible = false
        return
    end

    staffIndicator.Visible = true
    local t          = tick()
    local brightness = 0.6 + 0.4 * math.abs(math.sin(t * 3))
    staffIndicator.Color = Color3.fromRGB(255 * brightness, 255 * brightness, 255 * brightness)
    staffIndicator.Size  = 28 + math.sin(t * 4) * 2
end)

task.spawn(function()
    while true do
        if Library.Unloaded then break end
        if StaffDetector.Enabled then
            if tick() - StaffDetector.LastCheck >= StaffDetector.CheckInterval then
                StaffDetector.LastCheck = tick()
                checkStaffOnline()
            end
        end
        task.wait(1)
    end
end)

task.delay(2, function()
    if StaffDetector.Enabled then checkStaffOnline() end
end)

Library:OnUnload(function()
    if staffIndicator then
        staffIndicator.Visible = false
        staffIndicator:Remove()
    end
end)

-- ══════════════════════════════════════════════════════════════════════════════
--  CAMERA
-- ══════════════════════════════════════════════════════════════════════════════

local function setupLocalCamera()
    local CameraSection = Tabs.Misc:AddLeftGroupbox('Camera')

    local StretchEnabled = false
    local StretchValue   = 0.65
    local fovLockEnabled = false
    local targetFOV      = 120
    local zoomEnabled    = false
    local origFOV        = Camera.FieldOfView

    CameraSection:AddToggle('Camera_StretchEnabled', {
        Text     = 'Stretch Enabled',
        Default  = false,
        Tooltip  = 'Enable camera stretch',
        Callback = function(v) StretchEnabled = v end,
    })
    CameraSection:AddSlider('Camera_Stretch', {
        Text     = 'Stretch %',
        Default  = 65,
        Min      = 30,
        Max      = 100,
        Rounding = 0,
        Callback = function(v) StretchValue = v / 100 end,
    })
    CameraSection:AddDivider()

    CameraSection:AddToggle('Camera_FOVLock', {
        Text     = 'FOV',
        Default  = false,
        Callback = function(v)
            fovLockEnabled = v
            if not v and not zoomEnabled then
                Camera.FieldOfView = origFOV
            end
        end,
    })
    CameraSection:AddSlider('Camera_FOV', {
        Text     = 'Field of View',
        Default  = 120,
        Min      = 50,
        Max      = 120,
        Rounding = 0,
        Callback = function(v) targetFOV = v end,
    })
    CameraSection:AddDivider()

    CameraSection:AddToggle('Camera_Zoom', {
        Text     = 'Zoom',
        Default  = false,
        Callback = function(v) zoomEnabled = v end,
    })
    CameraSection:AddLabel('Zoom Key'):AddKeyPicker('Camera_ZoomKey', {
        Default = 'None',
        NoUI    = false,
        Text    = 'Zoom Key',
    })

    KeybindSystem:Register(
        "Zoom",
        function() return Options.Camera_ZoomKey and Options.Camera_ZoomKey.Value end,
        Toggles.Camera_Zoom,
        "Hold"
    )

    pcall(function()
        local _fovOldNamecall
        _fovOldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if (fovLockEnabled or zoomEnabled) and self == Camera and not checkcaller() then
                if method == "Interpolate" then return nil end
            end
            return _fovOldNamecall(self, ...)
        end))
    end)

    Camera:GetPropertyChangedSignal("FieldOfView"):Connect(function()
        local effectiveFOV = zoomEnabled and 30 or targetFOV
        if (fovLockEnabled or zoomEnabled) and Camera.FieldOfView ~= effectiveFOV then
            Camera.FieldOfView = effectiveFOV
        end
    end)

    RunService:BindToRenderStep("ScytheCameraUpdate", Enum.RenderPriority.Camera.Value + 1, function()
        if not Camera then return end
        if StretchEnabled then
            Camera.CFrame = Camera.CFrame * CFrame.new(0, 0, 0, 1, 0, 0, 0, StretchValue, 0, 0, 0, 1)
        end
        local effectiveFOV = zoomEnabled and 30 or targetFOV
        if (fovLockEnabled or zoomEnabled) and Camera.FieldOfView ~= effectiveFOV then
            Camera.FieldOfView = effectiveFOV
        end
    end)
end
setupLocalCamera()

-- ══════════════════════════════════════════════════════════════════════════════
--  VIEWMODEL MODS (No Sway / No Bob / No Fire Kick)
-- ══════════════════════════════════════════════════════════════════════════════

local function setupViewmodelMods()
    local ViewmodelSection = Tabs.Misc:AddRightGroupbox('Viewmodel')
    local vmPath = ReplicatedStorage:FindFirstChild("ViewModel")

    if vmPath and vmPath:FindFirstChild("Scripts") then
        local okSway,  swayMod  = pcall(function() return require(vmPath.Scripts.SwayViewModel)   end)
        local okBob,   bobMod   = pcall(function() return require(vmPath.Scripts.BobbleViewModel) end)
        local okFire,  fireMod  = pcall(function() return require(vmPath.Scripts.FireViewModel)   end)

        ViewmodelSection:AddToggle('Viewmodel_NoSway', {
            Text     = 'No Sway',
            Default  = false,
            Callback = function(val)
                if okSway and swayMod then
                    if val then
                        swayMod._originalUpdate = swayMod._originalUpdate or swayMod.update
                        swayMod.update = function(p7, _, p8, p9) return p9 end
                    else
                        if swayMod._originalUpdate then swayMod.update = swayMod._originalUpdate end
                    end
                end
            end,
        })

        ViewmodelSection:AddToggle('Viewmodel_NoBob', {
            Text     = 'No Bobble',
            Default  = false,
            Callback = function(val)
                if okBob and bobMod then
                    if val then
                        bobMod._originalUpdate = bobMod._originalUpdate or bobMod.update
                        bobMod.update = function(p12, _, _, p13) return p13 end
                    else
                        if bobMod._originalUpdate then bobMod.update = bobMod._originalUpdate end
                    end
                end
            end,
        })

        ViewmodelSection:AddToggle('Viewmodel_NoFireKick', {
            Text     = 'No Fire anim',
            Default  = false,
            Callback = function(val)
                if okFire and fireMod then
                    if val then
                        fireMod._originalUpdate = fireMod._originalUpdate or fireMod.update
                        fireMod.update = function(p8, _, p9, p10) return p10 end
                    else
                        if fireMod._originalUpdate then fireMod.update = fireMod._originalUpdate end
                    end
                end
            end,
        })
    else
        ViewmodelSection:AddLabel('ViewModel scripts not found!')
    end
end
setupViewmodelMods()

-- ══════════════════════════════════════════════════════════════════════════════
--  HIT SOUNDS
-- ══════════════════════════════════════════════════════════════════════════════

local function setupHitSounds()
    local HitSoundsSection = Tabs.World:AddRightGroupbox('Hit Sounds')

    local HitSoundPresets = {
        "None","Magic","Firework","Lazer","Pop","Zap","Neverlose","Skeet",
        "Sonic checkpoint","Sonic.exe laugh","Windows XP Error","Minecraft Hit",
        "one sit nn dog","Door Bell","Duck","Mgs","Money","Fart","Meow","byebye",
    }

    local HitSoundIDs = {
        ["None"]               = "",
        ["Magic"]              = "182765513",
        ["Firework"]           = "269146157",
        ["Lazer"]              = "360661189",
        ["Pop"]                = "127231141534262",
        ["Zap"]                = "9119594928",
        ["Neverlose"]          = "18391691942",
        ["Skeet"]              = "83717596220569",
        ["Sonic checkpoint"]   = "6817150445",
        ["Sonic.exe laugh"]    = "18379039436",
        ["Windows XP Error"]   = "9066167010",
        ["Minecraft Hit"]      = "8766809464",
        ["one sit nn dog"]     = "7380502345",
        ["Door Bell"]          = "131845870598154",
        ["Duck"]               = "1139819274",
        ["Mgs"]                = "81845122657643",
        ["Money"]              = "3020841054",
        ["Fart"]               = "4809574295",
        ["Meow"]               = "7148585764",
        ["byebye"]             = "70888261086432",
    }

    local HitSounds = {
        Enabled       = false,
        Choice        = "None",
        Volume        = 1.0,
        OriginalSounds = {},
    }

    local function isValidHitSound(sound)
        local parent = sound.Parent
        if not parent or parent.Name ~= "BodyAttach" then return false end
        if sound.Name == "HitClient" or sound.Name == "HeadShotClient" or sound.Name == "HitCharacterClient" then
            local tool = parent.Parent
            if not tool or not tool:IsA("Tool") then return false end
            return tool.Parent == LocalPlayer.Character
        end
        return false
    end

    local function applyHitSoundsToExisting()
        local char = LocalPlayer.Character
        if not char then return end
        local assetId = HitSoundIDs[HitSounds.Choice] or ""

        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") then
                local bodyAttach = tool:FindFirstChild("BodyAttach")
                if bodyAttach then
                    for _, soundName in ipairs({ "HitClient", "HeadShotClient", "HitCharacterClient" }) do
                        local sound = bodyAttach:FindFirstChild(soundName)
                        if sound and sound:IsA("Sound") then
                            if not HitSounds.OriginalSounds[sound] then
                                HitSounds.OriginalSounds[sound] = { SoundId = sound.SoundId, Volume = sound.Volume }
                            end
                            if HitSounds.Enabled and assetId ~= "" then
                                sound.SoundId = "rbxassetid://" .. assetId
                                sound.Volume  = HitSounds.Volume
                            else
                                local orig = HitSounds.OriginalSounds[sound]
                                if orig then
                                    sound.SoundId = orig.SoundId
                                    sound.Volume  = orig.Volume
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    local function resetAllHitSounds()
        for sound, orig in pairs(HitSounds.OriginalSounds) do
            if sound and sound:IsA("Sound") then
                sound.SoundId = orig.SoundId
                sound.Volume  = orig.Volume
            end
        end
        HitSounds.OriginalSounds = {}
    end

    workspace.DescendantAdded:Connect(function(obj)
        if not HitSounds.Enabled then return end
        if obj:IsA("Tool") then
            task.wait(0.1)
            applyHitSoundsToExisting()
        elseif obj:IsA("Sound") and isValidHitSound(obj) then
            if not HitSounds.OriginalSounds[obj] then
                HitSounds.OriginalSounds[obj] = { SoundId = obj.SoundId, Volume = obj.Volume }
            end
            local assetId = HitSoundIDs[HitSounds.Choice]
            if assetId and assetId ~= "" then
                obj.SoundId = "rbxassetid://" .. assetId
                obj.Volume  = HitSounds.Volume
            end
        end
    end)

    LocalPlayer.CharacterAdded:Connect(function()
        if HitSounds.Enabled then
            task.wait(0.5)
            applyHitSoundsToExisting()
        end
    end)

    HitSoundsSection:AddToggle('HitSounds_Enabled', {
        Text     = 'Hit Sound Enabled',
        Default  = false,
        Tooltip  = 'Enable custom hit sounds',
        Callback = function(state)
            HitSounds.Enabled = state
            if state then applyHitSoundsToExisting() else resetAllHitSounds() end
        end,
    })
    HitSoundsSection:AddDropdown('HitSounds_Choice', {
        Values   = HitSoundPresets,
        Default  = "None",
        Multi    = false,
        Text     = 'Hit Sound',
        Tooltip  = 'Select hit sound',
        Callback = function(v)
            HitSounds.Choice = v
            if HitSounds.Enabled then applyHitSoundsToExisting() end
        end,
    })
    HitSoundsSection:AddSlider('HitSounds_Volume', {
        Text     = 'Volume',
        Default  = 100,
        Min      = 0,
        Max      = 100,
        Rounding = 0,
        Compact  = false,
        Callback = function(v)
            HitSounds.Volume = v / 100
            if HitSounds.Enabled then applyHitSoundsToExisting() end
        end,
    })
end
setupHitSounds()

-- ══════════════════════════════════════════════════════════════════════════════
--  COMBAT: NO RECOIL / NO SPREAD / RELOAD CANCEL
--  OPTIMIZED: force-shoot hook check every 5 frames
-- ══════════════════════════════════════════════════════════════════════════════

local function setupCombat()
    local CombatSection = Tabs.Combat:AddLeftGroupbox('Weapon')

    local recoilModule   = nil
    local spreadPatched  = false
    local spreadOldFuncs = {}
    local ForceShoot     = { Enabled = false }
    local GunBaseModule  = nil
    local originalCanFire = nil
    local originalFire    = nil
    local hooksApplied    = false

    -- No Recoil
    local function setupNoRecoil(state)
        if state then
            if not recoilModule then
                pcall(function()
                    recoilModule = require(
                        ReplicatedStorage:WaitForChild("Gun")
                            :WaitForChild("Scripts")
                            :WaitForChild("RecoilHandler")
                    )
                end)
            end
            if recoilModule then
                if not recoilModule._original_nextStep then
                    recoilModule._original_nextStep           = recoilModule.nextStep
                    recoilModule._original_setRecoilMultiplier = recoilModule.setRecoilMultiplier
                end
                recoilModule.nextStep             = function() end
                recoilModule.setRecoilMultiplier  = function() end
            end
        elseif recoilModule then
            if recoilModule._original_nextStep then
                recoilModule.nextStep            = recoilModule._original_nextStep
                recoilModule._original_nextStep  = nil
            end
            if recoilModule._original_setRecoilMultiplier then
                recoilModule.setRecoilMultiplier            = recoilModule._original_setRecoilMultiplier
                recoilModule._original_setRecoilMultiplier  = nil
            end
        end
    end

    CombatSection:AddToggle('Combat_NoRecoil', {
        Text     = 'No Recoil',
        Default  = false,
        Callback = function(state) setupNoRecoil(state) end,
    })

    -- No Spread
    local function setupNoSpread(state)
        local utilsModule = ReplicatedStorage:FindFirstChild("Utils")
        if utilsModule and utilsModule:IsA("ModuleScript") then
            local success, content = pcall(require, utilsModule)
            if success and type(content) == "table" and content.applySpreadToDirection then
                if state then
                    if not spreadPatched then
                        spreadOldFuncs.applySpreadToDirection = content.applySpreadToDirection
                        content.applySpreadToDirection        = function(direction, ...) return direction end
                        spreadPatched = true
                    end
                elseif spreadPatched and spreadOldFuncs.applySpreadToDirection then
                    content.applySpreadToDirection = spreadOldFuncs.applySpreadToDirection
                    spreadPatched = false
                end
            end
        end

        local gcPath = ReplicatedStorage:FindFirstChild("Gun")
            and ReplicatedStorage.Gun:FindFirstChild("Scripts")
            and ReplicatedStorage.Gun.Scripts:FindFirstChild("GunClient")

        if gcPath and gcPath:IsA("ModuleScript") then
            local success, content = pcall(require, gcPath)
            if success and type(content) == "table" and content.updateSpreadMult then
                if state then
                    if not spreadOldFuncs.updateSpreadMult then
                        spreadOldFuncs.updateSpreadMult = content.updateSpreadMult
                    end
                    content.updateSpreadMult = function(...) return 0 end
                elseif spreadOldFuncs.updateSpreadMult then
                    content.updateSpreadMult = spreadOldFuncs.updateSpreadMult
                end
            end
        end
    end

    CombatSection:AddToggle('Combat_NoSpread', {
        Text     = 'No Spread',
        Default  = false,
        Callback = function(state) setupNoSpread(state) end,
    })

    CombatSection:AddDivider()

    -- Reload Cancel
    CombatSection:AddToggle('ForceShoot_Enabled', {
        Text     = 'Reload Cancel',
        Default  = false,
        Callback = function(v) ForceShoot.Enabled = v end,
    })

    local function applyForceShootHooks()
        if hooksApplied then return end
        local success, gunBase = pcall(function()
            return require(
                ReplicatedStorage:WaitForChild("Gun")
                    :WaitForChild("Scripts")
                    :WaitForChild("GunBase")
            )
        end)
        if not success or not gunBase then return end

        GunBaseModule  = gunBase
        originalCanFire = gunBase.canFire
        originalFire    = gunBase.fire

        gunBase.canFire = function(self, ...)
            if ForceShoot.Enabled then
                local hasAmmo = true
                pcall(function()
                    if self.Ammo        ~= nil and self.Ammo        <= 0 then hasAmmo = false end
                    if self.CurrentAmmo ~= nil and self.CurrentAmmo <= 0 then hasAmmo = false end
                    if self.ClipAmmo    ~= nil and self.ClipAmmo    <= 0 then hasAmmo = false end
                    if self.MagazineAmmo ~= nil and self.MagazineAmmo <= 0 then hasAmmo = false end
                end)
                if hasAmmo then return true end
            end
            return originalCanFire(self, ...)
        end

        gunBase.fire = function(self, ...)
            if ForceShoot.Enabled then
                self.FiringOnCooldown = false
                pcall(function()
                    if self.IsReloading ~= nil then self.IsReloading = false end
                    if self.Reloading   ~= nil then self.Reloading   = false end
                end)
            end
            return originalFire(self, ...)
        end

        hooksApplied = true
    end

    local function removeForceShootHooks()
        if not hooksApplied or not GunBaseModule then return end
        if originalCanFire then GunBaseModule.canFire = originalCanFire end
        if originalFire    then GunBaseModule.fire    = originalFire    end
        hooksApplied = false
    end

    -- OPTIMIZED: check every 5 frames instead of every frame
    local fsFrame = 0
    RunService.RenderStepped:Connect(function()
        fsFrame = fsFrame + 1
        if fsFrame % 5 ~= 0 then return end
        if ForceShoot.Enabled and not hooksApplied then
            applyForceShootHooks()
        elseif not ForceShoot.Enabled and hooksApplied then
            removeForceShootHooks()
        end
    end)
end
setupCombat()



CurrentAimPoint  = nil
CurrentAimTarget = nil

local function setupSilentAim()
    local SilentAimSection = Tabs.Combat:AddRightGroupbox('Silent Aim')

    SilentAim = SilentAim or {
        Enabled            = false,
        TargetPart         = "HumanoidRootPart",
        WallCheck          = false,
        DeadCheck          = true,
        MaxDistance        = 500,
        UseFOV             = true,
        FOVRadius          = 150,
        Snapline           = true,
        SnaplineColor      = Color3.fromRGB(255, 255, 255),
        SnaplineThickness  = 3,
        FOVStyle           = "Circle",
        FOVColor           = Color3.fromRGB(255, 255, 255),
        VisiblePoint       = true,
    }

    -- Single shared RaycastParams — never re-create in the loop
    local visParams = RaycastParams.new()
    visParams.FilterType        = Enum.RaycastFilterType.Exclude
    visParams.RespectCanCollide = false

    -- Hitbox names to scan (priority order)
    local HITBOX_NAMES   = { "HeadHitbox", "TorsoHitbox" }
    -- Fallback body parts if no hitboxes found
    local FALLBACK_PARTS = { "Head", "UpperTorso", "HumanoidRootPart", "Torso" }

    -- Grid resolution: GRID × GRID points per hitbox face = 9 raycasts
    local GRID = 3

    --[[
        sampleVisibleSurface(character, camPos, mousePos, fovRadSq)

        For each hitbox part:
          1. Project the camera→part direction onto the part's local axes to find
             which face (±X, ±Y, ±Z) is closest to the camera.
          2. Lay a GRID×GRID grid over that face with a small inset (0.85× size).
          3. Raycast from camera to each grid point; keep the one nearest to the
             mouse cursor that is not occluded.

        This replaces the old 15-corner scan that ran every frame per player.
    --]]
    local function sampleVisibleSurface(character, camPos, mousePos, fovRadSq)
        local bestPoint  = nil
        local bestDistSq = fovRadSq

        visParams.FilterDescendantsInstances = { LocalPlayer.Character, character }

        for _, hbName in ipairs(HITBOX_NAMES) do
            local hb = character:FindFirstChild(hbName)
            if not hb or not hb:IsA("BasePart") then continue end

            local cf   = hb.CFrame
            local half = hb.Size * 0.5

            -- Which face points most toward the camera?
            local toCam = camPos - cf.Position
            local lx    = cf.RightVector:Dot(toCam)
            local ly    = cf.UpVector:Dot(toCam)
            local lz    = cf.LookVector:Dot(toCam)
            local ax, ay, az = math.abs(lx), math.abs(ly), math.abs(lz)

            local faceNormal, faceU, faceV, halfU, halfV, faceDist

            if ax >= ay and ax >= az then
                local sign   = lx > 0 and 1 or -1
                faceNormal   = cf.RightVector  * sign
                faceU, faceV = cf.UpVector,     cf.LookVector
                halfU, halfV = half.Y,           half.Z
                faceDist     = half.X
            elseif ay >= ax and ay >= az then
                local sign   = ly > 0 and 1 or -1
                faceNormal   = cf.UpVector     * sign
                faceU, faceV = cf.RightVector,  cf.LookVector
                halfU, halfV = half.X,           half.Z
                faceDist     = half.Y
            else
                local sign   = lz > 0 and 1 or -1
                faceNormal   = cf.LookVector   * sign
                faceU, faceV = cf.RightVector,  cf.UpVector
                halfU, halfV = half.X,           half.Y
                faceDist     = half.Z
            end

            local faceCenter = cf.Position + faceNormal * faceDist
            local step       = 1 / (GRID - 1)

            for ui = 0, GRID - 1 do
                for vi = 0, GRID - 1 do
                    local u     = (ui * step - 0.5) * 2 * halfU * 0.85
                    local v     = (vi * step - 0.5) * 2 * halfV * 0.85
                    local point = faceCenter + faceU * u + faceV * v

                    local dir      = point - camPos
                    local dist     = dir.Magnitude
                    local res      = workspace:Raycast(camPos, dir, visParams)

                    local visible  = not res
                        or (res.Instance and res.Instance:IsDescendantOf(character))
                        or (res.Position - camPos).Magnitude >= dist - 0.3

                    if visible then
                        local sp, onScreen = Camera:WorldToViewportPoint(point)
                        if onScreen then
                            local dx   = sp.X - mousePos.X
                            local dy   = sp.Y - mousePos.Y
                            local dSq  = dx * dx + dy * dy
                            if dSq < bestDistSq then
                                bestDistSq = dSq
                                bestPoint  = point
                            end
                        end
                    end
                end
            end
        end

        -- Fallback: no hitboxes found, check standard body parts
        if not bestPoint then
            for _, partName in ipairs(FALLBACK_PARTS) do
                local part = character:FindFirstChild(partName)
                if not part then continue end
                local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local dx  = sp.X - mousePos.X
                    local dy  = sp.Y - mousePos.Y
                    local dSq = dx * dx + dy * dy
                    if dSq < bestDistSq then
                        bestDistSq = dSq
                        bestPoint  = part.Position
                    end
                end
            end
        end

        return bestPoint
    end

    -- ── FOV GUI ───────────────────────────────────────────────────────────────
    local FOVGui, FOVContainer, FOVStroke, DotsPool = nil, nil, nil, {}

    local function createFOVUI()
        if FOVGui then FOVGui:Destroy() end

        FOVGui = Instance.new("ScreenGui")
        FOVGui.Name           = "SilentAimFOV"
        FOVGui.Parent         = CoreGui
        FOVGui.IgnoreGuiInset = true
        FOVGui.DisplayOrder   = 999
        FOVGui.Enabled        = false

        FOVContainer = Instance.new("Frame")
        FOVContainer.AnchorPoint          = Vector2.new(0.5, 0.5)
        FOVContainer.BackgroundTransparency = 1
        FOVContainer.BorderSizePixel      = 0
        FOVContainer.Parent               = FOVGui

        FOVStroke = Instance.new("UIStroke")
        FOVStroke.Thickness        = 2
        FOVStroke.ApplyStrokeMode  = Enum.ApplyStrokeMode.Border
        FOVStroke.Parent           = FOVContainer
        Instance.new("UICorner", FOVContainer).CornerRadius = UDim.new(1, 0)

        DotsPool = {}
        for i = 1, 24 do
            local dot = Instance.new("Frame")
            dot.Size                 = UDim2.new(0, 3, 0, 3)
            dot.BorderSizePixel      = 0
            dot.BackgroundTransparency = 1
            dot.Visible              = false
            dot.Parent               = FOVContainer
            Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
            DotsPool[i] = dot
        end
    end

    -- ── Snapline via Drawing API (persistent, zero GC pressure) ──────────────
    local snapLine = Drawing.new("Line")
    snapLine.Visible      = false
    snapLine.Color        = SilentAim.SnaplineColor
    snapLine.Thickness    = SilentAim.SnaplineThickness
    snapLine.Transparency = 0

    Library:OnUnload(function() snapLine:Remove() end)

    -- ── Target search (throttled) ─────────────────────────────────────────────
    local frameCount    = 0
    local cachedPart    = nil
    local cachedPoint   = nil

    local function findTarget()
        local mousePos  = UserInputService:GetMouseLocation()
        local camPos    = Camera.CFrame.Position
        local fovRadSq  = SilentAim.FOVRadius ^ 2
        local maxDist   = SilentAim.MaxDistance

        local bestPart   = nil
        local bestPoint  = nil
        local bestDistSq = fovRadSq

        for _, player in ipairs(Players:GetPlayers()) do
            if player == LocalPlayer then continue end
            local character = player.Character
            if not character then continue end

            if SilentAim.DeadCheck then
                local hum = character:FindFirstChildOfClass("Humanoid")
                if not hum or hum.Health <= 0 then continue end
            end

            local hrp = character:FindFirstChild("HumanoidRootPart")
            if not hrp then continue end

            -- Fast 3D distance cull
            if (hrp.Position - camPos).Magnitude > maxDist then continue end

            -- Fast 2D screen-space pre-cull — skip players far outside FOV×2.5
            local sp0, on0 = Camera:WorldToViewportPoint(hrp.Position)
            if not on0 then continue end
            local dx0 = sp0.X - mousePos.X
            local dy0 = sp0.Y - mousePos.Y
            if dx0 * dx0 + dy0 * dy0 > (SilentAim.FOVRadius * 2.5) ^ 2 then continue end

            -- Find the best visible point on this character
            local point
            if SilentAim.VisiblePoint then
                point = sampleVisibleSurface(character, camPos, mousePos, bestDistSq)
            else
                local p = character:FindFirstChild(SilentAim.TargetPart) or hrp
                point   = p and p.Position
            end

            if point then
                local sp, onScreen = Camera:WorldToViewportPoint(point)
                if onScreen then
                    local dx  = sp.X - mousePos.X
                    local dy  = sp.Y - mousePos.Y
                    local dSq = dx * dx + dy * dy
                    if dSq < bestDistSq then
                        bestDistSq = dSq
                        bestPart   = hrp
                        bestPoint  = point
                    end
                end
            end
        end

        return bestPart, bestPoint
    end

    -- ── Render loop ───────────────────────────────────────────────────────────
    RunService.RenderStepped:Connect(function()
        frameCount = frameCount + 1

        -- Recalculate target every 3 frames (~20×/sec at 60fps)
        if frameCount % 3 == 0 then
            if SilentAim.Enabled then
                cachedPart, cachedPoint = findTarget()
            else
                cachedPart  = nil
                cachedPoint = nil
            end
        end

        CurrentAimTarget = cachedPart
        CurrentAimPoint  = cachedPoint

        -- FOV circle / rotating dots
        if not FOVGui then createFOVUI() end

        if SilentAim.Enabled and SilentAim.UseFOV then
            FOVGui.Enabled = true
            local mousePos = UserInputService:GetMouseLocation()
            local radius   = SilentAim.FOVRadius

            FOVContainer.Position = UDim2.new(0, mousePos.X, 0, mousePos.Y)
            FOVContainer.Size     = UDim2.new(0, radius * 2, 0, radius * 2)

            FOVStroke.Transparency = 1
            for _, dot in ipairs(DotsPool) do
                dot.Visible              = false
                dot.BackgroundTransparency = 1
            end

            if SilentAim.FOVStyle == "Circle" then
                FOVStroke.Transparency = 0
                FOVStroke.Color        = SilentAim.FOVColor
            elseif SilentAim.FOVStyle == "Rotating Dots" then
                local t = tick()
                for i, dot in ipairs(DotsPool) do
                    dot.Visible              = true
                    dot.BackgroundTransparency = 0
                    dot.BackgroundColor3     = SilentAim.FOVColor
                    local angle = math.rad((i / #DotsPool) * 360) + t * 2
                    dot.Position = UDim2.new(0.5, math.cos(angle) * radius - 1.5,
                                             0.5, math.sin(angle) * radius - 1.5)
                end
            end
        else
            if FOVGui then FOVGui.Enabled = false end
        end

        -- Snapline
        if SilentAim.Enabled and CurrentAimPoint and SilentAim.Snapline then
            local pos3, onScreen = Camera:WorldToViewportPoint(CurrentAimPoint)
            if onScreen then
                snapLine.From      = UserInputService:GetMouseLocation()
                snapLine.To        = Vector2.new(pos3.X, pos3.Y)
                snapLine.Color     = SilentAim.SnaplineColor
                snapLine.Thickness = SilentAim.SnaplineThickness
                snapLine.Visible   = true
            else
                snapLine.Visible = false
            end
        else
            snapLine.Visible = false
        end
    end)

    createFOVUI()

    -- UI
    SilentAimSection:AddToggle('SilentAim_Enabled', {
        Text     = 'Silent Aim Enabled',
        Default  = false,
        Callback = function(v)
            SilentAim.Enabled = v
            if not v then snapLine.Visible = false end
        end,
    })
    SilentAimSection:AddToggle('SilentAim_VisiblePoint', {
        Text     = 'Surface Scanner',
        Default  = true,
        Tooltip  = 'Aims at the hitbox face toward camera (not just center)',
        Callback = function(v) SilentAim.VisiblePoint = v end,
    })
    SilentAimSection:AddDropdown('SilentAim_TargetPart', {
        Values   = { "Head", "HumanoidRootPart" },
        Default  = "HumanoidRootPart",
        Multi    = false,
        Text     = 'Fallback Part',
        Tooltip  = 'Used when Surface Scanner is off or hitboxes missing',
        Callback = function(v) SilentAim.TargetPart = v or "HumanoidRootPart" end,
    })
    SilentAimSection:AddToggle('SilentAim_WallCheck', {
        Text     = 'Wall Check',
        Default  = false,
        Callback = function(v) SilentAim.WallCheck = v end,
    })
    SilentAimSection:AddToggle('SilentAim_DeadCheck', {
        Text     = 'Dead Check',
        Default  = true,
        Callback = function(v) SilentAim.DeadCheck = v end,
    })
    SilentAimSection:AddSlider('SilentAim_MaxDistance', {
        Text     = 'Max Distance',
        Default  = 500,
        Min      = 50,
        Max      = 1500,
        Rounding = 0,
        Compact  = false,
        Callback = function(v) SilentAim.MaxDistance = v end,
    })
    SilentAimSection:AddDivider()
    SilentAimSection:AddToggle('SilentAim_UseFOV', {
        Text     = 'Use FOV',
        Default  = true,
        Callback = function(v) SilentAim.UseFOV = v end,
    })
    SilentAimSection:AddDropdown('SilentAim_FOVStyle', {
        Values   = { "Circle", "Rotating Dots" },
        Default  = "Circle",
        Multi    = false,
        Text     = 'FOV Style',
        Callback = function(v) SilentAim.FOVStyle = v end,
    })
    SilentAimSection:AddSlider('SilentAim_FOVRadius', {
        Text     = 'FOV Radius',
        Default  = 150,
        Min      = 50,
        Max      = 500,
        Rounding = 0,
        Compact  = false,
        Callback = function(v) SilentAim.FOVRadius = v end,
    })
    SilentAimSection:AddLabel('FOV Color'):AddColorPicker('SilentAim_FOVColor', {
        Default  = SilentAim.FOVColor,
        Title    = 'FOV Color',
        Callback = function(c) SilentAim.FOVColor = c end,
    })
    SilentAimSection:AddDivider()
    SilentAimSection:AddToggle('SilentAim_Snapline', {
        Text     = 'Snapline',
        Default  = true,
        Callback = function(v)
            SilentAim.Snapline = v
            if not v then snapLine.Visible = false end
        end,
    })
    SilentAimSection:AddLabel('Snapline Color'):AddColorPicker('SilentAim_SnaplineColor', {
        Default  = SilentAim.SnaplineColor,
        Title    = 'Snapline Color',
        Callback = function(c)
            SilentAim.SnaplineColor = c
            snapLine.Color          = c
        end,
    })
    SilentAimSection:AddSlider('SilentAim_SnaplineThickness', {
        Text     = 'Snapline Thickness',
        Default  = 3,
        Min      = 1,
        Max      = 8,
        Rounding = 0,
        Compact  = false,
        Callback = function(v)
            SilentAim.SnaplineThickness = v
            snapLine.Thickness          = v
        end,
    })
end
setupSilentAim()

-- ══════════════════════════════════════════════════════════════════════════════
--  BACKPACK ESP
--  OPTIMIZED: Heartbeat at 10×/sec instead of every render frame
-- ══════════════════════════════════════════════════════════════════════════════

local function setupBackpackESP()
    local BackpackGroup = Tabs.Visuals:AddRightGroupbox('Backpack ESP')

    local BackpackESP = {
        Enabled = false,
        Color   = Color3.fromRGB(100, 200, 255),
        MaxDist = 300,
    }

    BackpackGroup:AddToggle('BackpackESP_Enabled', {
        Text     = 'Backpack ESP Enabled',
        Default  = false,
        Callback = function(v) BackpackESP.Enabled = v end,
    })
    BackpackGroup:AddLabel('Backpack Color'):AddColorPicker('BackpackESP_Color', {
        Default  = BackpackESP.Color,
        Title    = 'Backpack Color',
        Callback = function(c) BackpackESP.Color = c end,
    })
    BackpackGroup:AddSlider('BackpackESP_MaxDist', {
        Text     = 'Max Distance',
        Default  = 300,
        Min      = 50,
        Max      = 1000,
        Rounding = 0,
        Callback = function(v) BackpackESP.MaxDist = v end,
    })

    local backpackBillboards = {}

    local function createBackpackBillboard(adornee, text)
        local bb = Instance.new("BillboardGui")
        bb.Name        = "BackpackESP"
        bb.Adornee     = adornee
        bb.Size        = UDim2.fromOffset(150, 24)
        bb.StudsOffset = Vector3.new(0, 2, 0)
        bb.AlwaysOnTop = true
        bb.Parent      = adornee

        local label = Instance.new("TextLabel", bb)
        label.Size                   = UDim2.fromScale(1, 1)
        label.BackgroundTransparency = 1
        label.TextSize               = 14
        label.Font                   = Enum.Font.GothamBold
        label.TextColor3             = BackpackESP.Color
        label.TextStrokeTransparency = 0.3
        label.TextStrokeColor3       = Color3.new(0, 0, 0)
        label.Text                   = text
        return bb
    end

    -- OPTIMIZED: Heartbeat at 10×/sec
    local lastBPUpdate = 0
    RunService.Heartbeat:Connect(function()
        if tick() - lastBPUpdate < 0.1 then return end
        lastBPUpdate = tick()

        if not BackpackESP.Enabled then
            for _, bb in pairs(backpackBillboards) do
                if bb then bb:Destroy() end
            end
            backpackBillboards = {}
            return
        end

        local folder = workspace:FindFirstChild("DeathBackpacks")
        if not folder then return end

        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not root then return end

        for _, obj in ipairs(folder:GetChildren()) do
            if obj:IsA("Model") and obj.Name == "DeathBackback" then
                local adornee = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                if not adornee then continue end

                local dist = (adornee.Position - root.Position).Magnitude
                if dist > BackpackESP.MaxDist then
                    if backpackBillboards[obj] then
                        backpackBillboards[obj]:Destroy()
                        backpackBillboards[obj] = nil
                    end
                    continue
                end

                local text = string.format("Backpack [%.0fm]", dist)

                if not backpackBillboards[obj] then
                    backpackBillboards[obj] = createBackpackBillboard(adornee, text)
                else
                    local label = backpackBillboards[obj]:FindFirstChildOfClass("TextLabel")
                    if label then
                        label.Text       = text
                        label.TextColor3 = BackpackESP.Color
                    end
                end
            end
        end
    end)
end
setupBackpackESP()

-- ══════════════════════════════════════════════════════════════════════════════
--  ADVANCED ANTI AIM
-- ══════════════════════════════════════════════════════════════════════════════

local function setupAntiAim()
    local AA = {
        Enabled      = false,
        BodyYaw      = 'Backward',
        BodyYawOff   = 0,
        BodyPitch    = 'Down',
        BodyPitchVal = 89,
        BodyRoll     = 0,
        HeadYaw      = 'Opposite',
        HeadYawOff   = 0,
        HeadPitch    = 'Up',
        HeadPitchVal = 50,
        HeadRoll     = 0,
        Desync       = false,
        DesyncAmount = 58,
        DesyncRate   = 5,
        SpinSpeed    = 8,
        JitterRange  = 90,
    }

    local conn       = nil
    local origNeckC0 = nil

    local function getRoot()
        local c = LocalPlayer.Character
        return c and c:FindFirstChild('HumanoidRootPart')
    end

    local function getHum()
        local c = LocalPlayer.Character
        return c and c:FindFirstChildOfClass('Humanoid')
    end

    local function getNeck()
        local c = LocalPlayer.Character
        if not c then return nil end
        local torso = c:FindFirstChild('Torso') or c:FindFirstChild('UpperTorso')
        return torso and torso:FindFirstChild('Neck')
    end

    local function camFlat()
        local lv = Camera.CFrame.LookVector
        return Vector3.new(lv.X, 0, lv.Z).Unit
    end

    local function buildBodyCF(root)
        local flat = camFlat()
        local pos  = root.Position
        local base

        if AA.BodyYaw == 'Forward' then
            base = CFrame.new(pos, pos + flat)
        elseif AA.BodyYaw == 'Backward' then
            base = CFrame.new(pos, pos - flat)
        elseif AA.BodyYaw == 'Spin' then
            base = CFrame.new(pos) * CFrame.Angles(0, tick() * AA.SpinSpeed, 0)
        elseif AA.BodyYaw == 'Jitter' then
            local side = (math.floor(tick() * 20) % 2 == 0) and 1 or -1
            base = CFrame.new(pos, pos + flat) * CFrame.Angles(0, math.rad(side * AA.JitterRange), 0)
        elseif AA.BodyYaw == 'Static' then
            base = CFrame.new(pos) * CFrame.Angles(0, math.rad(AA.BodyYawOff), 0)
        else
            base = CFrame.new(pos, pos - flat)
        end

        if AA.BodyYaw ~= 'Static' then
            base = base * CFrame.Angles(0, math.rad(AA.BodyYawOff), 0)
        end

        if AA.Desync then
            local flip = (math.floor(tick() * AA.DesyncRate) % 2 == 0) and 1 or -1
            base = base * CFrame.Angles(0, math.rad(flip * AA.DesyncAmount), 0)
        end

        local pitch = 0
        if     AA.BodyPitch == 'Down'   then pitch =  AA.BodyPitchVal
        elseif AA.BodyPitch == 'Up'     then pitch = -AA.BodyPitchVal
        elseif AA.BodyPitch == 'Custom' then pitch =  AA.BodyPitchVal
        end

        return base * CFrame.Angles(math.rad(pitch), 0, math.rad(AA.BodyRoll))
    end

    local function buildNeckC0(neck)
        if not origNeckC0 then return neck.C0 end

        local flat   = camFlat()
        local rootCF = getRoot() and getRoot().CFrame or CFrame.new()
        local headYawRad = 0

        if AA.HeadYaw == 'Opposite' then
            local bodyBack = -rootCF.LookVector
            local dot      = flat:Dot(bodyBack)
            headYawRad     = math.acos(math.clamp(dot, -1, 1)) * (flat:Cross(bodyBack).Y > 0 and -1 or 1)
            headYawRad     = headYawRad + math.pi
        elseif AA.HeadYaw == 'Camera' then
            local bodyFwd = rootCF.LookVector
            local dot     = flat:Dot(bodyFwd)
            headYawRad    = math.acos(math.clamp(dot, -1, 1)) * (flat:Cross(bodyFwd).Y > 0 and -1 or 1)
        elseif AA.HeadYaw == 'Spin' then
            headYawRad = tick() * AA.SpinSpeed * 0.5
        elseif AA.HeadYaw == 'Jitter' then
            local side = (math.floor(tick() * 25) % 2 == 0) and 1 or -1
            headYawRad = math.rad(side * AA.JitterRange * 0.5)
        elseif AA.HeadYaw == 'Static' then
            headYawRad = math.rad(AA.HeadYawOff)
        elseif AA.HeadYaw == 'Fake' then
            local bodyFwd = rootCF.LookVector
            local camDir  = flat
            local dot     = camDir:Dot(bodyFwd)
            headYawRad    = math.acos(math.clamp(dot, -1, 1)) * (camDir:Cross(bodyFwd).Y > 0 and -1 or 1)
            headYawRad    = headYawRad + math.pi
        end

        headYawRad = headYawRad + math.rad(AA.HeadYawOff)

        local headPitch = 0
        if     AA.HeadPitch == 'Up'     then headPitch = math.rad(-AA.HeadPitchVal)
        elseif AA.HeadPitch == 'Down'   then headPitch = math.rad( AA.HeadPitchVal)
        elseif AA.HeadPitch == 'Custom' then headPitch = math.rad( AA.HeadPitchVal)
        end

        return origNeckC0 * CFrame.Angles(headPitch, headYawRad, math.rad(AA.HeadRoll))
    end

    local function stop()
        if conn then conn:Disconnect(); conn = nil end
        local hum = getHum()
        if hum then hum.AutoRotate = true end
        local neck = getNeck()
        if neck and origNeckC0 then neck.C0 = origNeckC0 end
        origNeckC0 = nil
    end

    local function start()
        stop()
        if not AA.Enabled then return end

        local hum = getHum()
        if hum then hum.AutoRotate = false end

        local neck = getNeck()
        if neck then origNeckC0 = neck.C0 end

        conn = RunService.RenderStepped:Connect(function()
            local root = getRoot()
            if not root then return end

            root.CFrame = buildBodyCF(root)

            local neck2 = getNeck()
            if neck2 then
                if not origNeckC0 then origNeckC0 = neck2.C0 end
                neck2.C0 = buildNeckC0(neck2)
            end
        end)
    end

    LocalPlayer.CharacterAdded:Connect(function()
        origNeckC0 = nil
        if AA.Enabled then
            task.wait(0.5)
            start()
        end
    end)

    local Group = Tabs.Combat:AddRightGroupbox('Advanced Anti Aim')

    Group:AddToggle('AntiAim_Enabled', {
        Text     = 'Enable Anti Aim',
        Default  = false,
        Callback = function(v)
            AA.Enabled = v
            if v then start() else stop() end
        end,
    })
    Group:AddDivider()
    Group:AddLabel('— Body —')
    Group:AddDropdown('AntiAim_BodyYaw',      { Text = 'Body Yaw',          Values = {'Forward','Backward','Spin','Jitter','Static'}, Default = 'Backward', Callback = function(v) AA.BodyYaw = v end })
    Group:AddSlider('AntiAim_BodyYawOff',     { Text = 'Body Yaw Offset',   Default = 0,  Min = -180, Max = 180, Rounding = 0,        Callback = function(v) AA.BodyYawOff = v end })
    Group:AddDropdown('AntiAim_BodyPitch',    { Text = 'Body Pitch',         Values = {'Down','Up','Zero','Custom'}, Default = 'Down', Callback = function(v) AA.BodyPitch = v end })
    Group:AddSlider('AntiAim_BodyPitchVal',   { Text = 'Body Pitch Value',  Default = 89, Min = 0,    Max = 89,  Rounding = 0,        Callback = function(v) AA.BodyPitchVal = v end })
    Group:AddSlider('AntiAim_BodyRoll',       { Text = 'Body Roll (Matrix)',Default = 0,  Min = -180, Max = 180, Rounding = 0, Tooltip = 'Tilts body sideways', Callback = function(v) AA.BodyRoll = v end })
    Group:AddDivider()
    Group:AddLabel('— Head —')
    Group:AddDropdown('AntiAim_HeadYaw',      { Text = 'Head Yaw',          Values = {'Opposite','Camera','Fake','Spin','Jitter','Static'}, Default = 'Opposite', Tooltip = 'Opposite = head faces camera | Fake = resolver bait', Callback = function(v) AA.HeadYaw = v end })
    Group:AddSlider('AntiAim_HeadYawOff',     { Text = 'Head Yaw Offset',   Default = 0,  Min = -180, Max = 180, Rounding = 0, Callback = function(v) AA.HeadYawOff = v end })
    Group:AddDropdown('AntiAim_HeadPitch',    { Text = 'Head Pitch',         Values = {'Up','Down','Zero','Custom'}, Default = 'Up', Callback = function(v) AA.HeadPitch = v end })
    Group:AddSlider('AntiAim_HeadPitchVal',   { Text = 'Head Pitch Value',  Default = 50, Min = 0,    Max = 89,  Rounding = 0, Callback = function(v) AA.HeadPitchVal = v end })
    Group:AddSlider('AntiAim_HeadRoll',       { Text = 'Head Roll',          Default = 0,  Min = -180, Max = 180, Rounding = 0, Callback = function(v) AA.HeadRoll = v end })
    Group:AddDivider()
    Group:AddLabel('— Desync —')
    Group:AddToggle('AntiAim_Desync',         { Text = 'Desync (Body Breaker)', Default = false, Tooltip = 'Snaps body L/R rapidly to break hitbox', Callback = function(v) AA.Desync = v end })
    Group:AddSlider('AntiAim_DesyncAmount',   { Text = 'Desync Amount',     Default = 58, Min = 1,    Max = 180, Rounding = 0, Callback = function(v) AA.DesyncAmount = v end })
    Group:AddSlider('AntiAim_DesyncRate',     { Text = 'Desync Rate (per sec)', Default = 5, Min = 1, Max = 30,  Rounding = 0, Callback = function(v) AA.DesyncRate = v end })
    Group:AddDivider()
    Group:AddLabel('— Spin / Jitter —')
    Group:AddSlider('AntiAim_SpinSpeed',      { Text = 'Spin Speed',         Default = 8,  Min = 1,    Max = 50,  Rounding = 0, Callback = function(v) AA.SpinSpeed = v end })
    Group:AddSlider('AntiAim_JitterRange',    { Text = 'Jitter Range',       Default = 90, Min = 1,    Max = 180, Rounding = 0, Callback = function(v) AA.JitterRange = v end })
end
setupAntiAim()

-- ══════════════════════════════════════════════════════════════════════════════
--  ALWAYS GROUNDED
-- ══════════════════════════════════════════════════════════════════════════════

local function setupGrounded()
    local GroundedGroup = Tabs.Misc:AddRightGroupbox('Grounded')

    local Grounded = {
        Enabled        = false,
        PlatformHeight = -3.2,
    }

    local groundedPlatform = nil

    GroundedGroup:AddToggle('Grounded_Enabled', {
        Text     = 'Always Grounded',
        Default  = false,
        Callback = function(v)
            Grounded.Enabled = v
            if not v and groundedPlatform then
                groundedPlatform:Destroy()
                groundedPlatform = nil
            end
        end,
    })
    GroundedGroup:AddSlider('Grounded_Height', {
        Text     = 'Platform Offset',
        Default  = -3.2,
        Min      = -5,
        Max      = -1,
        Rounding = 1,
        Callback = function(v) Grounded.PlatformHeight = v end,
    })

    RunService.Heartbeat:Connect(function()
        if not Grounded.Enabled then
            if groundedPlatform then groundedPlatform:Destroy(); groundedPlatform = nil end
            return
        end

        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not root then
            if groundedPlatform then groundedPlatform:Destroy(); groundedPlatform = nil end
            return
        end

        if not groundedPlatform then
            groundedPlatform             = Instance.new("Part")
            groundedPlatform.Name        = "AlwaysGroundedPlatform"
            groundedPlatform.Size        = Vector3.new(2, 0.1, 2)
            groundedPlatform.Anchored    = true
            groundedPlatform.CanCollide  = true
            groundedPlatform.Transparency = 1
            groundedPlatform.Parent      = workspace
        end

        groundedPlatform.CFrame = root.CFrame * CFrame.new(0, Grounded.PlatformHeight, 0)
    end)
end
setupGrounded()

-- ══════════════════════════════════════════════════════════════════════════════
--  AUTO FARM
--  OPTIMIZED: Heartbeat instead of RenderStepped (not visual)
-- ══════════════════════════════════════════════════════════════════════════════

local function setupFarmExtra()
    local FarmBox = Tabs.Misc:AddLeftGroupbox('Auto Farm')

    local AutoFarm = {
        Enabled       = false,
        Resource      = "stone",
        MaxDist       = 10,
        DelayTicks    = 0.5,
        TeleportStep  = 10,
        TeleportDelay = 0.3,
    }

    FarmBox:AddToggle('Farm_Enabled', {
        Text     = 'Auto Farm Enabled',
        Default  = false,
        Callback = function(v) AutoFarm.Enabled = v end,
    })
    FarmBox:AddDropdown('Farm_Resource', {
        Values   = { "stone", "iron", "sulfur" },
        Default  = "stone",
        Text     = 'Resource',
        Callback = function(v) AutoFarm.Resource = v end,
    })
    FarmBox:AddSlider('Farm_MaxDist', {
        Text     = 'Max Distance',
        Default  = 10,
        Min      = 1,
        Max      = 10,
        Rounding = 0,
        Callback = function(v) AutoFarm.MaxDist = v end,
    })
    FarmBox:AddSlider('Farm_Delay', {
        Text     = 'Hit Delay (sec)',
        Default  = 0.5,
        Min      = 0.1,
        Max      = 2,
        Rounding = 1,
        Tooltip  = 'Delay between hits in seconds',
        Callback = function(v) AutoFarm.DelayTicks = v end,
    })

    local lastFarmHit  = 0
    local lastTeleport = 0

    -- OPTIMIZED: Heartbeat — farm logic doesn't need render-frame precision
    RunService.Heartbeat:Connect(function()
        if not AutoFarm.Enabled then return end

        local char = LocalPlayer.Character
        if not char then return end

        local tool = char:FindFirstChild("Jackhammer")
        if not tool or not tool:IsA("Tool") then return end

        local oresFolder = workspace:FindFirstChild("ores")
        if not oresFolder then return end

        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end

        local targets = {}
        for _, obj in ipairs(oresFolder:GetChildren()) do
            if obj:IsA("MeshPart") and obj.Name == AutoFarm.Resource then
                table.insert(targets, obj)
            end
        end

        if #targets == 0 then return end

        table.sort(targets, function(a, b)
            return (a.Position - root.Position).Magnitude < (b.Position - root.Position).Magnitude
        end)

        local bestMesh = targets[1]
        local dist     = (bestMesh.Position - root.Position).Magnitude

        if dist <= AutoFarm.MaxDist then
            if tick() - lastFarmHit >= AutoFarm.DelayTicks then
                lastFarmHit = tick()
                local hitRemote = ReplicatedStorage:FindFirstChild("Tool")
                if hitRemote then hitRemote = hitRemote:FindFirstChild("Remotes") end
                if hitRemote then hitRemote = hitRemote:FindFirstChild("Hit") end
                if hitRemote then
                    pcall(function() hitRemote:FireServer(tool, bestMesh, bestMesh.Position) end)
                end
            end
        else
            if tick() - lastTeleport >= AutoFarm.TeleportDelay then
                local direction = (bestMesh.Position - root.Position).Unit
                local step      = math.max(0, math.min(AutoFarm.TeleportStep, dist - AutoFarm.MaxDist * 0.8))
                root.CFrame     = CFrame.new(root.Position + direction * step)
                lastTeleport    = tick()
            end
        end
    end)
end
setupFarmExtra()

-- ══════════════════════════════════════════════════════════════════════════════
--  COPTER FLY
-- ══════════════════════════════════════════════════════════════════════════════

local function setupLocalExtra()
    local FlyBox = Tabs.Misc:AddLeftGroupbox('Copter Fly')

    local FlyEnabled    = false
    local FlySpeed      = 256
    local flyConnection = nil

    local function StartZachFly()
        if flyConnection then flyConnection:Disconnect() end

        flyConnection = RunService.Heartbeat:Connect(function()
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if not root then return end

            local car = root:GetRootPart()
            if not car or car.Anchored then return end

            local isOwner = false
            pcall(function() isOwner = isnetworkowner(car) end)
            if not isOwner then return end

            local baseVel = Vector3.zero
            local cam     = workspace.CurrentCamera

            if not UserInputService:GetFocusedTextBox() then
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then baseVel = baseVel + cam.CFrame.LookVector  * FlySpeed end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then baseVel = baseVel - cam.CFrame.RightVector * FlySpeed end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then baseVel = baseVel - cam.CFrame.LookVector  * FlySpeed end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then baseVel = baseVel + cam.CFrame.RightVector * FlySpeed end
            end

            car.Velocity = baseVel + Vector3.new(0, 2, 0)

            if car ~= root then
                car.RotVelocity = Vector3.zero
                car.CFrame      = CFrame.new(car.Position, car.Position + cam.CFrame.LookVector)
            end
        end)
    end

    local function StopZachFly()
        if flyConnection then
            flyConnection:Disconnect()
            flyConnection = nil
        end
    end

    FlyBox:AddToggle('CopterFly_Enabled', {
        Text     = 'Copter Fly Enabled',
        Default  = false,
        Callback = function(v)
            FlyEnabled = v
            if FlyEnabled then StartZachFly() else StopZachFly() end
        end,
    })
    FlyBox:AddSlider('Fly_Speed', {
        Text     = 'Fly Speed',
        Default  = 256,
        Min      = 100,
        Max      = 1000,
        Rounding = 0,
        Callback = function(v) FlySpeed = v end,
    })
    FlyBox:AddLabel('Fly Key'):AddKeyPicker('CopterFly_Key', {
        Default = 'V',
        NoUI    = false,
        Text    = 'Fly Key',
    })

    KeybindSystem:Register(
        "Copter Fly",
        function() return Options.CopterFly_Key and Options.CopterFly_Key.Value end,
        Toggles.CopterFly_Enabled,
        "Toggle"
    )

    LocalPlayer.CharacterAdded:Connect(function()
        if FlyEnabled then
            task.wait(0.3)
            StartZachFly()
        end
    end)
end
setupLocalExtra()

-- ══════════════════════════════════════════════════════════════════════════════
--  REMOVE SPIKES
-- ══════════════════════════════════════════════════════════════════════════════

local function setupRemoveSpikes()
    local RemoveSpikesSection = Tabs.Misc:AddLeftGroupbox('Remove Spikes')
    local removeSpikesEnabled = false
    local spikesConn          = nil

    local function removeAllSpikes()
        task.spawn(function()
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj.Name == "Spikes" then
                    pcall(function() obj:Destroy() end)
                end
            end
        end)
    end

    RemoveSpikesSection:AddToggle('Misc_RemoveSpikes', {
        Text    = 'Remove Spikes',
        Default = false,
        Tooltip = 'Destroy all spikes on the map',
        Callback = function(v)
            removeSpikesEnabled = v
            if v then
                removeAllSpikes()
                if not spikesConn then
                    spikesConn = workspace.DescendantAdded:Connect(function(obj)
                        if removeSpikesEnabled and obj.Name == "Spikes" then
                            pcall(function() obj:Destroy() end)
                        end
                    end)
                end
            else
                if spikesConn then
                    spikesConn:Disconnect()
                    spikesConn = nil
                end
            end
        end,
    })
end
setupRemoveSpikes()

-- ══════════════════════════════════════════════════════════════════════════════
--  SPIDER CLIMB
-- ══════════════════════════════════════════════════════════════════════════════

local function setupSpiderClimb()
    local SpiderSection = Tabs.Misc:AddLeftGroupbox('Spider Climb')

    local SpiderSettings = {
        Enabled = false,
        Speed   = 50,
    }

    local spiderConnection  = nil
    local spiderRayParams   = RaycastParams.new()
    spiderRayParams.FilterType   = Enum.RaycastFilterType.Exclude
    spiderRayParams.IgnoreWater  = true

    local function stopSpiderConnection()
        if spiderConnection then
            spiderConnection:Disconnect()
            spiderConnection = nil
        end
    end

    local function startSpiderConnection()
        stopSpiderConnection()

        spiderConnection = RunService.Heartbeat:Connect(function()
            if not SpiderSettings.Enabled then return end

            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if not root then return end

            if not UserInputService:IsKeyDown(Enum.KeyCode.W) then return end

            local cam         = workspace.CurrentCamera
            local forward     = cam.CFrame.LookVector
            spiderRayParams.FilterDescendantsInstances = { char }
            local result = workspace:Raycast(root.Position, forward * 3, spiderRayParams)

            if result then
                local normal = result.Normal
                if math.abs(normal.Y) < 0.3 then
                    root.AssemblyLinearVelocity = Vector3.new(
                        root.AssemblyLinearVelocity.X,
                        SpiderSettings.Speed,
                        root.AssemblyLinearVelocity.Z
                    )
                end
            end
        end)
    end

    SpiderSection:AddToggle('Misc_SpiderClimb', {
        Text     = 'Spider Climb',
        Default  = false,
        Callback = function(v)
            SpiderSettings.Enabled = v
            if v then startSpiderConnection() else stopSpiderConnection() end
        end,
    })
    SpiderSection:AddSlider('Misc_SpiderSpeed', {
        Text     = 'Climb Speed',
        Rounding = 0,
        Default  = 50,
        Min      = 20,
        Max      = 150,
        Callback = function(v) SpiderSettings.Speed = v end,
    })
    SpiderSection:AddLabel('Spider Bind'):AddKeyPicker('Spider_Key', {
        Default = 'T',
        NoUI    = false,
        Text    = 'Spider Bind',
    })

    KeybindSystem:Register(
        "Spider Climb",
        function() return Options.Spider_Key and Options.Spider_Key.Value end,
        Toggles.Misc_SpiderClimb,
        "Toggle"
    )

    if Toggles.Misc_SpiderClimb and Toggles.Misc_SpiderClimb.Value then
        SpiderSettings.Enabled = true
        startSpiderConnection()
    end
end
setupSpiderClimb()

-- ══════════════════════════════════════════════════════════════════════════════
--  HITBOX EXPANDER
--  OPTIMIZED: Heartbeat at 20×/sec
-- ══════════════════════════════════════════════════════════════════════════════

local function setupHitboxExpander()
    local HitboxExpanderSection = Tabs.Combat:AddLeftGroupbox('Hitbox Expander')

    local HBE = {
        Enabled     = false,
        TargetPart  = "Both",
        SizeX       = 10,
        SizeY       = 10,
        Transparency = 0.5,
        Color       = Color3.fromRGB(255, 255, 255),
        origData    = {},
    }

    HitboxExpanderSection:AddToggle('Combat_HitboxExpander', {
        Text     = 'Hitbox Expander',
        Default  = false,
        Callback = function(v)
            HBE.Enabled = v
            if not v then
                for p, dat in pairs(HBE.origData) do
                    if p and p.Parent then
                        p.Size         = dat.Size
                        p.Transparency = dat.Transparency
                        p.Color        = dat.Color
                        pcall(function() p.Material = dat.Material end)
                    end
                end
                table.clear(HBE.origData)
            end
        end,
    })
    HitboxExpanderSection:AddDropdown('HBE_TargetPart', {
        Values   = { "Head", "Torso", "Both" },
        Default  = "Both",
        Multi    = false,
        Text     = 'Target Part',
        Callback = function(v) HBE.TargetPart = v end,
    })
    HitboxExpanderSection:AddSlider('HBE_SizeX', {
        Text     = 'Size X',
        Rounding = 0,
        Default  = 10,
        Min      = 1,
        Max      = 15,
        Callback = function(v) HBE.SizeX = v end,
    })
    HitboxExpanderSection:AddSlider('HBE_SizeY', {
        Text     = 'Size Y',
        Rounding = 0,
        Default  = 10,
        Min      = 1,
        Max      = 15,
        Callback = function(v) HBE.SizeY = v end,
    })
    HitboxExpanderSection:AddSlider('HBE_Transparency', {
        Text     = 'Transparency',
        Default  = 0.5,
        Min      = 0,
        Max      = 1,
        Rounding = 2,
        Callback = function(v) HBE.Transparency = v end,
    })
    HitboxExpanderSection:AddLabel('Hitbox Color'):AddColorPicker('HBE_Color', {
        Default  = HBE.Color,
        Title    = 'Hitbox Color',
        Callback = function(c) HBE.Color = c end,
    })

    -- OPTIMIZED: throttle to 20×/sec
    local lastHBEUpdate = 0
    RunService.Heartbeat:Connect(function()
        if not HBE.Enabled then return end
        if tick() - lastHBEUpdate < 0.05 then return end
        lastHBEUpdate = tick()

        local folder = workspace:FindFirstChild("Characters")
        if not folder then return end

        for _, model in ipairs(folder:GetChildren()) do
            if not model:IsA("Model") or model == LocalPlayer.Character then continue end

            local function expandPart(partName)
                local p = model:FindFirstChild(partName)
                if not p or not p:IsA("BasePart") then return end
                if not HBE.origData[p] then
                    HBE.origData[p] = {
                        Size         = p.Size,
                        Material     = p.Material,
                        Color        = p.Color,
                        Transparency = p.Transparency,
                    }
                end
                p.Size = Vector3.new(
                    math.max(HBE.origData[p].Size.X, HBE.SizeX),
                    math.max(HBE.origData[p].Size.Y, HBE.SizeY),
                    math.max(HBE.origData[p].Size.Z, HBE.SizeX)
                )
                p.Transparency = HBE.Transparency
                p.Color        = HBE.Color
                p.Material     = Enum.Material.ForceField
            end

            local target = HBE.TargetPart
            if target == "Head"  or target == "Both" then expandPart("HeadHitbox")  end
            if target == "Torso" or target == "Both" then expandPart("TorsoHitbox") end
        end
    end)
end
setupHitboxExpander()

-- ══════════════════════════════════════════════════════════════════════════════
--  X-RAY
-- ══════════════════════════════════════════════════════════════════════════════

local function setupXRay()
    local XRaySection = Tabs.Visuals:AddRightGroupbox('X-Ray')

    local XRaySettings = {
        Enabled        = false,
        Transparency   = 0.5,
        WhitelistNames = {
            "TwigWall","SoloTwigFrame","TrigTwigRoof",
            "TwigFrame","TwigWindow","TwigRoof",
        },
    }

    local xrayOriginalTransparencies = {}
    local xrayConn                   = nil

    local function isXRayTarget(obj)
        if not (obj:IsA("BasePart") or obj:IsA("MeshPart") or obj:IsA("UnionOperation")) then return false end
        for _, name in ipairs(XRaySettings.WhitelistNames) do
            if obj.Name == name then return true end
        end
        return false
    end

    local function applyXRayToObject(obj)
        if xrayOriginalTransparencies[obj] ~= nil then return end
        if not isXRayTarget(obj) then return end
        xrayOriginalTransparencies[obj] = obj.Transparency
        obj.Transparency = XRaySettings.Transparency
    end

    local function restoreAllXRay()
        for obj, orig in pairs(xrayOriginalTransparencies) do
            if obj and obj:IsDescendantOf(workspace) then
                obj.Transparency = orig
            end
        end
        table.clear(xrayOriginalTransparencies)
    end

    local function enableXRay()
        for _, obj in ipairs(workspace:GetDescendants()) do
            applyXRayToObject(obj)
        end
        if not xrayConn then
            xrayConn = workspace.DescendantAdded:Connect(function(obj)
                if XRaySettings.Enabled then
                    task.defer(applyXRayToObject, obj)
                end
            end)
        end
    end

    local function disableXRay()
        restoreAllXRay()
        if xrayConn then
            xrayConn:Disconnect()
            xrayConn = nil
        end
    end

    XRaySection:AddToggle('XRay_Enabled', {
        Text     = 'X-Ray',
        Default  = false,
        Callback = function(v)
            XRaySettings.Enabled = v
            if v then enableXRay() else disableXRay() end
        end,
    })
    XRaySection:AddSlider('XRay_Transparency', {
        Text     = 'Transparency',
        Default  = 0.5,
        Min      = 0,
        Max      = 1,
        Rounding = 2,
        Callback = function(v)
            XRaySettings.Transparency = v
            for obj in pairs(xrayOriginalTransparencies) do
                if obj and obj:IsDescendantOf(workspace) then
                    obj.Transparency = v
                end
            end
        end,
    })
    XRaySection:AddLabel('X-Ray Bind'):AddKeyPicker('XRay_Key', {
        Default = 'X',
        NoUI    = false,
        Text    = 'X-Ray Bind',
    })

    KeybindSystem:Register(
        "X-Ray",
        function() return Options.XRay_Key and Options.XRay_Key.Value end,
        Toggles.XRay_Enabled,
        "Toggle"
    )
end
setupXRay()

-- ══════════════════════════════════════════════════════════════════════════════
--  NO JUMP DELAY
-- ══════════════════════════════════════════════════════════════════════════════

local function setupNoJumpDelay()
    local LocalSection        = Tabs.Misc:AddLeftGroupbox('No Jump Delay')
    local noJumpDelayConn     = nil
    local lastJumpTime        = 0
    local JUMP_DELAY_INTERVAL = 0.1

    LocalSection:AddToggle('Misc_NoJumpDelay', {
        Text     = 'No Jump Delay',
        Default  = false,
        Callback = function(v)
            if noJumpDelayConn then noJumpDelayConn:Disconnect(); noJumpDelayConn = nil end

            if v then
                noJumpDelayConn = RunService.RenderStepped:Connect(function()
                    local char = LocalPlayer.Character
                    local hum  = char and char:FindFirstChildOfClass("Humanoid")
                    if not hum or hum.Health <= 0 then return end

                    if UserInputService:IsKeyDown(Enum.KeyCode.Space)
                        and hum.FloorMaterial ~= Enum.Material.Air then
                        local now = tick()
                        if now - lastJumpTime >= JUMP_DELAY_INTERVAL then
                            hum.Jump = true
                            hum:ChangeState(Enum.HumanoidStateType.Jumping)
                            lastJumpTime = now
                        end
                    end
                end)
            end
        end,
    })
end
setupNoJumpDelay()

-- ══════════════════════════════════════════════════════════════════════════════
--  VIEWMODEL CHANGER
-- ══════════════════════════════════════════════════════════════════════════════

local function setupViewmodelChanger()
    local VMGroup = Tabs.Visuals:AddLeftGroupbox('Viewmodel Changer')

    local vmPosX, vmPosY, vmPosZ = 0, 0, 0
    local vmEnabled               = false

    local success, ViewModelModule = pcall(function()
        return require(ReplicatedStorage.ViewModel.Scripts.ViewModel)
    end)

    if success and ViewModelModule then
        local oldUpdate = ViewModelModule.updateCFrame
        ViewModelModule.updateCFrame = function(self, smooth, dt)
            oldUpdate(self, smooth, dt)
            if not self.viewModel or not vmEnabled then return end
            local pos = CFrame.new(vmPosX, vmPosY, vmPosZ)
            self.viewModel:PivotTo(self.viewModel:GetPivot() * pos)
        end
    end

    VMGroup:AddToggle('Vis_VM_Enabled', {
        Text     = 'Custom Viewmodel',
        Default  = false,
        Tooltip  = 'Enable custom position',
        Callback = function(v) vmEnabled = v end,
    })
    VMGroup:AddSlider('Vis_VM_PosX', { Text = 'Pos X', Default = 0, Min = -5, Max = 5, Rounding = 2, Suffix = ' studs', Callback = function(v) vmPosX = v end })
    VMGroup:AddSlider('Vis_VM_PosY', { Text = 'Pos Y', Default = 0, Min = -5, Max = 5, Rounding = 2, Suffix = ' studs', Callback = function(v) vmPosY = v end })
    VMGroup:AddSlider('Vis_VM_PosZ', { Text = 'Pos Z', Default = 0, Min = -5, Max = 5, Rounding = 2, Suffix = ' studs', Callback = function(v) vmPosZ = v end })
end
setupViewmodelChanger()

-- ══════════════════════════════════════════════════════════════════════════════
--  CROSSHAIR HIDER
--  OPTIMIZED: Heartbeat at 2×/sec
-- ══════════════════════════════════════════════════════════════════════════════

local function setupCrosshairHider()
    local CrosshairHiderGroup = Tabs.Visuals:AddLeftGroupbox('Crosshair Hider')
    local hideCrosshairEnabled = false
    local lastHideTime         = 0

    CrosshairHiderGroup:AddToggle('Vis_HideCrosshair', {
        Text     = 'Hide Crosshair',
        Default  = false,
        Tooltip  = 'Continuously hides the game crosshair',
        Callback = function(v) hideCrosshairEnabled = v end,
    })

    -- OPTIMIZED: Heartbeat at 2×/sec (was RenderStepped at 60+)
    RunService.Heartbeat:Connect(function()
        if not hideCrosshairEnabled then return end
        if tick() - lastHideTime < 0.5 then return end
        lastHideTime = tick()

        local playerGui = LocalPlayer:FindFirstChild('PlayerGui')
        if not playerGui then return end
        local crosshairGui = playerGui:FindFirstChild('Crosshair')
        if not crosshairGui then return end
        local crosshairObjects = crosshairGui:FindFirstChild('CrosshairObjects')
        if not crosshairObjects then return end

        local ok, objectsModule = pcall(require, crosshairObjects)
        if not ok or not objectsModule then return end
        for _, obj in pairs(objectsModule) do
            pcall(function() obj:hide() end)
        end
    end)
end
setupCrosshairHider()

-- ══════════════════════════════════════════════════════════════════════════════
--  CUSTOM CROSSHAIR
-- ══════════════════════════════════════════════════════════════════════════════

local function setupCustomCrosshair()
    local CrossGroup = Tabs.Visuals:AddLeftGroupbox('Custom Crosshair')

    local old = CoreGui:FindFirstChild("ScytheCrosshair")
    if old then old:Destroy() end

    local CrossGui = Instance.new("ScreenGui")
    CrossGui.Name          = "ScytheCrosshair"
    CrossGui.IgnoreGuiInset = true
    CrossGui.Parent        = CoreGui

    local CrossHolder = Instance.new("Frame")
    CrossHolder.AnchorPoint          = Vector2.new(0.5, 0.5)
    CrossHolder.Position             = UDim2.new(0.5, 0, 0.5, 0)
    CrossHolder.Size                 = UDim2.new(0, 0, 0, 0)
    CrossHolder.BackgroundTransparency = 1
    CrossHolder.Parent               = CrossGui

    local lineNames   = { "Top", "Bottom", "Left", "Right" }
    local lineAnchors = {
        Vector2.new(0.5, 1), Vector2.new(0.5, 0),
        Vector2.new(1, 0.5), Vector2.new(0, 0.5),
    }
    local crossFrames = {}

    for i, name in ipairs(lineNames) do
        local frame = Instance.new("Frame")
        frame.Name            = name
        frame.AnchorPoint     = lineAnchors[i]
        frame.BorderSizePixel = 0
        frame.BackgroundColor3 = Color3.new(1, 1, 1)
        frame.Parent          = CrossHolder
        crossFrames[name]     = frame
    end

    local CrossText = Instance.new("TextLabel")
    CrossText.Name                 = "Text"
    CrossText.AnchorPoint          = Vector2.new(0.5, 0)
    CrossText.Position             = UDim2.new(0.5, 0, 0.5, 30)
    CrossText.Size                 = UDim2.new(0, 200, 0, 20)
    CrossText.BackgroundTransparency = 1
    CrossText.Font                 = Enum.Font.SourceSansBold
    CrossText.TextSize             = 14
    CrossText.TextColor3           = Color3.new(1, 1, 1)
    CrossText.Text                 = "Scythe private"
    CrossText.Parent               = CrossGui

    -- State variables (all local — avoids global table lookup in hot path)
    local crossEnabled   = false
    local crossSpin      = false
    local crossSpinSpeed = 10
    local crossLength    = 20
    local crossWidth     = 2
    local crossGap       = 8
    local textShow       = true
    local pulseAmp       = 8
    local pulseSpeed     = 4

    local function updateVisibility()
        CrossHolder.Visible = crossEnabled
        CrossText.Visible   = crossEnabled and textShow
    end

    local function applyLengths(baseLen)
        local topLen = math.max(0, baseLen)
        crossFrames["Top"].Size    = UDim2.new(0, crossWidth, 0, topLen)
        crossFrames["Bottom"].Size = UDim2.new(0, crossWidth, 0, topLen)
        crossFrames["Left"].Size   = UDim2.new(0, topLen, 0, crossWidth)
        crossFrames["Right"].Size  = UDim2.new(0, topLen, 0, crossWidth)
    end

    local function applyGap()
        crossFrames["Top"].Position    = UDim2.new(0.5, 0, 0.5, -crossGap)
        crossFrames["Bottom"].Position = UDim2.new(0.5, 0, 0.5,  crossGap)
        crossFrames["Left"].Position   = UDim2.new(0.5, -crossGap, 0.5, 0)
        crossFrames["Right"].Position  = UDim2.new(0.5,  crossGap, 0.5, 0)
    end

    -- OPTIMIZED: early return when crosshair is disabled
    RunService.RenderStepped:Connect(function(dt)
        if not crossEnabled then return end

        if crossSpin then
            CrossHolder.Rotation = CrossHolder.Rotation + crossSpinSpeed * dt * 60
        else
            CrossHolder.Rotation = 0
        end

        local pulse      = math.sin(tick() * pulseSpeed) * pulseAmp
        local currentLen = math.max(1, crossLength + pulse)
        applyLengths(currentLen)
    end)

    CrossGroup:AddToggle('Vis_Cross_Enabled',    { Text = 'Enable',          Default = false, Callback = function(v) crossEnabled = v; updateVisibility() end })
    CrossGroup:AddToggle('Vis_Cross_Spin',       { Text = 'Spin',            Default = false, Callback = function(v) crossSpin = v end })
    CrossGroup:AddSlider('Vis_Cross_SpinSpeed',  { Text = 'Spin Speed',      Default = 10,  Min = 1,   Max = 100, Rounding = 0, Callback = function(v) crossSpinSpeed = v end })
    CrossGroup:AddSlider('Vis_Cross_Length',     { Text = 'Length',          Default = 20,  Min = 5,   Max = 100, Rounding = 0, Suffix = 'px', Callback = function(v) crossLength = v end })
    CrossGroup:AddSlider('Vis_Cross_Width',      { Text = 'Width',           Default = 2,   Min = 1,   Max = 10,  Rounding = 0, Suffix = 'px', Callback = function(v) crossWidth = v end })
    CrossGroup:AddSlider('Vis_Cross_Gap',        { Text = 'Gap',             Default = 8,   Min = 0,   Max = 40,  Rounding = 0, Suffix = 'px', Callback = function(v) crossGap = v; applyGap() end })
    CrossGroup:AddSlider('Vis_Cross_PulseAmp',   { Text = 'Pulse Amplitude', Default = 8,   Min = 0,   Max = 30,  Rounding = 0, Suffix = 'px', Callback = function(v) pulseAmp = v end })
    CrossGroup:AddSlider('Vis_Cross_PulseSpeed', { Text = 'Pulse Speed',     Default = 4,   Min = 0.5, Max = 20,  Rounding = 1, Callback = function(v) pulseSpeed = v end })
    CrossGroup:AddLabel('Line Color'):AddColorPicker('Vis_Cross_Color', {
        Default  = Color3.new(1, 1, 1),
        Title    = 'Crosshair Color',
        Callback = function(v)
            for _, frame in pairs(crossFrames) do frame.BackgroundColor3 = v end
        end,
    })
    CrossGroup:AddToggle('Vis_Cross_TextShow', { Text = 'Show Text', Default = true, Callback = function(v) textShow = v; updateVisibility() end })
    CrossGroup:AddLabel('Text Color'):AddColorPicker('Vis_Cross_TextColor', {
        Default  = Color3.new(1, 1, 1),
        Title    = 'Text Color',
        Callback = function(v) CrossText.TextColor3 = v end,
    })

    applyGap()
    applyLengths(crossLength)
    CrossHolder.Visible = false
    updateVisibility()
end
setupCustomCrosshair()

-- ══════════════════════════════════════════════════════════════════════════════
--  __NAMECALL HOOK  (Bullet Trace + Silent Aim redirect)
--  NOTE: this fires on every workspace:Raycast call in the game.
--        Keep the body as cheap as possible.
-- ══════════════════════════════════════════════════════════════════════════════

-- ══════════════════════════════════════════════════════════════════════════════
--  __NAMECALL HOOK  (Bullet Trace + Silent Aim redirect)
-- ══════════════════════════════════════════════════════════════════════════════

-- ══════════════════════════════════════════════════════════════════════════════
--  __NAMECALL HOOK  (Bullet Trace + Silent Aim redirect)
-- ══════════════════════════════════════════════════════════════════════════════

local oldNamecall
local lastTraceTime = 0 -- Переменная для микро-кулдауна (защита от двойных трейсов)

oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local method = getnamecallmethod()

    if method ~= "Raycast" or self ~= workspace or checkcaller() then
        return oldNamecall(self, ...)
    end

    local args      = { ... }
    local origin    = args[1]
    local direction = args[2]
    local rayParams = args[3]

    if typeof(origin) ~= "Vector3" or typeof(direction) ~= "Vector3" then
        return oldNamecall(self, ...)
    end

    -- [1] Подмена направления для Silent Aim
    local isSilentAiming = false
    if type(SilentAim) == "table" and SilentAim.Enabled and CurrentAimPoint then
        local diff = CurrentAimPoint - origin
        if diff.Magnitude > 0 then
            direction = diff.Unit * direction.Magnitude
            args[2] = direction 
            isSilentAiming = true
        end
    end

    -- [2] Выполняем оригинальный рейкаст 
    local result = oldNamecall(self, unpack(args))

    -- [3] Строгий фильтр выстрелов
    local isBulletRay = false
    local mag = direction.Magnitude

    -- Отсекаем короткие рейкасты (спред, физика и т.д.)
    if mag > 20 then
        -- Ищем ТОЛЬКО те рейкасты, которые на 100% исходят от оружия игрока
        if rayParams and typeof(rayParams) == "RaycastParams" and rayParams.FilterType == Enum.RaycastFilterType.Exclude then
            for _, v in ipairs(rayParams.FilterDescendantsInstances or {}) do
                if v == LocalPlayer.Character then
                    isBulletRay = true
                    break
                end
            end
        end
        -- Запасной вариант (mag > 100) УДАЛЕН, так как именно он создавал второй (длинный) трейсер от визуала пули
    end

    -- [4] Рисуем Bullet Trace
    if type(BulletTrace) == "table" and BulletTrace.Enabled and CreateBulletTrace and isBulletRay then
        -- КУЛДАУН: Не больше 1 трейсера каждые 0.05 секунд (решает проблему дублей на 100%)
        if tick() - lastTraceTime > 0.05 then
            lastTraceTime = tick()
            
            pcall(function()
                if isSilentAiming and CurrentAimPoint then
                    CreateBulletTrace(origin, CurrentAimPoint)
                elseif result and typeof(result) == "table" and result.Position and typeof(result.Position) == "Vector3" then
                    CreateBulletTrace(origin, result.Position)
                else
                    CreateBulletTrace(origin, origin + direction)
                end
            end)
        end
    end

    return result
end))

-- ══════════════════════════════════════════════════════════════════════════════
--  SKYBOX
-- ══════════════════════════════════════════════════════════════════════════════

local function setupSkybox()
    local SkyboxSection = Tabs.World:AddRightGroupbox('Skybox')

    local Skyboxes = {
        ["Nebula Black"]  = { Bk="171410628",    Dn="171410649",    Ft="171410620",    Lf="171410666",    Rt="171410657",    Up="171410636"    },
        ["Nebula Orange"] = { Bk="171560994",    Dn="171561019",    Ft="171560968",    Lf="171561065",    Rt="171561026",    Up="171561009"    },
        ["Purple Space"]  = { Bk="159454299",    Dn="159454296",    Ft="159454293",    Lf="159454286",    Rt="159454300",    Up="159454288"    },
        ["Weird"]         = { Bk="6823346883",   Dn="6823346883",   Ft="6823346883",   Lf="6823346883",   Rt="6823346883",   Up="6823346883"   },
        ["Rainbow"]       = { Bk="16573631102",  Dn="16573631950",  Ft="16573632795",  Lf="16573633258",  Rt="16573633908",  Up="16573634370"  },
        ["Aurora"]        = { Bk="340908398",    Dn="340908450",    Ft="340908468",    Lf="340908504",    Rt="340908530",    Up="340908586"    },
    }

    local SkyboxNames = {}
    for name in pairs(Skyboxes) do table.insert(SkyboxNames, name) end
    table.sort(SkyboxNames)

    local function ApplySkybox(data)
        pcall(function()
            local lighting = game:GetService("Lighting")
            local sky      = lighting:FindFirstChildOfClass("Sky")
            if not sky then
                sky = Instance.new("Sky")
                sky.Parent = lighting
            end
            for side, id in pairs(data) do
                sky["Skybox" .. side] = "rbxassetid://" .. id
            end
        end)
    end

    SkyboxSection:AddDropdown('World_Skybox', {
        Values   = SkyboxNames,
        Default  = "Nebula Black",
        Multi    = false,
        Text     = 'Skybox',
        Tooltip  = 'Select a skybox',
        Callback = function(value)
            if Skyboxes[value] then ApplySkybox(Skyboxes[value]) end
        end,
    })
end
setupSkybox()

-- ══════════════════════════════════════════════════════════════════════════════
--  VISUAL TWEAKS
-- ══════════════════════════════════════════════════════════════════════════════

local function setupVisualTweaks()
    local VisualSection = Tabs.World:AddLeftGroupbox('Visual Tweaks')

    VisualSection:AddToggle('World_NoShadows', {
        Text     = 'No Shadows',
        Default  = false,
        Tooltip  = 'Disable global shadows',
        Callback = function(state)
            pcall(function() Lighting.GlobalShadows = not state end)
        end,
    })

    local dayConnection = nil
    VisualSection:AddToggle('World_AlwaysDay', {
        Text     = 'Always Day',
        Default  = false,
        Tooltip  = 'Keep lighting at daytime',
        Callback = function(state)
            if state then
                if dayConnection then dayConnection:Disconnect() end
                dayConnection = RunService.Heartbeat:Connect(function()
                    pcall(function() Lighting.ClockTime = 11 end)
                end)
            else
                if dayConnection then
                    dayConnection:Disconnect()
                    dayConnection = nil
                end
            end
        end,
    })

    local atmosphereBackup = Lighting:FindFirstChildOfClass("Atmosphere")
    VisualSection:AddToggle('World_NoAtmosphere', {
        Text     = 'No Atmosphere',
        Default  = false,
        Tooltip  = 'Remove atmosphere effects',
        Callback = function(state)
            pcall(function()
                if state then
                    local atm = Lighting:FindFirstChildOfClass("Atmosphere")
                    if atm then atm:Destroy() end
                else
                    if atmosphereBackup and not Lighting:FindFirstChildOfClass("Atmosphere") then
                        atmosphereBackup:Clone().Parent = Lighting
                    end
                end
            end)
        end,
    })

    VisualSection:AddToggle('World_NoClouds', {
        Text     = 'No Clouds',
        Default  = false,
        Tooltip  = 'Disable clouds',
        Callback = function(state)
            pcall(function()
                local terrain = workspace:FindFirstChildOfClass("Terrain")
                if terrain then
                    local clouds = terrain:FindFirstChildOfClass("Clouds")
                    if clouds then clouds.Enabled = not state end
                end
            end)
        end,
    })
end
setupVisualTweaks()

-- ══════════════════════════════════════════════════════════════════════════════
--  TERRAIN
-- ══════════════════════════════════════════════════════════════════════════════

local function setupTerrain()
    local WorldSection = Tabs.World:AddLeftGroupbox('Terrain')
    local TerrainObj   = workspace.Terrain

    WorldSection:AddToggle('World_Grass', {
        Text     = 'Grass',
        Default  = true,
        Tooltip  = 'Enable/Disable grass decoration',
        Callback = function(state)
            pcall(function()
                if sethiddenproperty then
                    sethiddenproperty(TerrainObj, "Decoration", state)
                end
            end)
        end,
    })
end
setupTerrain()

-- ══════════════════════════════════════════════════════════════════════════════
--  REMOVE LEAVES
-- ══════════════════════════════════════════════════════════════════════════════

local function setupFoliage()
    local FoliageSection   = Tabs.World:AddLeftGroupbox('Trees')
    local removeLeavesEnabled = false
    local leavesConn          = nil

    local function processTree(model)
        if not removeLeavesEnabled then return end
        if model.Name == "elka" then
            local leafs = model:FindFirstChild("Leafs")
            if leafs then leafs:Destroy() end
        elseif model.Name == "tree" then
            local leavesTop = model:FindFirstChild("LeavesTop")
            if leavesTop and leavesTop:IsA("BasePart") then
                leavesTop.Transparency = 1
            end
        end
    end

    local function scanExisting()
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and (obj.Name == "elka" or obj.Name == "tree") then
                processTree(obj)
            end
        end
    end

    FoliageSection:AddToggle('World_RemoveLeaves', {
        Text     = 'Remove Leaves',
        Default  = false,
        Tooltip  = 'Toggle removal of tree leaves',
        Callback = function(state)
            removeLeavesEnabled = state
            if state then
                scanExisting()
                if not leavesConn then
                    leavesConn = workspace.DescendantAdded:Connect(function(obj)
                        if obj:IsA("Model") and (obj.Name == "elka" or obj.Name == "tree") then
                            task.defer(processTree, obj)
                        end
                    end)
                end
            else
                if leavesConn then
                    leavesConn:Disconnect()
                    leavesConn = nil
                end
            end
        end,
    })
end
setupFoliage()

-- ══════════════════════════════════════════════════════════════════════════════
--  INSTANT EOKA
-- ══════════════════════════════════════════════════════════════════════════════

local function setupInstantEoka()
    local EokaSection = Tabs.Combat:AddRightGroupbox('Eoka')

    EokaSection:AddToggle('Combat_InstantEoka', {
        Text    = 'Instant Eoka',
        Default = false,
        Tooltip = 'Removes Eoka spark delay',
        Callback = function(state)
            if not state then return end

            pcall(function()
                local guns = ReplicatedStorage:FindFirstChild("Guns")
                if guns and guns:FindFirstChild("EokaFolder") then
                    local eokaScripts = guns.EokaFolder:FindFirstChild("Scripts")
                    if eokaScripts then
                        local eokaClient = eokaScripts:FindFirstChild("EokaClient")
                        if eokaClient then
                            local mod = require(eokaClient)
                            if mod then
                                if mod.startFiring then
                                    mod.startFiring = function(self, ...)
                                        if self.CurrentAmmo and self.CurrentAmmo > 0 and not self.FiringOnCooldown then
                                            self.SparkWait    = 0
                                            self.IsSparking   = false
                                        end
                                    end
                                end
                                if mod.new then
                                    local oldNew = mod.new
                                    mod.new = function(...)
                                        local obj = oldNew(...)
                                        obj.BaseBulletSpread = 0
                                        return obj
                                    end
                                end
                            end
                        end
                    end
                end
            end)

            local char = LocalPlayer.Character
            if char then
                for _, tool in ipairs(char:GetChildren()) do
                    if tool:IsA("Tool") and tool.Name:lower():find("eoka") then
                        pcall(function()
                            if tool:FindFirstChild("Scripts") then
                                local mod = require(
                                    tool.Scripts:FindFirstChild("EokaClient")
                                    or tool.Scripts:FindFirstChild("GunClient")
                                )
                                if mod and mod.SparkWait    then mod.SparkWait    = 0 end
                                if mod and mod.BaseBulletSpread then mod.BaseBulletSpread = 0 end
                            end
                        end)
                    end
                end
            end
        end,
    })
end
setupInstantEoka()

-- ══════════════════════════════════════════════════════════════════════════════
--  SPEEDHACK + THIRDPERSON
-- ══════════════════════════════════════════════════════════════════════════════

local function setupMovement()
    local SpeedBox = Tabs.Misc:AddLeftGroupbox('SpeedHack')
    local TPBox    = Tabs.Misc:AddRightGroupbox('ThirdPerson')

    -- SpeedHack state
    local speedEnabled = false
    local speedConn    = nil
    local noClipParts  = {}
    local lastNetCheck = 0
    local currentSpeed = 0

    local function calcMoveDir()
        local dir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + Vector3.new(0, 0, -1) end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir + Vector3.new(0, 0,  1) end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir + Vector3.new(-1, 0, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + Vector3.new( 1, 0, 0) end
        return dir.Magnitude > 0 and dir.Unit or Vector3.zero
    end

    local function setupNetwork()
        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not root then return end
        pcall(function() root:SetNetworkOwner(nil) end)
        lastNetCheck = tick()
    end

    local function enableNoClip()
        local char = LocalPlayer.Character
        if not char then return end
        for _, p in pairs(char:GetDescendants()) do
            if p:IsA("BasePart") then
                noClipParts[p] = p.CanCollide
                p.CanCollide   = false
            end
        end
    end

    local function disableNoClip()
        for p, orig in pairs(noClipParts) do
            if p and p.Parent then p.CanCollide = orig end
        end
        noClipParts = {}
    end

    local function enableSpeedHack()
        if speedEnabled then return end
        local char = LocalPlayer.Character
        if not char then return end
        local hum  = char:FindFirstChild("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if not hum or not root then return end

        setupNetwork()
        enableNoClip()
        speedEnabled = true
        currentSpeed = 0

        speedConn = RunService.Heartbeat:Connect(function(dt)
            if not speedEnabled then return end
            local c = LocalPlayer.Character
            if not c then return end
            local r = c:FindFirstChild("HumanoidRootPart")
            local h = c:FindFirstChild("Humanoid")
            if not r or not h then return end

            if tick() - lastNetCheck > 2 then setupNetwork() end

            local moveDir     = calcMoveDir()
            local targetSpeed = Options.Misc_SpeedHackValue.Value
            currentSpeed      = currentSpeed + (targetSpeed - currentSpeed) * 0.3

            if moveDir.Magnitude > 0 then
                local cam   = Workspace.CurrentCamera
                local look  = Vector3.new(cam.CFrame.LookVector.X,  0, cam.CFrame.LookVector.Z).Unit
                local right = Vector3.new(cam.CFrame.RightVector.X, 0, cam.CFrame.RightVector.Z).Unit
                local wd    = (look * -moveDir.Z) + (right * moveDir.X)
                wd          = wd.Unit
                r.CFrame    = r.CFrame + (wd * currentSpeed * dt)
                h.WalkSpeed = currentSpeed
            else
                h.WalkSpeed = 16
            end
        end)
    end

    local function disableSpeedHack()
        speedEnabled = false
        if speedConn then speedConn:Disconnect(); speedConn = nil end
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum then hum.WalkSpeed = 16 end
        end
        disableNoClip()
    end

    SpeedBox:AddToggle('Misc_SpeedHack', {
        Text     = 'SpeedHack',
        Default  = false,
        Callback = function(v)
            if v then enableSpeedHack() else disableSpeedHack() end
        end,
    })
    SpeedBox:AddSlider('Misc_SpeedHackValue', {
        Text     = 'Speed',
        Default  = 15,
        Min      = 1,
        Max      = 15,
        Rounding = 1,
    })

    -- Third Person state
    local tpEnabled    = false
    local tpConn       = nil
    local tpMouseConn  = nil
    local mouseX, mouseY = 0, 0

    local function enableThirdPerson()
        if tpEnabled then return end
        tpEnabled    = true
        mouseX, mouseY = 0, 0

        UserInputService.MouseBehavior   = Enum.MouseBehavior.LockCenter
        UserInputService.MouseIconEnabled = false

        tpMouseConn = UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement and tpEnabled then
                mouseX = mouseX - input.Delta.X * 0.01
                mouseY = math.clamp(mouseY - input.Delta.Y * 0.01, -math.rad(80), math.rad(80))
            end
        end)

        tpConn = RunService.RenderStepped:Connect(function()
            if not tpEnabled then return end
            local c = LocalPlayer.Character
            if not c then return end
            local root = c:FindFirstChild("HumanoidRootPart")
            local head = c:FindFirstChild("Head")
            if not root or not head then return end

            -- Make all body parts visible
            for _, part in ipairs(c:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.LocalTransparencyModifier = 0
                end
            end

            local rotCF  = CFrame.fromOrientation(mouseY, mouseX, 0)
            local look   = rotCF.LookVector
            local camPos = root.Position - (look * 10) + Vector3.new(0, 6, 0)
            local lookAt = head.Position + Vector3.new(0, 1, 0)

            Workspace.CurrentCamera.CFrame = CFrame.lookAt(camPos, lookAt)
        end)
    end

    local function disableThirdPerson()
        if not tpEnabled then return end
        tpEnabled = false
        if tpConn      then tpConn:Disconnect();      tpConn      = nil end
        if tpMouseConn then tpMouseConn:Disconnect(); tpMouseConn = nil end
        UserInputService.MouseBehavior    = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
        Workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
    end

    TPBox:AddToggle('Misc_ThirdPerson', {
        Text     = 'ThirdPerson',
        Default  = false,
        Callback = function(v)
            if v then enableThirdPerson() else disableThirdPerson() end
        end,
    })
    TPBox:AddLabel('ThirdPerson Key'):AddKeyPicker('Misc_ThirdPersonKey', {
        Default = 'H',
        NoUI    = false,
        Text    = 'ThirdPerson Key',
    })

    KeybindSystem:Register(
        "ThirdPerson",
        function() return Options.Misc_ThirdPersonKey and Options.Misc_ThirdPersonKey.Value end,
        Toggles.Misc_ThirdPerson,
        "Toggle"
    )

    -- Respawn handler
    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(2)
        if speedEnabled then
            disableSpeedHack()
            task.wait(0.5)
            if Toggles.Misc_SpeedHack.Value then enableSpeedHack() end
        end
        if tpEnabled then
            disableThirdPerson()
            task.wait(0.5)
            if Toggles.Misc_ThirdPerson.Value then enableThirdPerson() end
        end
    end)
end
setupMovement()

-- ══════════════════════════════════════════════════════════════════════════════
--  RAPID FIRE
-- ══════════════════════════════════════════════════════════════════════════════

local function setupRapidFire()
    local RapidBox = Tabs.Combat:AddLeftGroupbox('Rapid Fire')

    RapidBox:AddToggle('Combat_RapidFire', {
        Text    = 'Rapid Fire',
        Default = false,
        Tooltip = 'Maximum fire rate, uses normal ammo',
    })

    local GunBase, GunClient
    pcall(function() GunBase   = require(ReplicatedStorage.Gun.Scripts.GunBase)   end)
    pcall(function() GunClient = require(ReplicatedStorage.Gun.Scripts.GunClient) end)

    if GunBase then
        local oldCanFire = GunBase.canFire
        GunBase.canFire = function(self)
            if Toggles.Combat_RapidFire and Toggles.Combat_RapidFire.Value then
                if self.Equipping or not self.IsEquipped then return false end
                self.FiringOnCooldown = false
                return oldCanFire(self)
            end
            return oldCanFire(self)
        end
    end

    if GunClient then
        local oldFire = GunClient.fire
        GunClient.fire = function(self, isFirstShot)
            if Toggles.Combat_RapidFire and Toggles.Combat_RapidFire.Value then
                self.FireDelay = 0
            end
            return oldFire(self, isFirstShot)
        end
    end
end
setupRapidFire()

-- ══════════════════════════════════════════════════════════════════════════════
--  WEAPON MODS (Instant Hit + Instant Reload)
-- ══════════════════════════════════════════════════════════════════════════════

local CombatModSection = Tabs.Combat:AddLeftGroupbox('Weapon mods')

CombatModSection:AddToggle('Combat_InstantHit', {
    Text    = 'No Ballistic',
    Default = false,
    Tooltip = 'Bullets have no travel time',
})
CombatModSection:AddToggle('Combat_InstantReload', {
    Text    = 'Instant Reload',
    Default = false,
    Tooltip = 'Instantly reloads',
})

do
    local GunBase, GunClient
    pcall(function() GunBase   = require(ReplicatedStorage.Gun.Scripts.GunBase)   end)
    pcall(function() GunClient = require(ReplicatedStorage.Gun.Scripts.GunClient) end)

    if GunBase then
        local oldGetVelocity = GunBase.getBulletVelocity
        GunBase.getBulletVelocity = function(self)
            if Toggles.Combat_InstantHit and Toggles.Combat_InstantHit.Value then
                return 1000000
            end
            return oldGetVelocity(self)
        end
    end

    if GunClient then
        local oldUpdateVelocity = GunClient.updateBulletVelocity
        GunClient.updateBulletVelocity = function(self)
            if Toggles.Combat_InstantHit and Toggles.Combat_InstantHit.Value then
                if self.FireVisuals then self.FireVisuals.Velocity = 1000000 end
            else
                return oldUpdateVelocity(self)
            end
        end

        local oldReload = GunClient.reload
        GunClient.reload = function(self, ammoName)
            if Toggles.Combat_InstantReload and Toggles.Combat_InstantReload.Value then
                if not self.IsEquipped or self.Reloading then return false end

                local reloadRemote = ReplicatedStorage:FindFirstChild("Gun")
                    and ReplicatedStorage.Gun:FindFirstChild("Remotes")
                    and ReplicatedStorage.Gun.Remotes:FindFirstChild("Reload")

                if reloadRemote then
                    pcall(function() reloadRemote:FireServer(self.Tool, ammoName) end)
                end

                self.Reloading   = false
                self.CurrentAmmo = self.MaxAmmo

                if self.updateGunGui then self:updateGunGui() end
                if self.stopReload   then self:stopReload()   end
                return true
            end
            return oldReload(self, ammoName)
        end
    end
end

-- ══════════════════════════════════════════════════════════════════════════════
--  CHAMS (Gun & Arms)
-- ══════════════════════════════════════════════════════════════════════════════

local function setupChams()
    local GunChams = { Enabled = false, Color = Color3.fromRGB(255, 50, 50), Material = "Neon" }
    local ArmChams = { Enabled = false, Color = Color3.fromRGB(100, 200, 255), Material = "Neon" }
    local origData = {}

    local function saveOrig(part)
        if origData[part] then return end
        origData[part] = {
            Color      = part.Color,
            Material   = part.Material,
            CastShadow = part.CastShadow,
        }
    end

    local function applyToVM(vm)
        if not vm then return end
        for _, inst in ipairs(vm:GetDescendants()) do
            if inst:IsA("SurfaceAppearance") then
                inst:Destroy()
            elseif inst:IsA("BasePart") then
                saveOrig(inst)
                local isArm = inst.Name:lower():find("arm")
                if isArm and ArmChams.Enabled then
                    inst.Color      = ArmChams.Color
                    inst.Material   = Enum.Material[ArmChams.Material]
                    inst.CastShadow = false
                elseif not isArm and GunChams.Enabled then
                    inst.Color      = GunChams.Color
                    inst.Material   = Enum.Material[GunChams.Material]
                    inst.CastShadow = false
                end
            end
        end
    end

    local function restoreVM(vm)
        if not vm then return end
        for _, inst in ipairs(vm:GetDescendants()) do
            local d = origData[inst]
            if inst:IsA("BasePart") and d then
                inst.Color      = d.Color
                inst.Material   = d.Material
                inst.CastShadow = d.CastShadow
                origData[inst]  = nil
            end
        end
    end

    local vmHooked = false
    local function hookVM()
        if vmHooked then return end
        local ok, VM = pcall(require,
            ReplicatedStorage:WaitForChild("Gun")
                :WaitForChild("Scripts")
                :WaitForChild("ViewModel")
        )
        if not ok or not VM then return end
        vmHooked     = true
        local oldCreate = VM.createViewModel
        if not oldCreate then return end
        VM.createViewModel = function(self, ...)
            local r = oldCreate(self, ...)
            if self.ViewModel then applyToVM(self.ViewModel) end
            return r
        end
    end

    local function findViewModel()
        local char = Players.LocalPlayer.Character
        if not char then return nil end
        local vm = char:FindFirstChild("ViewModel")
            or workspace:FindFirstChild("ViewModel")
            or workspace.CurrentCamera:FindFirstChild("ViewModel")
        if not vm then
            for _, tool in ipairs(char:GetChildren()) do
                if tool:IsA("Tool") then
                    vm = tool:FindFirstChild("ViewModel")
                    if vm then break end
                end
            end
        end
        return vm
    end

    local function refreshCurrentVM()
        local vm = findViewModel()
        if not vm then return end
        if GunChams.Enabled or ArmChams.Enabled then
            applyToVM(vm)
        else
            restoreVM(vm)
        end
    end

    local ChamsGroup = Tabs.Visuals:AddLeftGroupbox('Chams')

    ChamsGroup:AddToggle('GunChams_Enabled', {
        Text     = 'Gun Chams',
        Default  = false,
        Tooltip  = 'Enable chams on your weapon',
        Callback = function(v) GunChams.Enabled = v; hookVM(); refreshCurrentVM() end,
    })
    ChamsGroup:AddLabel('Gun Color'):AddColorPicker('GunChams_Color', {
        Default     = GunChams.Color,
        Title       = 'Gun Chams Color',
        Transparency = 0,
        Callback    = function(v)
            GunChams.Color = v
            if GunChams.Enabled then refreshCurrentVM() end
        end,
    })
    ChamsGroup:AddDropdown('GunChams_Material', {
        Text     = 'Gun Material',
        Values   = { "Neon", "ForceField", "Plastic", "Glass", "Metal" },
        Default  = "Neon",
        Callback = function(v)
            GunChams.Material = v
            if GunChams.Enabled then refreshCurrentVM() end
        end,
    })

    ChamsGroup:AddDivider()

    ChamsGroup:AddToggle('ArmChams_Enabled', {
        Text     = 'Arm Chams',
        Default  = false,
        Tooltip  = 'Enable chams on your arms',
        Callback = function(v) ArmChams.Enabled = v; hookVM(); refreshCurrentVM() end,
    })
    ChamsGroup:AddLabel('Arm Color'):AddColorPicker('ArmChams_Color', {
        Default     = ArmChams.Color,
        Title       = 'Arm Chams Color',
        Transparency = 0,
        Callback    = function(v)
            ArmChams.Color = v
            if ArmChams.Enabled then refreshCurrentVM() end
        end,
    })
    ChamsGroup:AddDropdown('ArmChams_Material', {
        Text     = 'Arm Material',
        Values   = { "Neon", "ForceField", "Plastic", "Glass", "Metal" },
        Default  = "Neon",
        Callback = function(v)
            ArmChams.Material = v
            if ArmChams.Enabled then refreshCurrentVM() end
        end,
    })

    workspace.DescendantAdded:Connect(function(obj)
        if obj:IsA("Tool") or obj.Name == "ViewModel" then
            task.wait(0.1)
            if GunChams.Enabled or ArmChams.Enabled then refreshCurrentVM() end
        end
    end)
end
setupChams()

-- ══════════════════════════════════════════════════════════════════════════════
--  TRIGGER BOT
-- ══════════════════════════════════════════════════════════════════════════════

local function setupTriggerBot()
    local TriggerGroup = Tabs.Combat:AddLeftGroupbox('Trigger Bot')

    local Trigger = {
        Enabled   = false,
        FOV       = 15,
        Delay     = 0,
        DeadCheck = true,
        WallCheck = false,
        UseRapid  = true,
    }

    local GunBase3, GunClient3
    pcall(function() GunBase3   = require(ReplicatedStorage.Gun.Scripts.GunBase)   end)
    pcall(function() GunClient3 = require(ReplicatedStorage.Gun.Scripts.GunClient) end)

    local isFiring   = false
    local fireConn   = nil
    local delayTimer = 0

    -- Cache VirtualInputManager
    local vgInput = game:GetService("VirtualInputManager")

    local function startFire()
        if isFiring then return end
        isFiring = true

        if GunBase3 then GunBase3.FiringOnCooldown = false end

        if Trigger.UseRapid and Toggles.Combat_RapidFire then
            Toggles.Combat_RapidFire:SetValue(true)
        end

        fireConn = RunService.RenderStepped:Connect(function()
            if not isFiring then
                fireConn:Disconnect()
                fireConn = nil
                return
            end
            if GunBase3 then GunBase3.FiringOnCooldown = false end
        end)

        pcall(function() vgInput:SendMouseButtonEvent(0, 0, 0, true, game, 0) end)
    end

    local function stopFire()
        if not isFiring then return end
        isFiring = false

        if fireConn then fireConn:Disconnect(); fireConn = nil end

        if Trigger.UseRapid and Toggles.Combat_RapidFire then
            Toggles.Combat_RapidFire:SetValue(false)
        end

        pcall(function() vgInput:SendMouseButtonEvent(0, 0, 0, false, game, 0) end)
    end

    local function isOnTarget()
        local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        local fovSq  = Trigger.FOV ^ 2

        -- When Silent Aim is active, use its cached target
        if SilentAim and SilentAim.Enabled and CurrentAimTarget then
            local target = CurrentAimTarget
            if not target or not target.Parent then return false end

            if Trigger.DeadCheck then
                local model = target:FindFirstAncestorOfClass("Model")
                local hum   = model and model:FindFirstChildOfClass("Humanoid")
                if not hum or hum.Health <= 0 then return false end
            end

            if Trigger.WallCheck then
                local origin = Camera.CFrame.Position
                local dir    = target.Position - origin
                local ray    = RaycastParams.new()
                ray.FilterDescendantsInstances = { LocalPlayer.Character }
                ray.FilterType                 = Enum.RaycastFilterType.Exclude
                local res = workspace:Raycast(origin, dir, ray)
                if res and not res.Instance:IsDescendantOf(target:FindFirstAncestorOfClass("Model")) then
                    return false
                end
            end

            local pos3, onScreen = Camera:WorldToViewportPoint(target.Position)
            if not onScreen then return false end
            local dx = pos3.X - center.X
            local dy = pos3.Y - center.Y
            return (dx * dx + dy * dy) <= fovSq
        end

        -- Fallback: raycast from screen center
        local unitRay = Camera:ViewportPointToRay(center.X, center.Y)
        local params  = RaycastParams.new()
        params.FilterDescendantsInstances = { LocalPlayer.Character }
        params.FilterType                 = Enum.RaycastFilterType.Exclude
        local res = workspace:Raycast(unitRay.Origin, unitRay.Direction * 2000, params)
        if not res or not res.Instance then return false end

        local model = res.Instance:FindFirstAncestorOfClass("Model")
        if not model then return false end

        local hum = model:FindFirstChildOfClass("Humanoid")
        if not hum then return false end

        if Trigger.DeadCheck and hum.Health <= 0 then return false end
        if model == LocalPlayer.Character then return false end

        return Players:GetPlayerFromCharacter(model) ~= nil
    end

    local triggerConn = nil

    local function startTrigger()
        if triggerConn then return end
        delayTimer = 0

        triggerConn = RunService.RenderStepped:Connect(function(dt)
            if not Trigger.Enabled then return end

            if Library.Open then
                stopFire()
                delayTimer = 0
                return
            end

            local char = LocalPlayer.Character
            local tool = char and char:FindFirstChildWhichIsA("Tool")
            if not tool then
                stopFire()
                delayTimer = 0
                return
            end

            if isOnTarget() then
                if Trigger.Delay <= 0 then
                    startFire()
                else
                    delayTimer = delayTimer + dt * 1000
                    if delayTimer >= Trigger.Delay then startFire() end
                end
            else
                stopFire()
                delayTimer = 0
            end
        end)
    end

    local function stopTrigger()
        if triggerConn then triggerConn:Disconnect(); triggerConn = nil end
        stopFire()
    end

    TriggerGroup:AddToggle('TriggerBot_Enabled', {
        Text     = 'Trigger Bot',
        Default  = false,
        Tooltip  = 'Auto-fire when crosshair is on enemy',
        Callback = function(v)
            Trigger.Enabled = v
            if v then startTrigger() else stopTrigger() end
        end,
    })
    TriggerGroup:AddSlider('TriggerBot_FOV', {
        Text     = 'FOV (px from center)',
        Default  = 15,
        Min      = 1,
        Max      = 500,
        Rounding = 0,
        Tooltip  = 'How many pixels from screen center counts as "on target"',
        Callback = function(v) Trigger.FOV = v end,
    })
    TriggerGroup:AddSlider('TriggerBot_Delay', {
        Text     = 'Delay (ms)',
        Default  = 0,
        Min      = 0,
        Max      = 500,
        Rounding = 0,
        Tooltip  = 'Wait before shooting (0 = instant)',
        Callback = function(v) Trigger.Delay = v end,
    })
    TriggerGroup:AddToggle('TriggerBot_DeadCheck', {
        Text     = 'Dead Check',
        Default  = true,
        Tooltip  = 'Do not shoot dead players',
        Callback = function(v) Trigger.DeadCheck = v end,
    })
    TriggerGroup:AddToggle('TriggerBot_WallCheck', {
        Text     = 'Wall Check',
        Default  = false,
        Tooltip  = 'Do not shoot through walls',
        Callback = function(v) Trigger.WallCheck = v end,
    })
    TriggerGroup:AddToggle('TriggerBot_UseRapid', {
        Text     = 'Use Rapid Fire',
        Default  = true,
        Tooltip  = 'Activates Rapid Fire while trigger is firing',
        Callback = function(v) Trigger.UseRapid = v end,
    })

    Library:OnUnload(function() stopTrigger() end)
end
setupTriggerBot()
