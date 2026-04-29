-- SaveManager for Scythe Library
-- Compatible with Linoria SaveManager API

local httpService = game:GetService('HttpService')

local SaveManager = {} do
    SaveManager.Folder = 'ScytheSettings'
    SaveManager.Ignore = {}
    SaveManager.Parser = {
        Toggle = {
            Save = function(idx, object)
                return { type='Toggle', idx=idx, value=object.Value }
            end,
            Load = function(idx, data)
                if Toggles[idx] then Toggles[idx]:SetValue(data.value) end
            end,
        },
        Slider = {
            Save = function(idx, object)
                return { type='Slider', idx=idx, value=tostring(object.Value) }
            end,
            Load = function(idx, data)
                if Options[idx] then Options[idx]:SetValue(data.value) end
            end,
        },
        Dropdown = {
            Save = function(idx, object)
                return { type='Dropdown', idx=idx, value=object.Value, mutli=object.Multi }
            end,
            Load = function(idx, data)
                if Options[idx] then Options[idx]:SetValue(data.value) end
            end,
        },
        ColorPicker = {
            Save = function(idx, object)
                return { type='ColorPicker', idx=idx, value=object.Value:ToHex(), transparency=object.Transparency }
            end,
            Load = function(idx, data)
                if Options[idx] then Options[idx]:SetValueRGB(Color3.fromHex(data.value), data.transparency) end
            end,
        },
        KeyPicker = {
            Save = function(idx, object)
                return { type='KeyPicker', idx=idx, mode=object.Mode, key=object.Value }
            end,
            Load = function(idx, data)
                if Options[idx] then Options[idx]:SetValue({data.key, data.mode}) end
            end,
        },
        Input = {
            Save = function(idx, object)
                return { type='Input', idx=idx, text=object.Value }
            end,
            Load = function(idx, data)
                if Options[idx] and type(data.text)=='string' then Options[idx]:SetValue(data.text) end
            end,
        },
    }

    function SaveManager:SetIgnoreIndexes(list)
        for _,key in next, list do self.Ignore[key]=true end
    end

    function SaveManager:SetFolder(folder)
        self.Folder=folder; self:BuildFolderTree()
    end

    function SaveManager:Save(name)
        if not name then return false,'no config selected' end
        local fullPath = self.Folder..'/settings/'..name..'.json'
        local data = { objects={} }

        for idx,toggle in next, Toggles do
            if self.Ignore[idx] then continue end
            table.insert(data.objects, self.Parser[toggle.Type].Save(idx,toggle))
        end
        for idx,option in next, Options do
            if not self.Parser[option.Type] then continue end
            if self.Ignore[idx] then continue end
            table.insert(data.objects, self.Parser[option.Type].Save(idx,option))
        end

        local ok,encoded = pcall(httpService.JSONEncode, httpService, data)
        if not ok then return false,'encode failed' end
        writefile(fullPath, encoded)
        return true
    end

    function SaveManager:Load(name)
        if not name then return false,'no config selected' end
        local file = self.Folder..'/settings/'..name..'.json'
        if not isfile(file) then return false,'file not found' end
        local ok,decoded = pcall(httpService.JSONDecode, httpService, readfile(file))
        if not ok then return false,'decode error' end
        for _,option in next, decoded.objects do
            if self.Parser[option.type] then
                task.spawn(function() self.Parser[option.type].Load(option.idx, option) end)
            end
        end
        return true
    end

    function SaveManager:IgnoreThemeSettings()
        self:SetIgnoreIndexes({
            'BackgroundColor','MainColor','AccentColor','OutlineColor','FontColor',
            'ThemeManager_ThemeList','ThemeManager_CustomThemeList','ThemeManager_CustomThemeName',
        })
    end

    function SaveManager:BuildFolderTree()
        for _,path in next, { self.Folder, self.Folder..'/themes', self.Folder..'/settings' } do
            if not isfolder(path) then makefolder(path) end
        end
    end

    function SaveManager:RefreshConfigList()
        local list = listfiles(self.Folder..'/settings')
        local out  = {}
        for i=1,#list do
            local file = list[i]
            if file:sub(-5)=='.json' then
                local pos   = file:find('.json',1,true)
                local start = pos
                local char  = file:sub(pos,pos)
                while char~='/' and char~='\\' and char~='' do
                    pos=pos-1; char=file:sub(pos,pos)
                end
                if char=='/' or char=='\\' then
                    table.insert(out, file:sub(pos+1,start-1))
                end
            end
        end
        return out
    end

    function SaveManager:SetLibrary(library)
        self.Library = library
    end

    function SaveManager:LoadAutoloadConfig()
        local path = self.Folder..'/settings/autoload.txt'
        if isfile(path) then
            local name = readfile(path)
            local ok,err = self:Load(name)
            if not ok then
                return self.Library:Notify('Autoload failed: '..err, 3)
            end
            self.Library:Notify(string.format('Auto loaded %q', name))
        end
    end

    function SaveManager:BuildConfigSection(tab)
        assert(self.Library,'Must set SaveManager.Library')

        local section = tab:AddRightGroupbox('Configuration')

        section:AddInput('SaveManager_ConfigName', { Text='Config name' })
        section:AddDropdown('SaveManager_ConfigList', { Text='Config list', Values=self:RefreshConfigList(), AllowNull=true })
        section:AddDivider()

        section:AddButton('Create config', function()
            local name = Options.SaveManager_ConfigName.Value
            if name:gsub(' ','')== '' then return self.Library:Notify('Invalid name (empty)', 2) end
            local ok,err = self:Save(name)
            if not ok then return self.Library:Notify('Save failed: '..err) end
            self.Library:Notify(string.format('Created %q', name))
            Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
            Options.SaveManager_ConfigList:SetValue(nil)
        end):AddButton('Load config', function()
            local name = Options.SaveManager_ConfigList.Value
            local ok,err = self:Load(name)
            if not ok then return self.Library:Notify('Load failed: '..err) end
            self.Library:Notify(string.format('Loaded %q', name))
        end)

        section:AddButton('Overwrite config', function()
            local name = Options.SaveManager_ConfigList.Value
            local ok,err = self:Save(name)
            if not ok then return self.Library:Notify('Overwrite failed: '..err) end
            self.Library:Notify(string.format('Overwrote %q', name))
        end)

        section:AddButton('Refresh list', function()
            Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
            Options.SaveManager_ConfigList:SetValue(nil)
        end)

        section:AddButton('Set autoload', function()
            local name = Options.SaveManager_ConfigList.Value
            writefile(self.Folder..'/settings/autoload.txt', name)
            SaveManager.AutoloadLabel:SetText('Autoload: '..name)
            self.Library:Notify(string.format('Set autoload to %q', name))
        end)

        SaveManager.AutoloadLabel = section:AddLabel('Autoload: none', true)

        local autopath = self.Folder..'/settings/autoload.txt'
        if isfile(autopath) then
            SaveManager.AutoloadLabel:SetText('Autoload: '..readfile(autopath))
        end

        SaveManager:SetIgnoreIndexes({'SaveManager_ConfigList','SaveManager_ConfigName'})
    end

    SaveManager:BuildFolderTree()
end

return SaveManager
