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
    WYNF_ENC_STRING('https://raw.githubusercontent.com/pisqstroY/-scythe/refs/heads/main/ScytheLibtrue.lua')
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
--  WORKSPACE ENTITY ESP
-- ══════════════════════════════════════════════════════════════════════════════

local RunService  = game:GetService('RunService')
local Players     = game:GetService('Players')
local Workspace   = game:GetService('Workspace')
local Camera      = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local _ESPObjects = {}

local function _getLocalChar()
    -- в этой игре персонаж тут, а не в LocalPlayer.Character
    local ok, c = pcall(function()
        return Workspace.Const.Ignore.LocalCharacter
    end)
    return ok and c or LocalPlayer.Character
end

local function _getHRP(model)
    return model:FindFirstChild("HumanoidRootPart")
        or model:FindFirstChild("UpperTorso")
        or model:FindFirstChild("Torso")
end

local function _getHead(model)
    return model:FindFirstChild("Head")
end

local function _createESP(model)
    if _ESPObjects[model] then return end
    if model == _getLocalChar() then return end

    -- нужны хотя бы голова или торс — Humanoid не обязателен
    local hrp  = _getHRP(model)
    local head = _getHead(model)
    if not hrp and not head then return end
    local anchor = hrp or head

    local lines = {}
    for i = 1, 8 do
        local l = Drawing.new("Line")
        l.Thickness    = 1.5
        l.Transparency = 1
        l.Visible      = false
        l.Color        = Color3.fromRGB(255,255,255)
        lines[i] = l
    end

    local nameText = Drawing.new("Text")
    nameText.Size    = 13
    nameText.Center  = true
    nameText.Outline = true
    nameText.Visible = false
    nameText.Color   = Color3.fromRGB(255,255,255)

    local distText = Drawing.new("Text")
    distText.Size    = 12
    distText.Center  = true
    distText.Outline = true
    distText.Visible = false
    distText.Color   = Color3.fromRGB(200,200,200)

    local healthBG = Drawing.new("Square")
    healthBG.Filled       = true
    healthBG.Color        = Color3.new(0,0,0)
    healthBG.Transparency = 0.5
    healthBG.Visible      = false

    local healthFG = Drawing.new("Square")
    healthFG.Filled       = true
    healthFG.Transparency = 1
    healthFG.Visible      = false

    _ESPObjects[model] = {
        lines    = lines,
        name     = nameText,
        dist     = distText,
        healthBG = healthBG,
        healthFG = healthFG,
        anchor   = anchor,  -- hrp или head, что нашли
    }

    model.Destroying:Connect(function()
        local obj = _ESPObjects[model]
        if not obj then return end
        for _, l in ipairs(obj.lines) do pcall(function() l:Remove() end) end
        pcall(function() obj.name:Remove()     end)
        pcall(function() obj.dist:Remove()     end)
        pcall(function() obj.healthBG:Remove() end)
        pcall(function() obj.healthFG:Remove() end)
        _ESPObjects[model] = nil
    end)
end

local function _hideESP(obj)
    for _, l in ipairs(obj.lines) do l.Visible = false end
    obj.name.Visible     = false
    obj.dist.Visible     = false
    obj.healthBG.Visible = false
    obj.healthFG.Visible = false
end
local function _isPlayer(model)
    local torso = model:FindFirstChild("Torso")
    return torso and torso:FindFirstChild("LeftBooster") ~= nil
end

local function _isSleeping(model, anchor)
    local root = model:FindFirstChild("HumanoidRootPart")
    local head = model:FindFirstChild("Head")
    if root and head then
        return (head.Position.Y - root.Position.Y) < 1.2
    end
    return false
end
-- первичный скан
for _, v in ipairs(Workspace:GetChildren()) do
    if v:IsA("Model") then _createESP(v) end
end

Workspace.ChildAdded:Connect(function(v)
    if v:IsA("Model") then
        task.wait(0.1)
        _createESP(v)
    end
end)

RunService.RenderStepped:Connect(function()
    if not Toggles.ESP_Enabled.Value then
        for _, obj in pairs(_ESPObjects) do _hideESP(obj) end
        return
    end

    local maxDist   = Options.ESP_MaxDistance.Value
    local localChar = _getLocalChar()
    local botsOnly  = Toggles.ESP_BotsOnly.Value
    local noSleepers = Toggles.ESP_NoSleepers.Value

    for model, obj in pairs(_ESPObjects) do
        if model == localChar then _hideESP(obj); continue end

        local anchor = obj.anchor
        if not anchor or not anchor.Parent then
            _hideESP(obj); continue
        end

        local player = _isPlayer(model)

        -- фильтр: если включён Player Only — скрываем ботов
        if botsOnly and not player then
            _hideESP(obj); continue
        end

        -- фильтр слиперов
        if noSleepers and _isSleeping(model, anchor) then
            _hideESP(obj); continue
        end

        local sp, onScreen = Camera:WorldToViewportPoint(anchor.Position)
        if not onScreen then _hideESP(obj); continue end

        local dist = (Camera.CFrame.Position - anchor.Position).Magnitude
        if dist > maxDist then _hideESP(obj); continue end

        local scale = Camera.ViewportSize.Y / sp.Z
        local w  = scale * 1.5
        local h  = scale * 2.8
        local x1 = sp.X - w/2
        local y1 = sp.Y - h/2
        local x2 = sp.X + w/2
        local y2 = sp.Y + h/2
        local cs = math.clamp(w * 0.25, 4, 12)

        -- цвет уголков: игрок = акцент, бот = серый
        local cornerColor = player and Library.AccentColor or Color3.fromRGB(150,150,150)
        local ln = obj.lines
        for _, l in ipairs(ln) do l.Color = cornerColor end

        ln[1].Visible = true; ln[1].From = Vector2.new(x1,y1); ln[1].To = Vector2.new(x1+cs,y1)
        ln[2].Visible = true; ln[2].From = Vector2.new(x1,y1); ln[2].To = Vector2.new(x1,y1+cs)
        ln[3].Visible = true; ln[3].From = Vector2.new(x2,y1); ln[3].To = Vector2.new(x2-cs,y1)
        ln[4].Visible = true; ln[4].From = Vector2.new(x2,y1); ln[4].To = Vector2.new(x2,y1+cs)
        ln[5].Visible = true; ln[5].From = Vector2.new(x1,y2); ln[5].To = Vector2.new(x1+cs,y2)
        ln[6].Visible = true; ln[6].From = Vector2.new(x1,y2); ln[6].To = Vector2.new(x1,y2-cs)
        ln[7].Visible = true; ln[7].From = Vector2.new(x2,y2); ln[7].To = Vector2.new(x2-cs,y2)
        ln[8].Visible = true; ln[8].From = Vector2.new(x2,y2); ln[8].To = Vector2.new(x2,y2-cs)

        -- имя: у игрока — его ник, у бота — "Bot"
        if Toggles.ESP_Names.Value then
            obj.name.Visible  = true
            obj.name.Position = Vector2.new(sp.X, y1 - 14)
            obj.name.Text     = player and model.Name or "Bot"
            obj.name.Color    = player
                and Color3.fromRGB(255,255,255)
                or  Color3.fromRGB(180,180,180)
        else
            obj.name.Visible = false
        end

        -- дистанция
        if Toggles.ESP_Distance.Value then
            obj.dist.Visible  = true
            obj.dist.Position = Vector2.new(sp.X, y2 + 2)
            obj.dist.Text     = string.format("%.0fm", dist)
        else
            obj.dist.Visible = false
        end

        -- хелсбар
        local hum = model:FindFirstChildOfClass("Humanoid")
        if Toggles.ESP_Healthbar.Value and hum then
            local hp = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
            local bx = x1 - 6
            obj.healthBG.Visible  = true
            obj.healthBG.Size     = Vector2.new(3, h)
            obj.healthBG.Position = Vector2.new(bx, y1)
            obj.healthFG.Visible  = true
            obj.healthFG.Size     = Vector2.new(3, h * hp)
            obj.healthFG.Position = Vector2.new(bx, y2 - h*hp)
            obj.healthFG.Color    = Color3.new(1-hp, hp, 0)
        else
            obj.healthBG.Visible = false
            obj.healthFG.Visible = false
        end
    end
end)

