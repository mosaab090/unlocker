local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
local playerScripts = player.PlayerScripts
local controllers = playerScripts.Controllers

local EnumLibrary = require(ReplicatedStorage.Modules:WaitForChild("EnumLibrary", 10))
if EnumLibrary then EnumLibrary:WaitForEnumBuilder() end
    local CosmeticLibrary = require(ReplicatedStorage.Modules:WaitForChild("CosmeticLibrary", 10))
    local ItemLibrary = require(ReplicatedStorage.Modules:WaitForChild("ItemLibrary", 10))
    local DataController = require(controllers:WaitForChild("PlayerDataController", 10))
    
    local equipped, favorites = {}, {}
    local constructingWeapon, viewingProfile, lastUsedWeapon = nil, nil, nil
    
    local SAVE_FOLDER = "skin_changer_data"
    local SAVE_FILE = SAVE_FOLDER .. "/config.json"
    
    local UNLOCKED_TYPES = {
        Skin = true, Charm = true, Dance = true, Emote = true,
        Wrap = true, Wrapping = true, Finisher = true,
        Spray = true, PlayerCard = true, Title = true,
    }
    
    local function isUnlocked(cosmetic)
    return cosmetic and UNLOCKED_TYPES[cosmetic.Type]
    end
    
    local function cloneCosmetic(name, cosmeticType, options)
    local base = CosmeticLibrary.Cosmetics[name]
    if not base then return nil end
        local data = {}
        for k, v in pairs(base) do data[k] = v end
            data.Name = name
            data.Type = data.Type or cosmeticType
            data.Seed = data.Seed or math.random(1, 1000000)
            if EnumLibrary then
                local ok, id = pcall(EnumLibrary.ToEnum, EnumLibrary, name)
                if ok and id then data.Enum, data.ObjectID = id, data.ObjectID or id end
                    end
                    if options then
                        if options.inverted ~= nil then data.Inverted = options.inverted end
                            if options.favoritesOnly ~= nil then data.OnlyUseFavorites = options.favoritesOnly end
                                end
                                return data
                                end
                                
                                local function saveConfig()
                                if not writefile then return end
                                    pcall(function()
                                    local config = {equipped = {}, favorites = favorites}
                                    for weapon, cosmetics in pairs(equipped) do
                                        config.equipped[weapon] = {}
                                        for cType, cData in pairs(cosmetics) do
                                            if cData and cData.Name then
                                                config.equipped[weapon][cType] = {
                                                    name = cData.Name, seed = cData.Seed, inverted = cData.Inverted,
                                                }
                                                end
                                                end
                                                end
                                                makefolder(SAVE_FOLDER)
                                                writefile(SAVE_FILE, HttpService:JSONEncode(config))
                                                end)
                                    end
                                    
                                    local function loadConfig()
                                    if not readfile or not isfile or not isfile(SAVE_FILE) then return end
                                        pcall(function()
                                        local config = HttpService:JSONDecode(readfile(SAVE_FILE))
                                        if config.equipped then
                                            for weapon, cosmetics in pairs(config.equipped) do
                                                equipped[weapon] = {}
                                                for cType, cData in pairs(cosmetics) do
                                                    local cloned = cloneCosmetic(cData.name, cType, {inverted = cData.inverted})
                                                    if cloned then cloned.Seed = cData.seed; equipped[weapon][cType] = cloned end
                                                        end
                                                        end
                                                        end
                                                        favorites = config.favorites or {}
                                                        end)
                                        end
                                        
                                        -- ==== UNIFIED HOOKS (single layer, all types) ====
                                        
                                        -- OwnsCosmetic - return true for all unlocked types
                                        local origOwnsCosmetic = CosmeticLibrary.OwnsCosmetic
                                        CosmeticLibrary.OwnsCosmetic = function(self, inventory, name, weapon)
                                        if name:find("MISSING_") then return origOwnsCosmetic(self, inventory, name, weapon) end
                                            local c = CosmeticLibrary.Cosmetics[name]
                                            if c and isUnlocked(c) then return true end
                                                return origOwnsCosmetic(self, inventory, name, weapon)
                                                end
                                                
                                                CosmeticLibrary.OwnsCosmeticNormally = function(self, inventory, name, weapon)
                                                local c = CosmeticLibrary.Cosmetics[name]
                                                return c and isUnlocked(c) or false
                                                end
                                                
                                                CosmeticLibrary.OwnsCosmeticUniversally = function(self, inventory, name, weapon)
                                                local c = CosmeticLibrary.Cosmetics[name]
                                                return c and isUnlocked(c) or false
                                                end
                                                
                                                CosmeticLibrary.OwnsCosmeticForWeapon = function(self, inventory, name, weapon)
                                                local c = CosmeticLibrary.Cosmetics[name]
                                                return c and isUnlocked(c) or false
                                                end
                                                
                                                -- DataController.Get - inject all unlocked cosmetics into inventory
                                                local origDataGet = DataController.Get
                                                DataController.Get = function(self, key)
                                                local data = origDataGet(self, key)
                                                if key == "CosmeticInventory" then
                                                    local proxy = {}
                                                    if data then
                                                        for k, v in pairs(data) do
                                                            local c = CosmeticLibrary.Cosmetics[k]
                                                            if c and isUnlocked(c) then proxy[k] = v end
                                                                end
                                                                end
                                                                return setmetatable(proxy, {__index = function(t, k)
                                                                    local c = CosmeticLibrary.Cosmetics[k]
                                                                    return c and isUnlocked(c) and true or nil
                                                                    end})
                                                                end
                                                                if key == "FavoritedCosmetics" then
                                                                    local result = data and table.clone(data) or {}
                                                                    for weapon, favs in pairs(favorites) do
                                                                        result[weapon] = result[weapon] or {}
                                                                        for name, isFav in pairs(favs) do
                                                                            local c = CosmeticLibrary.Cosmetics[name]
                                                                            if c and isUnlocked(c) then result[weapon][name] = isFav end
                                                                                end
                                                                                end
                                                                                return result
                                                                                end
                                                                                return data
                                                                                end
                                                                                
                                                                                -- DataController.GetWeaponData - apply equipped cosmetics
                                                                                local origGetWeaponData = DataController.GetWeaponData
                                                                                DataController.GetWeaponData = function(self, weaponName)
                                                                                local data = origGetWeaponData(self, weaponName)
                                                                                if not data then return nil end
                                                                                    local merged = {}
                                                                                    for k, v in pairs(data) do merged[k] = v end
                                                                                        merged.Name = weaponName
                                                                                        if equipped[weaponName] then
                                                                                            for cType, cData in pairs(equipped[weaponName]) do
                                                                                                if UNLOCKED_TYPES[cType] then merged[cType] = cData end
                                                                                                    end
                                                                                                    end
                                                                                                    return merged
                                                                                                    end
                                                                                                    
                                                                                                    -- ViewModel image hook
                                                                                                    local origGetVMImage = ItemLibrary.GetViewModelImageFromWeaponData
                                                                                                    ItemLibrary.GetViewModelImageFromWeaponData = function(self, weaponData, highRes)
                                                                                                    if not weaponData then return origGetVMImage(self, weaponData, highRes) end
                                                                                                        local weaponName = weaponData.Name
                                                                                                        local shouldShow = (weaponData.Skin and equipped[weaponName] and weaponData.Skin == equipped[weaponName].Skin) or (viewingProfile == player and equipped[weaponName] and equipped[weaponName].Skin)
                                                                                                        if shouldShow and equipped[weaponName] and equipped[weaponName].Skin then
                                                                                                            local info = self.ViewModels[equipped[weaponName].Skin.Name]
                                                                                                            if info then return info[highRes and "ImageHighResolution" or "Image"] or info.Image end
                                                                                                                end
                                                                                                                return origGetVMImage(self, weaponData, highRes)
                                                                                                                end
                                                                                                                
                                                                                                                -- ==== REMOTE HOOK (single __namecall hook for all types) ====
                                                                                                                
                                                                                                                if hookmetamethod then
                                                                                                                    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                                                                                                                    local dataRemotes = remotes and remotes:FindFirstChild("Data")
                                                                                                                    local equipRemote = dataRemotes and dataRemotes:FindFirstChild("EquipCosmetic")
                                                                                                                    local favoriteRemote = dataRemotes and dataRemotes:FindFirstChild("FavoriteCosmetic")
                                                                                                                    local replicationRemotes = remotes and remotes:FindFirstChild("Replication")
                                                                                                                    local fighterRemotes = replicationRemotes and replicationRemotes:FindFirstChild("Fighter")
                                                                                                                    local useItemRemote = fighterRemotes and fighterRemotes:FindFirstChild("UseItem")
                                                                                                                    
                                                                                                                    local FighterController
                                                                                                                    pcall(function() FighterController = require(controllers:WaitForChild("FighterController", 10)) end)
                                                                                                                    
                                                                                                                    local oldNamecall
                                                                                                                    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
                                                                                                                    if getnamecallmethod() ~= "FireServer" then return oldNamecall(self, ...) end
                                                                                                                        local args = {...}
                                                                                                                        
                                                                                                                        if useItemRemote and self == useItemRemote and FighterController then
                                                                                                                            local objectID = args[1]
                                                                                                                            pcall(function()
                                                                                                                            local fighter = FighterController:GetFighter(player)
                                                                                                                            if fighter and fighter.Items then
                                                                                                                                for _, item in pairs(fighter.Items) do
                                                                                                                                    if item:Get("ObjectID") == objectID then lastUsedWeapon = item.Name; break end
                                                                                                                                        end
                                                                                                                                        end
                                                                                                                                        end)
                                                                                                                            end
                                                                                                                            
                                                                                                                            if self == equipRemote then
                                                                                                                                local weaponName, cosmeticType, cosmeticName, options = args[1], args[2], args[3], args[4] or {}
                                                                                                                                if not UNLOCKED_TYPES[cosmeticType] then return oldNamecall(self, ...) end
                                                                                                                                    
                                                                                                                                    if cosmeticName and cosmeticName ~= "None" and cosmeticName ~= "" then
                                                                                                                                        local inventory = DataController:Get("CosmeticInventory")
                                                                                                                                        if inventory and rawget(inventory, cosmeticName) then return oldNamecall(self, ...) end
                                                                                                                                            end
                                                                                                                                            
                                                                                                                                            -- Player-wide cosmetics (Dance, Emote, Spray, etc.)
                                                                                                                    if cosmeticType == "Dance" or cosmeticType == "Emote" or cosmeticType == "Spray" or cosmeticType == "PlayerCard" or cosmeticType == "Title" then
                                                                                                                        equipped.PlayerWide = equipped.PlayerWide or {}
                                                                                                                        if not cosmeticName or cosmeticName == "None" or cosmeticName == "" then
                                                                                                                            equipped.PlayerWide[cosmeticType] = nil
                                                                                                                            else
                                                                                                                                local cloned = cloneCosmetic(cosmeticName, cosmeticType, {inverted = options.IsInverted, favoritesOnly = options.OnlyUseFavorites})
                                                                                                                                if cloned then equipped.PlayerWide[cosmeticType] = cloned end
                                                                                                                                    end
                                                                                                                                    task.defer(function()
                                                                                                                                    pcall(function() DataController.CurrentData:Replicate("CosmeticInventory") end)
                                                                                                                                    task.wait(0.2)
                                                                                                                                    saveConfig()
                                                                                                                                    end)
                                                                                                                                    return
                                                                                                                                    end
                                                                                                                                    
                                                                                                                                    -- Weapon-specific cosmetics (Skin, Charm, Wrap, Finisher, etc.)
                                                                                                                    equipped[weaponName] = equipped[weaponName] or {}
                                                                                                                    if not cosmeticName or cosmeticName == "None" or cosmeticName == "" then
                                                                                                                        equipped[weaponName][cosmeticType] = nil
                                                                                                                        if not next(equipped[weaponName]) then equipped[weaponName] = nil end
                                                                                                                            else
                                                                                                                                local cloned = cloneCosmetic(cosmeticName, cosmeticType, {inverted = options.IsInverted, favoritesOnly = options.OnlyUseFavorites})
                                                                                                                                if cloned then equipped[weaponName][cosmeticType] = cloned end
                                                                                                                                    end
                                                                                                                                    task.defer(function()
                                                                                                                                    pcall(function() DataController.CurrentData:Replicate("WeaponInventory") end)
                                                                                                                                    task.wait(0.2)
                                                                                                                                    saveConfig()
                                                                                                                                    end)
                                                                                                                                    return
                                                                                                                                    end
                                                                                                                                    
                                                                                                                                    if self == favoriteRemote then
                                                                                                                                        local cosmetic = CosmeticLibrary.Cosmetics[args[2]]
                                                                                                                                        if cosmetic and isUnlocked(cosmetic) then
                                                                                                                                            favorites[args[1]] = favorites[args[1]] or {}
                                                                                                                                            favorites[args[1]][args[2]] = args[3] or nil
                                                                                                                                            saveConfig()
                                                                                                                                            task.spawn(function() pcall(function() DataController.CurrentData:Replicate("FavoritedCosmetics") end) end)
                                                                                                                                            end
                                                                                                                                            return
                                                                                                                                            end
                                                                                                                                            
                                                                                                                                            return oldNamecall(self, ...)
                                                                                                                                            end)
                                                                                                                    end
                                                                                                                    
                                                                                                                    -- ==== VIEWMODEL HOOKS ====
                                                                                                                    
                                                                                                                    local ClientItem
                                                                                                                    pcall(function() ClientItem = require(playerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem) end)
                                                                                                                    
                                                                                                                    if ClientItem and ClientItem._CreateViewModel then
                                                                                                                        local origCreateVM = ClientItem._CreateViewModel
                                                                                                                        ClientItem._CreateViewModel = function(self, viewmodelRef)
                                                                                                                        local weaponName = self.Name
                                                                                                                        local weaponPlayer = self.ClientFighter and self.ClientFighter.Player
                                                                                                                        constructingWeapon = (weaponPlayer == player) and weaponName or nil
                                                                                                                        
                                                                                                                        if weaponPlayer == player and equipped[weaponName] and viewmodelRef then
                                                                                                                            for _, cType in ipairs({"Skin", "Charm", "Wrap", "Wrapping", "Finisher"}) do
                                                                                                                                if equipped[weaponName][cType] then
                                                                                                                                    local dataKey, typeKey, nameKey = self:ToEnum("Data"), self:ToEnum(cType), self:ToEnum("Name")
                                                                                                                                    if viewmodelRef[dataKey] then
                                                                                                                                        viewmodelRef[dataKey][typeKey] = equipped[weaponName][cType]
                                                                                                                                        viewmodelRef[dataKey][nameKey] = equipped[weaponName][cType].Name
                                                                                                                                        elseif viewmodelRef.Data then
                                                                                                                                            viewmodelRef.Data[cType] = equipped[weaponName][cType]
                                                                                                                                            viewmodelRef.Data.Name = equipped[weaponName][cType].Name
                                                                                                                                            end
                                                                                                                                            end
                                                                                                                                            end
                                                                                                                                            end
                                                                                                                                            
                                                                                                                                            local result = origCreateVM(self, viewmodelRef)
                                                                                                                                            constructingWeapon = nil
                                                                                                                                            return result
                                                                                                                                            end
                                                                                                                                            end
                                                                                                                                            
                                                                                                                                            local viewModelModule = playerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem:FindFirstChild("ClientViewModel")
                                                                                                                                            if viewModelModule then
                                                                                                                                                local ClientViewModel = require(viewModelModule)
                                                                                                                                                
                                                                                                                                                if ClientViewModel.GetCharm then
                                                                                                                                                    local origGetCharm = ClientViewModel.GetCharm
                                                                                                                                                    ClientViewModel.GetCharm = function(self)
                                                                                                                                                    local wName = self.ClientItem and self.ClientItem.Name
                                                                                                                                                    local wPlayer = self.ClientItem and self.ClientItem.ClientFighter and self.ClientItem.ClientFighter.Player
                                                                                                                                                    if wName and wPlayer == player and equipped[wName] and equipped[wName].Charm then
                                                                                                                                                        return equipped[wName].Charm
                                                                                                                                                        end
                                                                                                                                                        return origGetCharm(self)
                                                                                                                                                        end
                                                                                                                                                        end
                                                                                                                                                        
                                                                                                                                                        if ClientViewModel.GetWrap then
                                                                                                                                                            local origGetWrap = ClientViewModel.GetWrap
                                                                                                                                                            ClientViewModel.GetWrap = function(self)
                                                                                                                                                            local wName = self.ClientItem and self.ClientItem.Name
                                                                                                                                                            local wPlayer = self.ClientItem and self.ClientItem.ClientFighter and self.ClientItem.ClientFighter.Player
                                                                                                                                                            if wName and wPlayer == player and equipped[wName] and equipped[wName].Wrap then
                                                                                                                                                                return equipped[wName].Wrap
                                                                                                                                                                end
                                                                                                                                                                return origGetWrap(self)
                                                                                                                                                                end
                                                                                                                                                                end
                                                                                                                                                                
                                                                                                                                                                local origNew = ClientViewModel.new
                                                                                                                                                                ClientViewModel.new = function(replicatedData, clientItem)
                                                                                                                                                                local wPlayer = clientItem.ClientFighter and clientItem.ClientFighter.Player
                                                                                                                                                                local wName = constructingWeapon or clientItem.Name
                                                                                                                                                                if wPlayer == player and equipped[wName] then
                                                                                                                                                                    local ReplicatedClass = require(ReplicatedStorage.Modules.ReplicatedClass)
                                                                                                                                                                    local dataKey = ReplicatedClass:ToEnum("Data")
                                                                                                                                                                    replicatedData[dataKey] = replicatedData[dataKey] or {}
                                                                                                                                                                    for _, cType in ipairs({"Skin", "Charm", "Wrap", "Wrapping", "Finisher"}) do
                                                                                                                                                                        if equipped[wName][cType] then
                                                                                                                                                                            replicatedData[dataKey][ReplicatedClass:ToEnum(cType)] = equipped[wName][cType]
                                                                                                                                                                            end
                                                                                                                                                                            end
                                                                                                                                                                            end
                                                                                                                                                                            local result = origNew(replicatedData, clientItem)
                                                                                                                                                                            if wPlayer == player and equipped[wName] and equipped[wName].Wrap and result._UpdateWrap then
                                                                                                                                                                                result:_UpdateWrap()
                                                                                                                                                                                task.delay(0.1, function() if not result._destroyed then result:_UpdateWrap() end end)
                                                                                                                                                                                end
                                                                                                                                                                                return result
                                                                                                                                                                                end
                                                                                                                                                                                end
                                                                                                                                                                                
                                                                                                                                                                                -- ==== EMOTE CONTROLLER HOOK ====
                                                                                                                                                                                
                                                                                                                                                                                local EmoteController
                                                                                                                                                                                pcall(function()
                                                                                                                                                                                EmoteController = require(controllers:WaitForChild("EmoteController", 10))
                                                                                                                                                                                if EmoteController and EmoteController.GetEmotes then
                                                                                                                                                                                    local origGetEmotes = EmoteController.GetEmotes
                                                                                                                                                                                    EmoteController.GetEmotes = function(self)
                                                                                                                                                                                    local emotes = origGetEmotes(self)
                                                                                                                                                                                    for name, cosmetic in pairs(CosmeticLibrary.Cosmetics) do
                                                                                                                                                                                        if cosmetic and (cosmetic.Type == "Dance" or cosmetic.Type == "Emote") then
                                                                                                                                                                                            if not emotes[name] then
                                                                                                                                                                                                emotes[name] = {Name = name, Type = cosmetic.Type, ObjectID = cosmetic.ObjectID, Enum = cosmetic.Enum}
                                                                                                                                                                                                end
                                                                                                                                                                                                end
                                                                                                                                                                                                end
                                                                                                                                                                                                return emotes
                                                                                                                                                                                                end
                                                                                                                                                                                                end
                                                                                                                                                                                                end)
                                                                                                                                                                                
                                                                                                                                                                                -- ==== VIEW PROFILE HOOK ====
                                                                                                                                                                                
                                                                                                                                                                                pcall(function()
                                                                                                                                                                                local ViewProfile = require(playerScripts.Modules.Pages.ViewProfile)
                                                                                                                                                                                if ViewProfile and ViewProfile.Fetch then
                                                                                                                                                                                    local origFetch = ViewProfile.Fetch
                                                                                                                                                                                    ViewProfile.Fetch = function(self, targetPlayer)
                                                                                                                                                                                    viewingProfile = targetPlayer
                                                                                                                                                                                    return origFetch(self, targetPlayer)
                                                                                                                                                                                    end
                                                                                                                                                                                    end
                                                                                                                                                                                    end)
                                                                                                                                                                                
                                                                                                                                                                                -- ==== INIT ====
                                                                                                                                                                                
                                                                                                                                                                                local NotificationLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/ScriptssForRoblox/Notifica/refs/heads/main/gold_lib.lua"))()
                                                                                                                                                                                if NotificationLib then
                                                                                                                                                                                    NotificationLib:Notify("UnlockAll", "Skins, Charms, Dances, Emotes, Wraps & Finishers desbloqueados!", 5)
                                                                                                                                                                                    end
                                                                                                                                                                                    
                                                                                                                                                                                    loadConfig()
                                                                                                                                                                                    
                                                                                                                                                                                    if NotificationLib then
                                                                                                                                                                                        NotificationLib:Notify("UnlockAll finalizado", "Script carregado com sucesso!", 3)
                                                                                                                                                                                        end
                                                                                                                                                                                        
                                                                                                                                                                                        return "UnlockAll loaded - All cosmetics (including Finishers & Emotes) unlocked!"
                                                                                                                                                                                        