local ESPSection = Tabs.Visuals:AddLeftGroupbox('Entity ESP')
ESPSection:AddToggle('ESP_Enabled',    { Text = 'ESP Enabled',       Default = true  })
ESPSection:AddToggle('ESP_Names',      { Text = 'Names',             Default = true  })
ESPSection:AddToggle('ESP_Distance',   { Text = 'Distance',          Default = true  })
ESPSection:AddToggle('ESP_Healthbar',  { Text = 'Healthbar',         Default = true  })
ESPSection:AddToggle('ESP_BotsOnly',   { Text = 'Players Only',      Default = false })
ESPSection:AddToggle('ESP_NoSleepers', { Text = 'Hide Sleepers',     Default = false })
ESPSection:AddSlider('ESP_MaxDistance', {
    Text     = 'Max Distance',
    Default  = 200,
    Min      = 50,
    Max      = 2000,
    Rounding = 0,
})
-- ══════════════════════════════════════════════════════════════════════════════
--  ZONE ESP
-- ══════════════════════════════════════════════════════════════════════════════

do
    local ZoneGroup = Tabs.Misc:AddLeftGroupbox('Zone ESP')
    ZoneGroup:AddToggle('ZESP_SafeZone', { Text = 'SafeZone Visible', Default = false })
    Toggles.ZESP_SafeZone:OnChanged(function(v)
        pcall(function()
            Workspace.World.Zones.SafeZones["SAFEZONE_Town"].Transparency = v and 0.97 or 1
        end)
    end)
end
-- ══════════════════════════════════════════════════════════════════════════════
--  BOAT BOOST  (Hull detection)
-- ══════════════════════════════════════════════════════════════════════════════

do
    local boatBoostEnabled  = false
    local boatBoostSpeed    = 100
    local boatBoostUpSpeed  = 30
    local boatBoostAccel    = 200
    local boatBuildup       = 0
    local boatLastDir       = Vector3.new(0, 0, 1)
    local currentBoat       = nil

    local function findBoat()
        currentBoat = nil
        for _, v in pairs(Workspace:GetChildren()) do
            if v:IsA("Model") and v:FindFirstChild("Hull") then
                currentBoat = v
                currentBoat.PrimaryPart = v.Hull
                break
            end
        end
    end
    findBoat()

    local BBGroup = Tabs.Misc:AddLeftGroupbox('Boat Boost')
    BBGroup:AddToggle('BB_Enabled', { Text = 'Boat Boost', Default = false })
    Toggles.BB_Enabled:OnChanged(function(v)
        boatBoostEnabled = v
        if v then findBoat() end
        if not v and currentBoat then
            for _, p in pairs(currentBoat:GetChildren()) do
                if p:IsA("BasePart") then p.AssemblyLinearVelocity = Vector3.zero end
            end
        end
    end)
    BBGroup:AddSlider('BB_Speed',   { Text = 'Speed',        Default = 100, Min = 20,  Max = 500, Rounding = 0 })
    Options.BB_Speed:OnChanged(function(v)   boatBoostSpeed   = v end)
    BBGroup:AddSlider('BB_UpSpeed', { Text = 'Up Speed',     Default = 30,  Min = 5,   Max = 100, Rounding = 0 })
    Options.BB_UpSpeed:OnChanged(function(v) boatBoostUpSpeed = v end)
    BBGroup:AddSlider('BB_Accel',   { Text = 'Acceleration', Default = 200, Min = 50,  Max = 500, Rounding = 0 })
    Options.BB_Accel:OnChanged(function(v)   boatBoostAccel   = v end)
    BBGroup:AddButton('Rescan Boat', function() findBoat() end)
    BBGroup:AddLabel('WASD = move  |  V = up  |  LeftCtrl = down')

    RunService.Heartbeat:Connect(function(dt)
        if not boatBoostEnabled then boatBuildup = 0; return end
        if not currentBoat or not currentBoat.Parent then findBoat(); return end
        local hull = currentBoat:FindFirstChild("Hull")
        if not hull then findBoat(); return end

        local camLook = Camera.CFrame.LookVector
        local flatDir = Vector3.new(camLook.X, 0, camLook.Z)
        if flatDir.Magnitude > 0 then flatDir = flatDir.Unit end

        local moveDir  = Vector3.zero
        local isMoving = false

        if UIS:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + flatDir; isMoving = true end
        if UIS:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - flatDir; isMoving = true end
        if UIS:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Vector3.new(-flatDir.Z, 0, flatDir.X); isMoving = true end
        if UIS:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir + Vector3.new(flatDir.Z,  0, -flatDir.X); isMoving = true end
        if UIS:IsKeyDown(Enum.KeyCode.V) then moveDir = moveDir + Vector3.yAxis; isMoving = true end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.yAxis; isMoving = true end

        if isMoving and moveDir ~= Vector3.zero then
            moveDir = moveDir.Unit
            if moveDir ~= Vector3.yAxis and -moveDir ~= Vector3.yAxis then
                boatBuildup  = math.clamp(boatBuildup + dt * boatBoostAccel, 0, boatBoostSpeed)
                boatLastDir  = moveDir
            end
        else
            moveDir     = boatLastDir
            boatBuildup = 0
        end

        for _, part in pairs(currentBoat:GetChildren()) do
            if part:IsA("BasePart") then
                part.AssemblyLinearVelocity = Vector3.new(
                    moveDir.X * boatBuildup,
                    moveDir.Y * boatBoostUpSpeed,
                    moveDir.Z * boatBuildup
                )
            end
        end
    end)
end
-- ══════════════════════════════════════════════════════════════════════════════
--  CAR FLY  (ATV — Seat + Frame detection, swimhub method)
-- ══════════════════════════════════════════════════════════════════════════════

do
    local carFlyEnabled    = false
    local carFlySpeed      = 150
    local carFlyUpSpeed    = 15
    local carFlyAccel      = 100
    local carFlyBuildup    = 0
    local carFlyLastDir    = Vector3.new(1, 0, 0)
    local currentCar       = nil

    local function findNearestCar()
        currentCar = nil
        local bestDist = 100
        local middle   = getMiddle()
        if not middle then return end
        for _, v in pairs(Workspace:GetChildren()) do
            if v:FindFirstChild("Seat") and v:FindFirstChild("Frame") then
                local dist = (v.Frame.Position - middle.Position).Magnitude
                if dist < bestDist then
                    bestDist   = dist
                    currentCar = v
                end
            end
        end
    end

    local CFGroup = Tabs.Misc:AddLeftGroupbox('Car Fly')
    CFGroup:AddToggle('CF_Enabled', { Text = 'Car Fly', Default = false })
    Toggles.CF_Enabled:OnChanged(function(v)
        carFlyEnabled = v
        if v then findNearestCar() end
        if not v then carFlyBuildup = 0 end
    end)
    CFGroup:AddSlider('CF_Speed',   { Text = 'Speed',        Default = 150, Min = 10,  Max = 300, Rounding = 0 })
    Options.CF_Speed:OnChanged(function(v)   carFlySpeed   = v end)
    CFGroup:AddSlider('CF_UpSpeed', { Text = 'Up Speed',     Default = 15,  Min = 1,   Max = 100, Rounding = 0 })
    Options.CF_UpSpeed:OnChanged(function(v) carFlyUpSpeed = v end)
    CFGroup:AddSlider('CF_Accel',   { Text = 'Acceleration', Default = 100, Min = 10,  Max = 300, Rounding = 0 })
    Options.CF_Accel:OnChanged(function(v)   carFlyAccel   = v end)
    CFGroup:AddButton('Rescan Car', function() findNearestCar() end)
    CFGroup:AddLabel('WASD = move  |  V = up  |  B = down')

    RunService.RenderStepped:Connect(function(dt)
        if not carFlyEnabled then carFlyBuildup = 0; return end
        if not currentCar or not currentCar:FindFirstChild("Frame") then findNearestCar(); return end
        if (currentCar.Frame.CFrame.p - Camera.CFrame.p).Magnitude > 50 then
            findNearestCar(); carFlyBuildup = 0; return
        end

        local camLook = Camera.CFrame.LookVector
        local flatDir = Vector3.new(camLook.X, 0, camLook.Z)
        local moveDir = Vector3.zero
        local isMoving = false

        if UIS:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + flatDir; isMoving = true end
        if UIS:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - flatDir; isMoving = true end
        if UIS:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Vector3.new(-flatDir.Z, 0, flatDir.X); isMoving = true end
        if UIS:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir + Vector3.new(flatDir.Z,  0, -flatDir.X); isMoving = true end
        if UIS:IsKeyDown(Enum.KeyCode.V) then moveDir = moveDir + Vector3.yAxis; isMoving = true end
        if UIS:IsKeyDown(Enum.KeyCode.B) then moveDir = moveDir - Vector3.yAxis; isMoving = true end

        if isMoving and moveDir ~= Vector3.zero then
            moveDir = moveDir.Unit
            if moveDir ~= Vector3.yAxis and -moveDir ~= Vector3.yAxis then
                carFlyBuildup  = math.clamp(carFlyBuildup + dt * carFlyAccel, 0, carFlySpeed)
                carFlyLastDir  = moveDir
            end
        else
            moveDir       = carFlyLastDir
            carFlyBuildup = math.clamp(carFlyBuildup - dt * 150, 0, carFlySpeed)
        end

        for _, part in pairs(currentCar:GetChildren()) do
            if part:IsA("BasePart") then
                part.AssemblyLinearVelocity = Vector3.new(
                    moveDir.X * carFlyBuildup,
                    moveDir.Y * carFlyUpSpeed,
                    moveDir.Z * carFlyBuildup
                )
            end
        end
    end)
end
-- ══════════════════════════════════════════════════════════════════════════════
--  LONG NECK  (move Prism1 down)
-- ══════════════════════════════════════════════════════════════════════════════

do
    local longNeckActive   = false
    local prismOriginalCF  = nil

    local ExploitGroup = Tabs.Misc:AddLeftGroupbox('Exploits')
    ExploitGroup:AddToggle('LN_Enabled', { Text = 'Long Neck', Default = false })
    Toggles.LN_Enabled:OnChanged(function(v)
        pcall(function()
            local top   = getTop()
            if not top then return end
            local prism = top:FindFirstChild("Prism1")
            if not prism then return end
            if v then
                prismOriginalCF = prism.CFrame
                prism.CFrame    = prism.CFrame - Vector3.yAxis * 5
            else
                if prismOriginalCF then prism.CFrame = prismOriginalCF end
            end
            longNeckActive = v
        end)
    end)
end
-- ══════════════════════════════════════════════════════════════════════════════
--  FORCE SPRINT
-- ══════════════════════════════════════════════════════════════════════════════

do
    local forceSprintEnabled = false

    local FSGroup = Tabs.Misc:AddLeftGroupbox('Force Sprint')
    FSGroup:AddToggle('FS_Enabled', { Text = 'Force Sprint', Default = false })
    Toggles.FS_Enabled:OnChanged(function(v) forceSprintEnabled = v end)

    RunService.RenderStepped:Connect(function()
        if not forceSprintEnabled then return end
        local middle = getMiddle()
        if not middle then return end
        local camLook = Camera.CFrame.LookVector
        local flatDir = Vector3.new(camLook.X, 0, camLook.Z)
        local moveDir = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + flatDir end
        if UIS:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - flatDir end
        if UIS:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Vector3.new(-flatDir.Z, 0, flatDir.X) end
        if UIS:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir + Vector3.new(flatDir.Z,  0, -flatDir.X) end
        if moveDir ~= Vector3.zero then moveDir = moveDir.Unit end
        middle.AssemblyLinearVelocity = Vector3.new(moveDir.X * 18, middle.AssemblyLinearVelocity.Y, moveDir.Z * 18)
    end)
end
-- ══════════════════════════════════════════════════════════════════════════════
--  SILENT SPEED  (TCP slide exploit)
-- ══════════════════════════════════════════════════════════════════════════════

do
    local silentSpeedEnabled = false
    local silentSpeedActive  = false
    local silentSpeedValue   = 55
    local silentSpeedTimer   = 0
    local silentSpeedSliding = false

    local SilentGroup = Tabs.Misc:AddLeftGroupbox('Silent Speed')
    SilentGroup:AddToggle('SS_Enabled', { Text = 'Silent Speed', Default = false })
    Toggles.SS_Enabled:OnChanged(function(v) silentSpeedEnabled = v end)
    SilentGroup:AddToggle('SS_Active', { Text = 'Activate', Default = false })
    Toggles.SS_Active:OnChanged(function(v)
        silentSpeedActive = v
        if not v and silentSpeedSliding then
            local tcp = getTCP()
            if tcp then pcall(function() tcp:FireServer(3, false); tcp:FireServer(2, false) end) end
            silentSpeedSliding = false
        end
    end)
    SilentGroup:AddSlider('SS_Value', { Text = 'Speed (sps)', Default = 55, Min = 10, Max = 150, Rounding = 0 })
    Options.SS_Value:OnChanged(function(v) silentSpeedValue = v end)
    SilentGroup:AddLabel('Shift + C to move while sliding')

    RunService.Heartbeat:Connect(function(dt)
        if not silentSpeedEnabled or not silentSpeedActive then
            silentSpeedTimer = 0; return
        end
        local middle = getMiddle(); local bottom = getBottom(); local top = getTop()
        if not middle or not bottom or not top then return end

        local camLook = Camera.CFrame.LookVector
        local flatDir = Vector3.new(camLook.X, 0, camLook.Z)
        local moveDir = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + flatDir end
        if UIS:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - flatDir end
        if UIS:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Vector3.new(-flatDir.Z, 0, flatDir.X) end
        if UIS:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir + Vector3.new(flatDir.Z,  0, -flatDir.X) end
        if moveDir ~= Vector3.zero then moveDir = moveDir.Unit end

        local heightOffset = silentSpeedTimer < 0.85 and 6 or math.clamp(6 - silentSpeedTimer * 15, 0, 6)

        if silentSpeedTimer == 0 then
            local tcp = getTCP()
            if tcp then pcall(function() tcp:FireServer(3, true, Vector3.xAxis); tcp:FireServer(2, true) end) end
            silentSpeedSliding = true
        end

        local oldMid = middle.CFrame; local oldBot = bottom.CFrame; local oldTop = top.CFrame
        middle.CFrame = oldMid + Vector3.new(0, heightOffset, 0)
        bottom.CFrame = oldBot + Vector3.new(0, heightOffset, 0)
        top.CFrame    = oldTop + Vector3.new(0, heightOffset, 0)

        RunService.RenderStepped:Wait()

        if middle then
            middle.CFrame = oldMid; bottom.CFrame = oldBot; top.CFrame = oldTop
            local vel = moveDir * silentSpeedValue
            middle.AssemblyLinearVelocity = vel
            bottom.AssemblyLinearVelocity = vel
            top.AssemblyLinearVelocity    = vel
        end

        silentSpeedTimer = silentSpeedTimer + dt
        if silentSpeedTimer > 1.5 then
            local tcp = getTCP()
            if tcp then pcall(function() tcp:FireServer(3, false); tcp:FireServer(2, false) end) end
            silentSpeedSliding = false
            silentSpeedTimer   = 0
        end
    end)
end
-- ══════════════════════════════════════════════════════════════════════════════
--  HITBOX EXPANDER
-- ══════════════════════════════════════════════════════════════════════════════

do
    local hbEnabled      = false
    local hbConnection   = nil
    local hbSizeX        = 10
    local hbSizeY        = 10
    local hbSize         = Vector3.new(10, 10, 10)
    local hbTransparency = 0.5
    local hbCanCollide   = false

    local function applyHitbox(model)
        for _, v in model:GetChildren() do
            if v.Name == "Head" and v.Material == Enum.Material.Plastic then
                v.Size        = hbSize
                v.Transparency = hbTransparency
                v.CanCollide  = hbCanCollide
            end
        end
    end

    local function restoreHitbox(model)
        for _, v in model:GetChildren() do
            if v.Name == "Head" and v.Material == Enum.Material.Plastic then
                v.Size        = Vector3.new(1, 1, 1)
                v.Transparency = 0
                v.CanCollide  = false
            end
        end
    end

    local HBGroup = Tabs.Combat:AddLeftGroupbox('Hitbox Expander')
    HBGroup:AddToggle('HB_Enabled', { Text = 'Enable Hitbox Expander', Default = false })
    Toggles.HB_Enabled:OnChanged(function(v)
        hbEnabled = v
        if hbConnection then hbConnection:Disconnect(); hbConnection = nil end
        if v then
            hbConnection = RunService.Heartbeat:Connect(function()
                for _, model in pairs(validcharacters) do applyHitbox(model) end
            end)
        else
            for _, model in pairs(validcharacters) do restoreHitbox(model) end
        end
    end)
    HBGroup:AddToggle('HB_CanCollide', { Text = 'Can Collide', Default = false })
    Toggles.HB_CanCollide:OnChanged(function(v) hbCanCollide = v end)
    HBGroup:AddSlider('HB_Transparency', { Text = 'Transparency', Default = 5, Min = 0, Max = 10, Rounding = 0 })
    Options.HB_Transparency:OnChanged(function(v) hbTransparency = v / 10 end)
    HBGroup:AddSlider('HB_SizeX', { Text = 'Size X', Default = 10, Min = 1, Max = 100, Rounding = 0 })
    Options.HB_SizeX:OnChanged(function(v)
        hbSizeX = v; hbSize = Vector3.new(hbSizeX, hbSizeY, hbSizeX)
        if hbEnabled then for _, m in pairs(validcharacters) do applyHitbox(m) end end
    end)
    HBGroup:AddSlider('HB_SizeY', { Text = 'Size Y', Default = 10, Min = 1, Max = 100, Rounding = 0 })
    Options.HB_SizeY:OnChanged(function(v)
        hbSizeY = v; hbSize = Vector3.new(hbSizeX, hbSizeY, hbSizeX)
        if hbEnabled then for _, m in pairs(validcharacters) do applyHitbox(m) end end
    end)
end
-- ══════════════════════════════════════════════════════════════════════════════
--  MAGIC BULLET  (hookfunction CreateProjectile method)
-- ══════════════════════════════════════════════════════════════════════════════

do
    local MB_enabled  = false
    local MB_fov      = 150
    local MB_target   = nil
    local MB_predicted = Vector3.zero
    local MB_connection = nil

    local RS   = game:GetService("ReplicatedStorage")
    local cam  = workspace.CurrentCamera

    -- берём классы из _G
    local classes = getrenv()._G.classes

    -- список игроков из upvalue updatePlayers
    local loaded_players = nil
    local entity_list    = nil

    for _, v in pairs(getgc(true)) do
        if type(v) == "function" and not iscclosure(v) then
            local src = debug.info(v, "s")
            if debug.info(v, "n") == "updatePlayers" and src and src:match("PlayerClient") then
                loaded_players = debug.getupvalue(v, 1)
            end
        end
        if loaded_players then break end
    end

    pcall(function()
        entity_list = debug.getupvalue(classes.EntityClient.GetEntityFromPart, 1)
    end)

    -- предсказание с учётом velocity таргета
    local function prediction(origin, target_pos, speed, drop, target_data)
        if not origin or not target_pos then return nil end
        local dist = (target_pos - origin).Magnitude
        local t    = dist / speed
        local up   = CFrame.new(origin, target_pos).UpVector
        local vel  = (target_data and typeof(target_data.velocityVector) == "Vector3")
                     and target_data.velocityVector or Vector3.zero
        local predicted = target_pos + vel * t
        local arc = (drop ^ (t * drop)) - 1
        return predicted + up * arc
    end

    -- поиск ближайшего к центру экрана
    local function get_target()
        local center = cam.ViewportSize * 0.5
        local closest, best = nil, math.huge

        -- игроки
        if loaded_players then
            for _, ent in next, loaded_players do
                if ent and ent.model then
                    local head = ent.model:FindFirstChild("Head")
                    if head then
                        local sp, onScreen = cam:WorldToViewportPoint(head.Position)
                        if onScreen and sp.Z > 0 then
                            local dist = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                            if dist <= MB_fov and dist < best then
                                best    = dist
                                closest = ent
                            end
                        end
                    end
                end
            end
        end

        -- нпс
        if entity_list then
            local NPC_TYPES = {"LabWorker","GasMaskSoldier","Soldier","Ghoul","General","Merchant","Officer","Vlad"}
            for _, ent in next, entity_list do
                local t = rawget(ent, "type")
                if t and table.find(NPC_TYPES, t) and ent.model then
                    local head = ent.model:FindFirstChild("Head")
                    if head then
                        local sp, onScreen = cam:WorldToViewportPoint(head.Position)
                        if onScreen and sp.Z > 0 then
                            local dist = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                            if dist <= MB_fov and dist < best then
                                best    = dist
                                closest = ent
                            end
                        end
                    end
                end
            end
        end

        MB_target = closest
    end

    -- хук на CreateProjectile
    local orig_create
    orig_create = hookfunction(classes.RangedWeaponClient.CreateProjectile, function(fire_cframe, weapon_data, is_server, ignore_instance, override_drop)
        if not MB_enabled or not MB_target or not MB_target.model then
            return orig_create(fire_cframe, weapon_data, is_server, ignore_instance, override_drop)
        end

        local head = MB_target.model:FindFirstChild("Head")
        if not head then
            return orig_create(fire_cframe, weapon_data, is_server, ignore_instance, override_drop)
        end

        local pred = prediction(
            fire_cframe.Position,
            head.Position,
            weapon_data.ProjectileSpeed,
            weapon_data.ProjectileDrop,
            MB_target
        )
        if not pred then
            return orig_create(fire_cframe, weapon_data, is_server, ignore_instance, override_drop)
        end

        MB_predicted = pred
        local silent_cf = CFrame.new(fire_cframe.Position, pred)

        -- если уже летит снаряд — не дублируем
        if MB_connection and MB_connection.Connected then return end

        local speed  = weapon_data.ProjectileSpeed
        local drop   = override_drop or weapon_data.ProjectileDrop
        local sendCode = (classes.SendCodes and classes.SendCodes.INV_USE_ITEM) or 10

        -- трейсер
        local tracer = nil
        pcall(function()
            local src = (weapon_data.type == "Bow" or weapon_data.type == "Crossbow")
                        and RS:FindFirstChild("Arrow") or RS:FindFirstChild("Bullet")
            if src then
                tracer = src:Clone()
                if tracer:FindFirstChild("whiz") then tracer.whiz:Play() end
                tracer.Parent = workspace.Const.Ignore
                tracer.CFrame = silent_cf
            end
        end)

        -- отправляем Fire
        if is_server then
            local pellets = 1
            if weapon_data.type == "PumpShotgun" or weapon_data.type == "Blunderbuss" then
                local multi = {}
                for i = 1, 5 do multi[i] = { silent_cf, i } end
                classes.NetClient.SendTCP(sendCode, "MultiFire", multi)
                pellets = 5
            else
                classes.NetClient.SendTCP(sendCode, "Fire", 1, silent_cf)
            end

            local t_elapsed = 0
            local cur_pos   = silent_cf.Position
            local hit_done  = false

            local rayParams = RaycastParams.new()
            rayParams.FilterDescendantsInstances = { workspace.Const.Ignore, ignore_instance }
            rayParams.FilterType = Enum.RaycastFilterType.Exclude
            rayParams.CollisionGroup = "WeaponRaycast"

            MB_connection = RunService.RenderStepped:Connect(function(dt)
                if hit_done then
                    MB_connection:Disconnect()
                    MB_connection = nil
                    if tracer then pcall(function() tracer:Destroy() end) end
                    return
                end

                t_elapsed = t_elapsed + dt
                local next_t   = t_elapsed + 0.025
                local prev_pos = cur_pos
                cur_pos = (silent_cf * CFrame.new(0, -(drop ^ (t_elapsed * drop)) + 1, -t_elapsed * speed)).Position

                if tracer then
                    pcall(function()
                        tracer.CFrame = CFrame.new(cur_pos,
                            (silent_cf * CFrame.new(0, -(drop ^ (next_t * drop)) + 1, -next_t * speed)).Position)
                    end)
                end

                local result = workspace:Raycast(prev_pos, cur_pos - prev_pos, rayParams)
                if result then
                    t_elapsed = t_elapsed - ((cur_pos - prev_pos).Magnitude - result.Distance) / speed
                    pcall(function()
                        local ent = classes.EntityClient.GetEntityFromPart(MB_target.model.Head)
                        for _ = 1, pellets do
                            classes.NetClient.SendTCP(sendCode, "Hit", 1, t_elapsed, ent.id, "Head", Vector3.zero, result.Position)
                        end
                        classes.Sound.Play("Dink")
                        classes.Sound.Play("PlayerHitHeadshot")
                    end)
                    hit_done = true
                elseif t_elapsed >= 3 then
                    MB_connection:Disconnect()
                    MB_connection = nil
                    if tracer then pcall(function() tracer:Destroy() end) end
                end
            end)
        else
            -- не наш выстрел — тихо перенаправляем
            return orig_create(silent_cf, weapon_data, is_server, ignore_instance, override_drop)
        end
    end)

    -- drawings
    local fovCircle = Drawing.new("Circle")
    fovCircle.Filled   = false
    fovCircle.NumSides = 64
    fovCircle.Thickness = 1
    fovCircle.Visible  = false

    local snapLine = Drawing.new("Line")
    snapLine.Thickness = 1
    snapLine.Visible   = false

    RunService.RenderStepped:Connect(function()
        local center = cam.ViewportSize * 0.5

        -- FOV
        if MB_enabled and Toggles.MB_ShowFOV.Value then
            fovCircle.Visible  = true
            fovCircle.Position = center
            fovCircle.Radius   = MB_fov
            fovCircle.Color    = Library.AccentColor
        else
            fovCircle.Visible = false
        end

        if not MB_enabled then
            snapLine.Visible = false
            MB_target = nil
            return
        end

        get_target()

        -- snapline
        if Toggles.MB_Snapline.Value and MB_target and MB_target.model then
            local head = MB_target.model:FindFirstChild("Head")
            if head then
                local sp, onScreen = cam:WorldToViewportPoint(head.Position)
                if onScreen then
                    snapLine.Visible = true
                    snapLine.From    = center
                    snapLine.To      = Vector2.new(sp.X, sp.Y)
                    snapLine.Color   = Library.AccentColor
                else
                    snapLine.Visible = false
                end
            end
        else
            snapLine.Visible = false
        end
    end)

    local MBGroup = Tabs.Combat:AddLeftGroupbox('Magic Bullet')
    MBGroup:AddToggle('MB_Enabled',  { Text = 'Enable Magic Bullet', Default = false })
    Toggles.MB_Enabled:OnChanged(function(v)
        MB_enabled = v
        if not v then
            fovCircle.Visible = false
            snapLine.Visible  = false
            MB_target = nil
        end
    end)
    MBGroup:AddToggle('MB_ShowFOV',  { Text = 'Show FOV Circle', Default = true })
    MBGroup:AddToggle('MB_Snapline', { Text = 'Snapline',        Default = true })
    MBGroup:AddSlider('MB_FOV', { Text = 'FOV', Default = 150, Min = 10, Max = 500, Rounding = 0 })
    Options.MB_FOV:OnChanged(function(v) MB_fov = v end)
    MBGroup:AddLabel('Head | Players + NPCs')
end
-- ══════════════════════════════════════════════════════════════════════════════
--  CAMERA  (stretch + FOV lock + zoom)
-- ══════════════════════════════════════════════════════════════════════════════

do
    local stretchEnabled = false
    local stretchValue   = 0.65
    local fovLockEnabled = false
    local targetFOV      = 120
    local zoomEnabled    = false
    local originalFOV    = Camera.FieldOfView

    local CameraSection = Tabs.Misc:AddLeftGroupbox('Camera')
    CameraSection:AddToggle('CAM_Stretch', { Text = 'Stretch', Default = false })
    Toggles.CAM_Stretch:OnChanged(function(v) stretchEnabled = v end)
    CameraSection:AddSlider('CAM_StretchVal', { Text = 'Stretch %', Default = 65, Min = 30, Max = 100, Rounding = 0 })
    Options.CAM_StretchVal:OnChanged(function(v) stretchValue = v / 100 end)
    CameraSection:AddDivider()
    CameraSection:AddToggle('CAM_FOVLock', { Text = 'FOV Lock', Default = false })
    Toggles.CAM_FOVLock:OnChanged(function(v)
        fovLockEnabled = v
        if not v and not zoomEnabled then Camera.FieldOfView = originalFOV end
    end)
    CameraSection:AddSlider('CAM_FOV', { Text = 'FOV Value', Default = 120, Min = 50, Max = 120, Rounding = 0 })
    Options.CAM_FOV:OnChanged(function(v) targetFOV = v end)
    CameraSection:AddDivider()
    CameraSection:AddToggle('CAM_Zoom', { Text = 'Scope Zoom', Default = false })
    Toggles.CAM_Zoom:OnChanged(function(v) zoomEnabled = v end)

    pcall(function()
        local _fovHook
        _fovHook = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if (fovLockEnabled or zoomEnabled) and self == Camera and not checkcaller() then
                if method == "Interpolate" then return nil end
            end
            return _fovHook(self, ...)
        end))
    end)

    Camera:GetPropertyChangedSignal("FieldOfView"):Connect(function()
        local effective = zoomEnabled and 30 or targetFOV
        if (fovLockEnabled or zoomEnabled) and Camera.FieldOfView ~= effective then
            Camera.FieldOfView = effective
        end
    end)

    RunService:BindToRenderStep("ScytheCameraUpdate", Enum.RenderPriority.Camera.Value + 1, function()
        if not Camera then return end
        if stretchEnabled then
            local cf = Camera.CFrame
            Camera.CFrame = CFrame.fromMatrix(cf.Position, cf.RightVector, cf.UpVector * stretchValue, -cf.LookVector)
        end
        local effective = zoomEnabled and 30 or targetFOV
        if (fovLockEnabled or zoomEnabled) and Camera.FieldOfView ~= effective then
            Camera.FieldOfView = effective
        end
    end)
end
-- ══════════════════════════════════════════════════════════════════════════════
--  WORLD TWEAKS  (Clouds, Grass, Tree Leaves, Skybox)
-- ══════════════════════════════════════════════════════════════════════════════

do
    local WorldGroup = Tabs.World:AddLeftGroupbox('World Tweaks')

    WorldGroup:AddToggle('WORLD_NoClouds', { Text = 'No Clouds', Default = false })
    Toggles.WORLD_NoClouds:OnChanged(function(v)
        pcall(function()
            local clouds = Workspace.Terrain:FindFirstChildOfClass("Clouds")
            if clouds then clouds.Enabled = not v end
        end)
    end)

    WorldGroup:AddToggle('WORLD_Grass', { Text = 'Terrain Grass', Default = true })
    Toggles.WORLD_Grass:OnChanged(function(v)
        pcall(function()
            if sethiddenproperty then
                sethiddenproperty(Workspace.Terrain, "Decoration", v)
            end
        end)
    end)

    local LeafNames = { "Fir3_Leaves", "Elm1_Leaves", "Birch1_Leaves" }
    WorldGroup:AddToggle('WORLD_TreeLeaves', { Text = 'Tree Leaves', Default = true })
    Toggles.WORLD_TreeLeaves:OnChanged(function(v)
        task.spawn(function()
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("BasePart") and table.find(LeafNames, obj.Name) then
                    obj.Transparency = v and 0 or 1
                    obj.CanCollide   = v
                end
            end
        end)
    end)

    WorldGroup:AddDivider()

    local Skyboxes = {
        ["None"]          = nil,
        ["Nebula Black"]  = { Bk="171410628",  Dn="171410649",  Ft="171410620",  Lf="171410666",  Rt="171410657",  Up="171410636"  },
        ["Nebula Orange"] = { Bk="171560994",  Dn="171561019",  Ft="171560968",  Lf="171561065",  Rt="171561026",  Up="171561009"  },
        ["Purple Space"]  = { Bk="159454299",  Dn="159454296",  Ft="159454293",  Lf="159454286",  Rt="159454300",  Up="159454288"  },
        ["Rainbow"]       = { Bk="16573631102",Dn="16573631950",Ft="16573632795",Lf="16573633258",Rt="16573633908",Up="16573634370" },
        ["Aurora"]        = { Bk="340908398",  Dn="340908450",  Ft="340908468",  Lf="340908504",  Rt="340908530",  Up="340908586"  },
    }

    local function applySkybox(data)
        local sky = Lighting:FindFirstChildOfClass("Sky")
        if not sky then sky = Instance.new("Sky"); sky.Parent = Lighting end
        for side, id in pairs(data) do sky["Skybox" .. side] = "rbxassetid://" .. id end
    end

    WorldGroup:AddDropdown('WORLD_Skybox', {
        Text   = 'Skybox',
        Values = { 'None', 'Nebula Black', 'Nebula Orange', 'Purple Space', 'Rainbow', 'Aurora' },
        Default = 1,
    })
    Options.WORLD_Skybox:OnChanged(function(v)
        if Skyboxes[v] then applySkybox(Skyboxes[v]) end
    end)

    WorldGroup:AddDivider()

    WorldGroup:AddToggle('WORLD_DeleteWalls', { Text = 'Delete Walls (click)', Default = false })
    local wallNames = { "Hitbox", "LeftWall", "RightWall", "LeftHinge", "RightHinge", "Prim" }
    Mouse.Button1Down:Connect(function()
        if not Toggles.WORLD_DeleteWalls.Value then return end
        local target = Mouse.Target
        if target and table.find(wallNames, target.Name) then
            target:Destroy()
        end
    end)
end
-- ══════════════════════════════════════════════════════════════════════════════
--  HIT SOUNDS
-- ══════════════════════════════════════════════════════════════════════════════

do
    local HitSounds = {
        Default    = "9119561046",
        Rust       = "5043539486",
        Gamesense  = "4817809188",
        Magic      = "182765513",
        Firework   = "269146157",
        Lazer      = "360661189",
        Zap        = "9119594928",
        Neverlose  = "18391691942",
    }
    local hitSoundVolume = 1.0

    local HitSoundGroup = Tabs.Visuals:AddRightGroupbox('Hit Sounds')
    HitSoundGroup:AddDropdown('HS_Sound', {
        Text   = 'Hit Sound',
        Values = { 'Default', 'Rust', 'Gamesense', 'Magic', 'Firework', 'Lazer', 'Zap', 'Neverlose' },
        Default = 1,
    })
    Options.HS_Sound:OnChanged(function(v)
        pcall(function()
            local hs = SoundService:FindFirstChild("PlayerHitHeadshot")
            if hs then hs.SoundId = "rbxassetid://" .. (HitSounds[v] or HitSounds.Default) end
        end)
    end)
    HitSoundGroup:AddSlider('HS_Volume', { Text = 'Volume', Default = 10, Min = 0, Max = 10, Rounding = 0 })
    Options.HS_Volume:OnChanged(function(v)
        hitSoundVolume = v / 10
        pcall(function()
            local hs = SoundService:FindFirstChild("PlayerHitHeadshot")
            if hs then hs.Volume = hitSoundVolume end
        end)
    end)
end
-- ══════════════════════════════════════════════════════════════════════════════
--  CUSTOM TRAIL COLOR  (arrows + bullets)
-- ══════════════════════════════════════════════════════════════════════════════

do
    local trailEnabled = false
    local trailColor   = Color3.fromRGB(0, 255, 255)
    local activeBulletConns = {}

    local function applyToArrow(arrow)
        for _, child in ipairs(arrow:GetDescendants()) do
            if child:IsA("Trail") then
                child.Color        = ColorSequence.new(trailColor)
                child.Lifetime     = 0.4
                child.LightEmission = 1
                child.Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(0.6, 0.5),
                    NumberSequenceKeypoint.new(1, 1),
                })
            end
        end
    end

    local function createBulletTracer(bullet)
        if not trailEnabled then return end
        local points = {}
        local conn
        conn = RunService.RenderStepped:Connect(function()
            if not bullet or not bullet.Parent then
                conn:Disconnect(); activeBulletConns[bullet] = nil; return
            end
            local pos = bullet.Position or bullet.CFrame.Position
            table.insert(points, 1, pos)
            if #points > 10 then table.remove(points) end
            for i = 1, #points - 1 do
                local p1, p2 = points[i], points[i + 1]
                local part = Instance.new("Part")
                part.Anchored    = true
                part.CanCollide  = false
                part.Size        = Vector3.new(0.2, 0.2, (p1 - p2).Magnitude)
                part.CFrame      = CFrame.new(p1, p2) * CFrame.new(0, 0, -part.Size.Z / 2)
                part.Color       = trailColor
                part.Material    = Enum.Material.Neon
                part.Parent      = Workspace
                Debris:AddItem(part, 0.1)
            end
        end)
        activeBulletConns[bullet] = conn
    end

    local function updateAllArrows()
        if not trailEnabled then return end
        local ok, arrowTemplate = pcall(function() return ReplicatedStorage:FindFirstChild("Arrow") end)
        if ok and arrowTemplate then applyToArrow(arrowTemplate) end
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj.Name == "Arrow" then applyToArrow(obj) end
        end
    end

    Workspace.ChildAdded:Connect(function(child)
        if not trailEnabled then return end
        if child.Name == "Arrow" then task.wait(0.05); applyToArrow(child)
        elseif child.Name == "Bullet" and not child:IsDescendantOf(ReplicatedStorage) then
            createBulletTracer(child)
        end
    end)
    Workspace.ChildRemoved:Connect(function(child)
        if child.Name == "Bullet" and activeBulletConns[child] then
            activeBulletConns[child]:Disconnect(); activeBulletConns[child] = nil
        end
    end)

    local TrailGroup = Tabs.Visuals:AddRightGroupbox('Trail Color')
    TrailGroup:AddToggle('TRAIL_Enabled', { Text = 'Custom Trail Color', Default = false })
    Toggles.TRAIL_Enabled:OnChanged(function(v)
        trailEnabled = v
        if v then updateAllArrows()
        else for _, conn in pairs(activeBulletConns) do conn:Disconnect() end; activeBulletConns = {} end
    end)
    TrailGroup:AddLabel('Trail Color'):AddColorPicker('TRAIL_Color', { Default = Color3.fromRGB(0, 255, 255) })
    Options.TRAIL_Color:OnChanged(function(v)
        trailColor = v
        if trailEnabled then updateAllArrows() end
    end)
end
-- ══════════════════════════════════════════════════════════════════════════════
--  WEAPON VISUALS  (material & color for HandModels in ReplicatedStorage)
-- ══════════════════════════════════════════════════════════════════════════════

do
    local weaponParts    = {}
    local weaponOrigMats = {}
    local weaponColor    = Color3.fromRGB(255, 255, 255)
    local currentMat     = "Default"

    local function refreshWeaponParts()
        weaponParts = {}
        local ok, HandModels = pcall(function() return ReplicatedStorage:WaitForChild("HandModels", 3) end)
        if not ok or not HandModels then return end
        local function scan(obj)
            if obj:IsA("BasePart") then
                table.insert(weaponParts, obj)
                weaponOrigMats[obj] = weaponOrigMats[obj] or obj.Material
            end
            for _, ch in ipairs(obj:GetChildren()) do scan(ch) end
        end
        for _, model in ipairs(HandModels:GetChildren()) do scan(model) end
    end

    local function applyWeaponMaterial(mat)
        currentMat = mat
        if mat == "Default" then
            for _, p in ipairs(weaponParts) do
                if p and p.Parent then p.Material = weaponOrigMats[p] or Enum.Material.Plastic end
            end
        else
            local ok, enumMat = pcall(function() return Enum.Material[mat] end)
            for _, p in ipairs(weaponParts) do
                if p and p.Parent then
                    if ok and enumMat then p.Material = enumMat end
                end
            end
        end
    end

    local function applyWeaponColor(c)
        weaponColor = c
        for _, p in ipairs(weaponParts) do
            if p and p.Parent then p.Color = c end
        end
    end

    task.spawn(refreshWeaponParts)

    local WepVisGroup = Tabs.Visuals:AddRightGroupbox('Weapon Visuals')
    WepVisGroup:AddDropdown('WEP_Material', {
        Text   = 'Material',
        Values = { 'Default', 'ForceField', 'Neon', 'Asphalt', 'Glass', 'SmoothPlastic' },
        Default = 1,
    })
    Options.WEP_Material:OnChanged(function(v)
        refreshWeaponParts(); applyWeaponMaterial(v)
    end)
    WepVisGroup:AddLabel('Weapon Color'):AddColorPicker('WEP_Color', { Default = Color3.fromRGB(255, 255, 255) })
    Options.WEP_Color:OnChanged(function(v) refreshWeaponParts(); applyWeaponColor(v) end)
    WepVisGroup:AddButton('Refresh', function() refreshWeaponParts(); applyWeaponMaterial(currentMat); applyWeaponColor(weaponColor) end)
end
-- ══════════════════════════════════════════════════════════════════════════════
--  HANDS COLOR  (FPS arms)
-- ══════════════════════════════════════════════════════════════════════════════

do
    local handsColor = Color3.fromRGB(255, 255, 255)

    local function applyHandsColor()
        pcall(function()
            local fpsArms = Workspace.Const.Ignore.FPSArms
            for _, p in ipairs(fpsArms:GetDescendants()) do
                if p:IsA("BasePart") then
                    p.Material    = Enum.Material.ForceField
                    p.Color       = handsColor
                    p.Transparency = 0
                end
            end
        end)
    end

    local HandsGroup = Tabs.Visuals:AddRightGroupbox('FPS Arms')
    HandsGroup:AddLabel('Hands Color'):AddColorPicker('HANDS_Color', { Default = Color3.fromRGB(255, 255, 255) })
    Options.HANDS_Color:OnChanged(function(v) handsColor = v; applyHandsColor() end)
    HandsGroup:AddButton('Apply Hands Color', function() applyHandsColor() end)

    HandsGroup:AddToggle('HANDS_HideTorso', { Text = 'Hide Torso / HRP', Default = false })
    Toggles.HANDS_HideTorso:OnChanged(function(v)
        pcall(function()
            local fpsArms = Workspace.Const.Ignore.FPSArms
            local function setTransp(obj, t)
                if not obj then return end
                if obj:IsA("BasePart") then obj.Transparency = t end
                for _, child in ipairs(obj:GetChildren()) do setTransp(child, t) end
            end
            setTransp(fpsArms:FindFirstChild("Torso"),              v and 1 or 0)
            setTransp(fpsArms:FindFirstChild("HumanoidRootPart"),   v and 1 or 0)
        end)
    end)
end
-- ══════════════════════════════════════════════════════════════════════════════
--  X-RAY  (make Hitbox parts transparent)
-- ══════════════════════════════════════════════════════════════════════════════

do
    local xrayActive       = false
    local xrayTransparency = 0.5

    local function applyXRay()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj.Name == "Hitbox" and obj:IsA("BasePart") then
                obj.Transparency = xrayActive and xrayTransparency or 0
            end
        end
    end

    local XRayGroup = Tabs.Visuals:AddRightGroupbox('X-Ray')
    XRayGroup:AddToggle('XRAY_Enabled', { Text = 'X-Ray (Hitbox)',   Default = false })
    Toggles.XRAY_Enabled:OnChanged(function(v) xrayActive = v; applyXRay() end)
    XRayGroup:AddSlider('XRAY_Transparency', { Text = 'Transparency', Default = 5, Min = 0, Max = 10, Rounding = 0 })
    Options.XRAY_Transparency:OnChanged(function(v)
        xrayTransparency = v / 10
        if xrayActive then applyXRay() end
    end)
end
-- ══════════════════════════════════════════════════════════════════════════════
--  ORE ESP
-- ══════════════════════════════════════════════════════════════════════════════

do
    local ORE_Stone   = false
    local ORE_Iron    = false
    local ORE_Nitrate = false
    local ORE_Dist    = false
    local ORE_Range   = 750
    local oreESPData  = {}

    local oreColors = {
        Stone   = Color3.fromRGB(120, 120, 120),
        Iron    = Color3.fromRGB(255, 215, 0),
        Nitrate = Color3.fromRGB(200, 255, 200),
    }

    local oreRefColors = {
        Stone   = { Color3.fromRGB(72,  72,  72) },
        Iron    = { Color3.fromRGB(72,  72,  72),  Color3.fromRGB(199, 172, 120) },
        Nitrate = { Color3.fromRGB(248, 248, 248), Color3.fromRGB(72,  72,  72) },
    }

    local function colorClose(a, b)
        return math.abs(a.R - b.R) < 0.02 and math.abs(a.G - b.G) < 0.02 and math.abs(a.B - b.B) < 0.02
    end

    local function identifyOre(model)
        local meshes = {}
        for _, c in ipairs(model:GetChildren()) do
            if c:IsA("MeshPart") then table.insert(meshes, c) end
        end
        if #meshes == 1 then
            if colorClose(meshes[1].Color, oreRefColors.Stone[1]) then return "Stone", meshes[1] end
        elseif #meshes == 2 then
            local c1, c2 = meshes[1].Color, meshes[2].Color
            if (colorClose(c1, oreRefColors.Iron[1]) and colorClose(c2, oreRefColors.Iron[2]))
            or (colorClose(c1, oreRefColors.Iron[2]) and colorClose(c2, oreRefColors.Iron[1])) then
                return "Iron", meshes[1]
            end
            if (colorClose(c1, oreRefColors.Nitrate[1]) and colorClose(c2, oreRefColors.Nitrate[2]))
            or (colorClose(c1, oreRefColors.Nitrate[2]) and colorClose(c2, oreRefColors.Nitrate[1])) then
                return "Nitrate", meshes[1]
            end
        end
        return nil
    end

    local function oreEnabled(t)
        return (t == "Stone" and ORE_Stone) or (t == "Iron" and ORE_Iron) or (t == "Nitrate" and ORE_Nitrate)
    end

    task.spawn(function()
        while true do
            for _, m in ipairs(Workspace:GetChildren()) do
                if m:IsA("Model") and not oreESPData[m] then
                    local otype, part = identifyOre(m)
                    if otype then
                        local d = Drawing.new("Text")
                        d.Size    = 16
                        d.Center  = true
                        d.Outline = true
                        d.Color   = oreColors[otype]
                        d.Visible = false
                        oreESPData[m] = { draw = d, otype = otype, part = part }
                    end
                end
            end
            for m in pairs(oreESPData) do
                if not m.Parent then
                    oreESPData[m].draw:Remove()
                    oreESPData[m] = nil
                end
            end
            task.wait(2)
        end
    end)

    RunService.RenderStepped:Connect(function()
        for _, data in pairs(oreESPData) do
            local p = data.part
            if p and p.Parent and oreEnabled(data.otype) then
                local dist = (Camera.CFrame.Position - p.Position).Magnitude
                local sp, vis = Camera:WorldToViewportPoint(p.Position)
                if vis and dist <= ORE_Range then
                    data.draw.Text     = ORE_Dist and string.format("%s | %.0fm", data.otype, dist) or data.otype
                    data.draw.Position = Vector2.new(sp.X, sp.Y)
                    data.draw.Visible  = true
                else
                    data.draw.Visible = false
                end
            else
                data.draw.Visible = false
            end
        end
    end)

    local OreGroup = Tabs.Visuals:AddLeftGroupbox('Ore ESP')
    OreGroup:AddToggle('ORE_Stone',   { Text = 'Stone',    Default = false }); Toggles.ORE_Stone:OnChanged(function(v)   ORE_Stone   = v end)
    OreGroup:AddToggle('ORE_Iron',    { Text = 'Iron',     Default = false }); Toggles.ORE_Iron:OnChanged(function(v)    ORE_Iron    = v end)
    OreGroup:AddToggle('ORE_Nitrate', { Text = 'Nitrate',  Default = false }); Toggles.ORE_Nitrate:OnChanged(function(v) ORE_Nitrate = v end)
    OreGroup:AddToggle('ORE_Dist',    { Text = 'Distance', Default = false }); Toggles.ORE_Dist:OnChanged(function(v)    ORE_Dist    = v end)
    OreGroup:AddSlider('ORE_Range',   { Text = 'Range', Default = 750, Min = 50, Max = 2000, Rounding = 0 })
    Options.ORE_Range:OnChanged(function(v) ORE_Range = v end)
end
