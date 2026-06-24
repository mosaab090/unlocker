-- REDZ UNLOCK ALL + FINISHERS + VISUALS (Merged)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")
local player = Players.LocalPlayer
local playerScripts = player.PlayerScripts
local controllers = playerScripts.Controllers
local EnumLibrary = require(ReplicatedStorage.Modules:WaitForChild("EnumLibrary", 10))
if EnumLibrary then EnumLibrary:WaitForEnumBuilder() end
local CosmeticLibrary = require(ReplicatedStorage.Modules:WaitForChild("CosmeticLibrary", 10))
local ItemLibrary = require(ReplicatedStorage.Modules:WaitForChild("ItemLibrary", 10))
local DataController = require(controllers:WaitForChild("PlayerDataController", 10))
local equipped, favorites = {}, {}
local constructingWeapon, viewingProfile = nil, nil
local lastUsedWeapon = nil

-- NOTIFICAÇÃO
local NotificationLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/ScriptssForRoblox/Notifica/refs/heads/main/gold_lib.lua"))()
if NotificationLib then
    NotificationLib:Notify("UnlockAll iniciado", "Todas os cosméticos (exceto Finishers) foram desbloqueados!", 5)
end

local function cloneCosmetic(name, cosmeticType, options)
    local base = CosmeticLibrary.Cosmetics[name]
    if not base then return nil end
    local data = {}
    for key, value in pairs(base) do data[key] = value end
    data.Name = name
    data.Type = data.Type or cosmeticType
    data.Seed = data.Seed or math.random(1, 1000000)
    if EnumLibrary then
        local success, enumId = pcall(EnumLibrary.ToEnum, EnumLibrary, name)
        if success and enumId then data.Enum, data.ObjectID = enumId, data.ObjectID or enumId end
    end
    if options then
        if options.inverted ~= nil then data.Inverted = options.inverted end
        if options.favoritesOnly ~= nil then data.OnlyUseFavorites = options.favoritesOnly end
    end
    return data
end

local saveFile = "unlockall/config.json"
local function saveConfig()
    if not writefile then return end
    pcall(function()
        local config = {equipped = {}, favorites = favorites}
        for weapon, cosmetics in pairs(equipped) do
            config.equipped[weapon] = {}
            for cosmeticType, cosmeticData in pairs(cosmetics) do
                if cosmeticData and cosmeticData.Name then
                    config.equipped[weapon][cosmeticType] = {
                        name = cosmeticData.Name, seed = cosmeticData.Seed, inverted = cosmeticData.Inverted
                    }
                end
            end
        end
        makefolder("unlockall")
        writefile(saveFile, HttpService:JSONEncode(config))
    end)
end

local function loadConfig()
    if not readfile or not isfile or not isfile(saveFile) then return end
    pcall(function()
        local config = HttpService:JSONDecode(readfile(saveFile))
        if config.equipped then
            for weapon, cosmetics in pairs(config.equipped) do
                equipped[weapon] = {}
                for cosmeticType, cosmeticData in pairs(cosmetics) do
                    local cloned = cloneCosmetic(cosmeticData.name, cosmeticType, {inverted = cosmeticData.inverted})
                    if cloned then cloned.Seed = cosmeticData.seed equipped[weapon][cosmeticType] = cloned end
                end
            end
        end
        favorites = config.favorites or {}
    end)
end

-- ==================== VERSION SKINS ====================
CosmeticLibrary.OwnsCosmeticNormally = function(self, inventory, name, weapon)
    local cosmetic = CosmeticLibrary.Cosmetics[name]
    if cosmetic and cosmetic.Type == "Skin" then return true end
    return false
end

CosmeticLibrary.OwnsCosmeticUniversally = function(self, inventory, name, weapon)
    local cosmetic = CosmeticLibrary.Cosmetics[name]
    if cosmetic and cosmetic.Type == "Skin" then return true end
    return false
end

CosmeticLibrary.OwnsCosmeticForWeapon = function(self, inventory, name, weapon)
    local cosmetic = CosmeticLibrary.Cosmetics[name]
    if cosmetic and cosmetic.Type == "Skin" then return true end
    return false
end

local originalOwnsCosmetic = CosmeticLibrary.OwnsCosmetic
CosmeticLibrary.OwnsCosmetic = function(self, inventory, name, weapon)
    if name:find("MISSING_") then return originalOwnsCosmetic(self, inventory, name, weapon) end
    local cosmetic = CosmeticLibrary.Cosmetics[name]
    -- EXCLURE LES FINISHERS
    if cosmetic and cosmetic.Type == "Skin" then return true end
    return originalOwnsCosmetic(self, inventory, name, weapon)
end

local originalGet = DataController.Get
DataController.Get = function(self, key)
    local data = originalGet(self, key)
    if key == "CosmeticInventory" then
        local proxy = {}
        if data then for k, v in pairs(data) do 
            local cosmetic = CosmeticLibrary.Cosmetics[k]
            -- EXCLURE LES FINISHERS
            if cosmetic and cosmetic.Type == "Skin" then proxy[k] = v end
        end end
        return setmetatable(proxy, {__index = function(t, k)
            local cosmetic = CosmeticLibrary.Cosmetics[k]
            -- EXCLURE LES FINISHERS
            if cosmetic and cosmetic.Type == "Skin" then return true end
            return nil
        end})
    end
    if key == "FavoritedCosmetics" then
        local result = data and table.clone(data) or {}
        for weapon, favs in pairs(favorites) do
            result[weapon] = result[weapon] or {}
            for name, isFav in pairs(favs) do 
                local cosmetic = CosmeticLibrary.Cosmetics[name]
                if cosmetic and cosmetic.Type == "Skin" then result[weapon][name] = isFav end
            end 
        end
        return result
    end
    return data
end

local originalGetWeaponData = DataController.GetWeaponData
DataController.GetWeaponData = function(self, weaponName)
    local data = originalGetWeaponData(self, weaponName)
    if not data then return nil end
    local merged = {}
    for key, value in pairs(data) do merged[key] = value end
    merged.Name = weaponName
    if equipped[weaponName] then
        for cosmeticType, cosmeticData in pairs(equipped[weaponName]) do 
            if cosmeticType == "Skin" then merged[cosmeticType] = cosmeticData end
        end
    end
    return merged
end

local FighterController
pcall(function() FighterController = require(controllers:WaitForChild("FighterController", 10)) end)



local ClientItem
pcall(function() ClientItem = require(player.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem) end)

if ClientItem and ClientItem._CreateViewModel then
    local originalCreateViewModel = ClientItem._CreateViewModel
    ClientItem._CreateViewModel = function(self, viewmodelRef)
        local weaponName = self.Name
        local weaponPlayer = self.ClientFighter and self.ClientFighter.Player
        constructingWeapon = (weaponPlayer == player) and weaponName or nil
        if weaponPlayer == player and equipped[weaponName] and equipped[weaponName].Skin and viewmodelRef then
            local dataKey, skinKey, nameKey = self:ToEnum("Data"), self:ToEnum("Skin"), self:ToEnum("Name")
            if viewmodelRef[dataKey] then
                viewmodelRef[dataKey][skinKey] = equipped[weaponName].Skin
                viewmodelRef[dataKey][nameKey] = equipped[weaponName].Skin.Name
            elseif viewmodelRef.Data then
                viewmodelRef.Data.Skin = equipped[weaponName].Skin
                viewmodelRef.Data.Name = equipped[weaponName].Skin.Name
            end
        end
        local result = originalCreateViewModel(self, viewmodelRef)
        constructingWeapon = nil
        return result
    end
end

local viewModelModule = player.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem:FindFirstChild("ClientViewModel")
if viewModelModule then
    local ClientViewModel = require(viewModelModule)
    local originalNew = ClientViewModel.new
    ClientViewModel.new = function(replicatedData, clientItem)
        local weaponPlayer = clientItem.ClientFighter and clientItem.ClientFighter.Player
        local weaponName = constructingWeapon or clientItem.Name
        if weaponPlayer == player and equipped[weaponName] then
            local ReplicatedClass = require(ReplicatedStorage.Modules.ReplicatedClass)
            local dataKey = ReplicatedClass:ToEnum("Data")
            replicatedData[dataKey] = replicatedData[dataKey] or {}
            local cosmetics = equipped[weaponName]
            if cosmetics.Skin then replicatedData[dataKey][ReplicatedClass:ToEnum("Skin")] = cosmetics.Skin end
        end
        local result = originalNew(replicatedData, clientItem)
        return result
    end
end

local originalGetViewModelImage = ItemLibrary.GetViewModelImageFromWeaponData
ItemLibrary.GetViewModelImageFromWeaponData = function(self, weaponData, highRes)
    if not weaponData then return originalGetViewModelImage(self, weaponData, highRes) end
    local weaponName = weaponData.Name
    local shouldShowSkin = (weaponData.Skin and equipped[weaponName] and weaponData.Skin == equipped[weaponName].Skin) or (viewingProfile == player and equipped[weaponName] and equipped[weaponName].Skin)
    if shouldShowSkin and equipped[weaponName] and equipped[weaponName].Skin then
        local skinInfo = self.ViewModels[equipped[weaponName].Skin.Name]
        if skinInfo then return skinInfo[highRes and "ImageHighResolution" or "Image"] or skinInfo.Image end
    end
    return originalGetViewModelImage(self, weaponData, highRes)
end

-- ==================== VERSION CHARMS ====================
local originalOwnsCosmeticCharm = CosmeticLibrary.OwnsCosmetic
CosmeticLibrary.OwnsCosmetic = function(self, inventory, name, weapon)
    if name:find("MISSING_") then return originalOwnsCosmeticCharm(self, inventory, name, weapon) end
    local cosmetic = CosmeticLibrary.Cosmetics[name]
    -- EXCLURE LES FINISHERS
    if cosmetic and (cosmetic.Type == "Charm" or name:lower():find("charm")) then return true end
    return originalOwnsCosmeticCharm(self, inventory, name, weapon)
end

local originalGetCharm = DataController.Get
DataController.Get = function(self, key)
    local data = originalGetCharm(self, key)
    if key == "CosmeticInventory" then
        local proxy = {}
        if data then for k, v in pairs(data) do 
            local cosmetic = CosmeticLibrary.Cosmetics[k]
            -- EXCLURE LES FINISHERS
            if cosmetic and (cosmetic.Type == "Charm" or k:lower():find("charm")) then proxy[k] = v end
        end end
        return setmetatable(proxy, {__index = function(t, k)
            local cosmetic = CosmeticLibrary.Cosmetics[k]
            -- EXCLURE LES FINISHERS
            if cosmetic and (cosmetic.Type == "Charm" or k:lower():find("charm")) then return true end
            return nil
        end})
    end
    if key == "FavoritedCosmetics" then
        local result = data and table.clone(data) or {}
        for weapon, favs in pairs(favorites) do
            result[weapon] = result[weapon] or {}
            for name, isFav in pairs(favs) do 
                local cosmetic = CosmeticLibrary.Cosmetics[name]
                if cosmetic and (cosmetic.Type == "Charm" or name:lower():find("charm")) then result[weapon][name] = isFav end
            end
        end
        return result
    end
    return data
end

local originalGetWeaponDataCharm = DataController.GetWeaponData
DataController.GetWeaponData = function(self, weaponName)
    local data = originalGetWeaponDataCharm(self, weaponName)
    if not data then return nil end
    local merged = {}
    for key, value in pairs(data) do merged[key] = value end
    merged.Name = weaponName
    if equipped[weaponName] then
        for cosmeticType, cosmeticData in pairs(equipped[weaponName]) do 
            if cosmeticType == "Charm" then merged[cosmeticType] = cosmeticData end
        end
    end
    return merged
end



if ClientItem and ClientItem._CreateViewModel then
    local originalCreateViewModelCharm = ClientItem._CreateViewModel
    ClientItem._CreateViewModel = function(self, viewmodelRef)
        local weaponName = self.Name
        local weaponPlayer = self.ClientFighter and self.ClientFighter.Player
        constructingWeapon = (weaponPlayer == player) and weaponName or nil
        if weaponPlayer == player and equipped[weaponName] and equipped[weaponName].Charm and viewmodelRef then
            local dataKey, charmKey, nameKey = self:ToEnum("Data"), self:ToEnum("Charm"), self:ToEnum("Name")
            if viewmodelRef[dataKey] then
                viewmodelRef[dataKey][charmKey] = equipped[weaponName].Charm
                viewmodelRef[dataKey][nameKey] = equipped[weaponName].Charm.Name
            elseif viewmodelRef.Data then
                viewmodelRef.Data.Charm = equipped[weaponName].Charm
                viewmodelRef.Data.Name = equipped[weaponName].Charm.Name
            end
        end
        local result = originalCreateViewModelCharm(self, viewmodelRef)
        constructingWeapon = nil
        return result
    end
end

if viewModelModule then
    local ClientViewModel = require(viewModelModule)
    if ClientViewModel.GetCharm then
        local originalGetCharmFunc = ClientViewModel.GetCharm
        ClientViewModel.GetCharm = function(self)
            local weaponName = self.ClientItem and self.ClientItem.Name
            local weaponPlayer = self.ClientItem and self.ClientItem.ClientFighter and self.ClientItem.ClientFighter.Player
            if weaponName and weaponPlayer == player and equipped[weaponName] and equipped[weaponName].Charm then
                return equipped[weaponName].Charm
            end
            return originalGetCharmFunc(self)
        end
    end
    local originalNewCharm = ClientViewModel.new
    ClientViewModel.new = function(replicatedData, clientItem)
        local weaponPlayer = clientItem.ClientFighter and clientItem.ClientFighter.Player
        local weaponName = constructingWeapon or clientItem.Name
        if weaponPlayer == player and equipped[weaponName] then
            local ReplicatedClass = require(ReplicatedStorage.Modules.ReplicatedClass)
            local dataKey = ReplicatedClass:ToEnum("Data")
            replicatedData[dataKey] = replicatedData[dataKey] or {}
            local cosmetics = equipped[weaponName]
            if cosmetics.Charm then replicatedData[dataKey][ReplicatedClass:ToEnum("Charm")] = cosmetics.Charm end
        end
        local result = originalNewCharm(replicatedData, clientItem)
        return result
    end
end

-- ==================== VERSION DANCES ====================
local originalOwnsCosmeticDance = CosmeticLibrary.OwnsCosmetic
CosmeticLibrary.OwnsCosmetic = function(self, inventory, name, weapon)
    if name:find("MISSING_") then return originalOwnsCosmeticDance(self, inventory, name, weapon) end
    local cosmetic = CosmeticLibrary.Cosmetics[name]
    -- EXCLURE LES FINISHERS
    if cosmetic and (cosmetic.Type == "Dance" or cosmetic.Type == "Emote" or name:lower():find("dance") or name:lower():find("emote")) then return true end
    return originalOwnsCosmeticDance(self, inventory, name, weapon)
end

local originalGetDance = DataController.Get
DataController.Get = function(self, key)
    local data = originalGetDance(self, key)
    if key == "CosmeticInventory" then
        local proxy = {}
        if data then for k, v in pairs(data) do 
            local cosmetic = CosmeticLibrary.Cosmetics[k]
            -- EXCLURE LES FINISHERS
            if cosmetic and (cosmetic.Type == "Dance" or cosmetic.Type == "Emote" or k:lower():find("dance") or k:lower():find("emote")) then proxy[k] = v end
        end end
        return setmetatable(proxy, {__index = function(t, k)
            local cosmetic = CosmeticLibrary.Cosmetics[k]
            -- EXCLURE LES FINISHERS
            if cosmetic and (cosmetic.Type == "Dance" or cosmetic.Type == "Emote" or k:lower():find("dance") or k:lower():find("emote")) then return true end
            return nil
        end})
    end
    if key == "FavoritedCosmetics" then
        local result = data and table.clone(data) or {}
        for weapon, favs in pairs(favorites) do
            result[weapon] = result[weapon] or {}
            for name, isFav in pairs(favs) do 
                local cosmetic = CosmeticLibrary.Cosmetics[name]
                if cosmetic and (cosmetic.Type == "Dance" or cosmetic.Type == "Emote" or name:lower():find("dance") or name:lower():find("emote")) then result[weapon][name] = isFav end
            end
        end
        return result
    end
    return data
end

local originalGetWeaponDataDance = DataController.GetWeaponData
DataController.GetWeaponData = function(self, weaponName)
    local data = originalGetWeaponDataDance(self, weaponName)
    if not data then return nil end
    local merged = {}
    for key, value in pairs(data) do merged[key] = value end
    merged.Name = weaponName
    return merged
end



local EmoteController
pcall(function() 
    EmoteController = require(controllers:WaitForChild("EmoteController", 10))
    if EmoteController and EmoteController.GetEmotes then
        local originalGetEmotes = EmoteController.GetEmotes
        EmoteController.GetEmotes = function(self)
            local emotes = originalGetEmotes(self)
            for name, cosmetic in pairs(CosmeticLibrary.Cosmetics) do
                if cosmetic and (cosmetic.Type == "Dance" or cosmetic.Type == "Emote" or name:lower():find("dance") or name:lower():find("emote")) then
                    if not emotes[name] then
                        emotes[name] = {
                            Name = name,
                            Type = cosmetic.Type,
                            ObjectID = cosmetic.ObjectID,
                            Enum = cosmetic.Enum
                        }
                    end
                end
            end
            return emotes
        end
    end
end)

-- ==================== VERSION WRAPS ====================
local originalOwnsCosmeticWrap = CosmeticLibrary.OwnsCosmetic
CosmeticLibrary.OwnsCosmetic = function(self, inventory, name, weapon)
    if name:find("MISSING_") then return originalOwnsCosmeticWrap(self, inventory, name, weapon) end
    local cosmetic = CosmeticLibrary.Cosmetics[name]
    -- EXCLURE LES FINISHERS
    if cosmetic and (cosmetic.Type == "Wrap" or cosmetic.Type == "Wrapping" or name:lower():find("wrap")) then return true end
    return originalOwnsCosmeticWrap(self, inventory, name, weapon)
end

local originalGetWrapVer = DataController.Get
DataController.Get = function(self, key)
    local data = originalGetWrapVer(self, key)
    if key == "CosmeticInventory" then
        local proxy = {}
        if data then for k, v in pairs(data) do 
            local cosmetic = CosmeticLibrary.Cosmetics[k]
            -- EXCLURE LES FINISHERS
            if cosmetic and (cosmetic.Type == "Wrap" or cosmetic.Type == "Wrapping" or k:lower():find("wrap")) then proxy[k] = v end
        end end
        return setmetatable(proxy, {__index = function(t, k)
            local cosmetic = CosmeticLibrary.Cosmetics[k]
            -- EXCLURE LES FINISHERS
            if cosmetic and (cosmetic.Type == "Wrap" or cosmetic.Type == "Wrapping" or k:lower():find("wrap")) then return true end
            return nil
        end})
    end
    if key == "FavoritedCosmetics" then
        local result = data and table.clone(data) or {}
        for weapon, favs in pairs(favorites) do
            result[weapon] = result[weapon] or {}
            for name, isFav in pairs(favs) do 
                local cosmetic = CosmeticLibrary.Cosmetics[name]
                if cosmetic and (cosmetic.Type == "Wrap" or cosmetic.Type == "Wrapping" or name:lower():find("wrap")) then result[weapon][name] = isFav end
            end
        end
        return result
    end
    return data
end

local originalGetWeaponDataWrap = DataController.GetWeaponData
DataController.GetWeaponData = function(self, weaponName)
    local data = originalGetWeaponDataWrap(self, weaponName)
    if not data then return nil end
    local merged = {}
    for key, value in pairs(data) do merged[key] = value end
    merged.Name = weaponName
    if equipped[weaponName] then
        for cosmeticType, cosmeticData in pairs(equipped[weaponName]) do 
            if cosmeticType == "Wrap" or cosmeticType == "Wrapping" then merged[cosmeticType] = cosmeticData end
        end
    end
    return merged
end



if ClientItem and ClientItem._CreateViewModel then
    local originalCreateViewModelWrap = ClientItem._CreateViewModel
    ClientItem._CreateViewModel = function(self, viewmodelRef)
        local weaponName = self.Name
        local weaponPlayer = self.ClientFighter and self.ClientFighter.Player
        constructingWeapon = (weaponPlayer == player) and weaponName or nil
        if weaponPlayer == player and equipped[weaponName] and equipped[weaponName].Wrap and viewmodelRef then
            local dataKey, wrapKey, nameKey = self:ToEnum("Data"), self:ToEnum("Wrap"), self:ToEnum("Name")
            if viewmodelRef[dataKey] then
                viewmodelRef[dataKey][wrapKey] = equipped[weaponName].Wrap
                viewmodelRef[dataKey][nameKey] = equipped[weaponName].Wrap.Name
            elseif viewmodelRef.Data then
                viewmodelRef.Data.Wrap = equipped[weaponName].Wrap
                viewmodelRef.Data.Name = equipped[weaponName].Wrap.Name
            end
        end
        local result = originalCreateViewModelWrap(self, viewmodelRef)
        constructingWeapon = nil
        return result
    end
end

if viewModelModule then
    local ClientViewModel = require(viewModelModule)
    if ClientViewModel.GetWrap then
        local originalGetWrapFunc = ClientViewModel.GetWrap
        ClientViewModel.GetWrap = function(self)
            local weaponName = self.ClientItem and self.ClientItem.Name
            local weaponPlayer = self.ClientItem and self.ClientItem.ClientFighter and self.ClientItem.ClientFighter.Player
            if weaponName and weaponPlayer == player and equipped[weaponName] and equipped[weaponName].Wrap then
                return equipped[weaponName].Wrap
            end
            return originalGetWrapFunc(self)
        end
    end
    local originalNewWrap = ClientViewModel.new
    ClientViewModel.new = function(replicatedData, clientItem)
        local weaponPlayer = clientItem.ClientFighter and clientItem.ClientFighter.Player
        local weaponName = constructingWeapon or clientItem.Name
        if weaponPlayer == player and equipped[weaponName] then
            local ReplicatedClass = require(ReplicatedStorage.Modules.ReplicatedClass)
            local dataKey = ReplicatedClass:ToEnum("Data")
            replicatedData[dataKey] = replicatedData[dataKey] or {}
            local cosmetics = equipped[weaponName]
            if cosmetics.Wrap then replicatedData[dataKey][ReplicatedClass:ToEnum("Wrap")] = cosmetics.Wrap end
        end
        local result = originalNewWrap(replicatedData, clientItem)
        if weaponPlayer == player and equipped[weaponName] and equipped[weaponName].Wrap and result._UpdateWrap then
            result:_UpdateWrap()
            task.delay(0.1, function() if not result._destroyed then result:_UpdateWrap() end end)
        end
        return result
    end
end

-- ============================================================================
-- FINISHERS — Dynamic Type Detection
-- ============================================================================
local KNOWN_NON_FINISHER = {
    Skin = true, Charm = true, Dance = true, Emote = true, Wrap = true,
    Wrapping = true, Animation = true, Taunt = true, Spray = true,
    Banner = true, Title = true, Icon = true, Frame = true,
    Sticker = true, Effect = true, Trail = true, Accessory = true,
    Hat = true, Face = true, Hair = true, Shirt = true, Pants = true,
    Bundle = true, LobbyMusic = true, KillEffect = true,
}
local finisherTypes = nil

local function detectFinisherTypes()
    local counts = {}
    for _, cosmetic in pairs(CosmeticLibrary.Cosmetics) do
        if type(cosmetic) == "table" and cosmetic.Type then
            local t = cosmetic.Type
            if not KNOWN_NON_FINISHER[t] then
                counts[t] = (counts[t] or 0) + 1
            end
        end
    end
    local types = {}
    for t, count in pairs(counts) do
        if count >= 3 then
            local lt = t:lower()
            if lt:find("finish") or lt:find("execute") or lt:find("fatal") or lt:find("eliminate") then
                types[t] = true
            end
        end
    end
    if next(types) then finisherTypes = types; return types end
    types = {Finisher = true, FinishingMove = true, Execution = true, Fatality = true}
    finisherTypes = types
    return types
end

local function isFinisher(cosmetic, name)
    if not cosmetic or type(cosmetic) ~= "table" then return false end
    if cosmetic.Type and finisherTypes and finisherTypes[cosmetic.Type] then return true end
    if name then
        local lower = name:lower()
        if lower:find("finish") or lower:find("execution") or lower:find("fatality") then return true end
    end
    return false
end

local finEquipped = {}
local finFavorites = {}
local constructingFinisher = nil
local finisherConfigDirty = false
local finisherSaveFile = "unlockall/finishers_config.json"

local function saveFinisherConfig()
    if not writefile then return end
    pcall(function()
        local config = {equipped = {}, favorites = {}}
        for weapon, cosmetics in pairs(finEquipped) do
            config.equipped[weapon] = {}
            for ctype, cdata in pairs(cosmetics) do
                if cdata and cdata.Name then
                    config.equipped[weapon][ctype] = {
                        name = cdata.Name, seed = cdata.Seed, inverted = cdata.Inverted,
                    }
                end
            end
        end
        for weapon, favs in pairs(finFavorites) do
            config.favorites[weapon] = {}
            for name, val in pairs(favs) do config.favorites[weapon][name] = val end
        end
        makefolder("unlockall")
        writefile(finisherSaveFile, HttpService:JSONEncode(config))
    end)
    finisherConfigDirty = false
end

local function loadFinisherConfig()
    if not readfile or not isfile or not isfile(finisherSaveFile) then return end
    pcall(function()
        local config = HttpService:JSONDecode(readfile(finisherSaveFile))
        if config.equipped then
            for weapon, cosmetics in pairs(config.equipped) do
                finEquipped[weapon] = {}
                for ctype, cdata in pairs(cosmetics) do
                    local cloned = cloneCosmetic(cdata.name, ctype, {inverted = cdata.inverted})
                    if cloned then
                        if cdata.seed then cloned.Seed = cdata.seed end
                        finEquipped[weapon][ctype] = cloned
                    end
                end
                if not next(finEquipped[weapon]) then finEquipped[weapon] = nil end
            end
        end
        if config.favorites then
            for weapon, favs in pairs(config.favorites) do
                finFavorites[weapon] = {}
                for name, val in pairs(favs) do
                    local cosmetic = CosmeticLibrary.Cosmetics[name]
                    if cosmetic and isFinisher(cosmetic, name) then
                        finFavorites[weapon][name] = val
                    end
                end
            end
        end
    end)
end

-- ============================================================================
-- FINISHERS — CosmeticLibrary.OwnsCosmetic chain
-- ============================================================================
local prevOwnsFinisher = CosmeticLibrary.OwnsCosmetic
CosmeticLibrary.OwnsCosmetic = function(self, inventory, name, weapon)
    if name:find("MISSING_") then return prevOwnsFinisher(self, inventory, name, weapon) end
    if prevOwnsFinisher(self, inventory, name, weapon) then return true end
    local cosmetic = CosmeticLibrary.Cosmetics[name]
    if cosmetic and isFinisher(cosmetic, name) then return true end
    return false
end

-- ============================================================================
-- FINISHERS — DataController.Get chain
-- ============================================================================
local prevDataGetFin = DataController.Get
DataController.Get = function(self, key)
    if key == "CosmeticInventory" then
        local data = prevDataGetFin(self, key)
        local proxy = {}
        if data then for k, v in pairs(data) do proxy[k] = v end end
        for k, cosmetic in pairs(CosmeticLibrary.Cosmetics) do
            if isFinisher(cosmetic, k) then proxy[k] = true end
        end
        local prevMT = type(data) == "table" and getmetatable(data)
        return setmetatable(proxy, {__index = function(t, k)
            if prevMT and prevMT.__index then
                local mtv = prevMT.__index(t, k)
                if mtv ~= nil then return mtv end
            end
            local cosmetic = CosmeticLibrary.Cosmetics[k]
            if cosmetic and isFinisher(cosmetic, k) then return true end
            return nil
        end})
    end
    if key == "FavoritedCosmetics" then
        local result = prevDataGetFin(self, key) or {}
        for weapon, favs in pairs(finFavorites) do
            if not result[weapon] then result[weapon] = {} end
            for name, isFav in pairs(favs) do
                local cosmetic = CosmeticLibrary.Cosmetics[name]
                if cosmetic and isFinisher(cosmetic, name) then
                    result[weapon][name] = isFav
                end
            end
        end
        return result
    end
    return prevDataGetFin(self, key)
end

-- ============================================================================
-- FINISHERS — DataController.GetWeaponData chain
-- ============================================================================
local prevGetWeaponDataFin = DataController.GetWeaponData
DataController.GetWeaponData = function(self, weaponName)
    local data = prevGetWeaponDataFin(self, weaponName)
    if not data then return nil end
    local merged = {}
    for key, value in pairs(data) do merged[key] = value end
    merged.Name = weaponName
    if finEquipped[weaponName] then
        for ctype, cdata in pairs(finEquipped[weaponName]) do merged[ctype] = cdata end
    end
    return merged
end



-- ============================================================================
-- FINISHERS — FighterController.GetFighter injection (cached)
-- ============================================================================
local finisherItemCache = nil
local finisherCacheDirty = true

local function rebuildFinisherCache()
    finisherItemCache = {}
    for name, cosmetic in pairs(CosmeticLibrary.Cosmetics) do
        if isFinisher(cosmetic, name) then
            local objectID = cosmetic.ObjectID
            if not objectID and EnumLibrary then
                local ok, eid = pcall(EnumLibrary.ToEnum, EnumLibrary, name)
                if ok and eid then objectID = eid end
            end
            if objectID then
                table.insert(finisherItemCache, {
                    Name = name,
                    ObjectID = objectID,
                    Cosmetic = cosmetic,
                })
            end
        end
    end
    finisherCacheDirty = false
end

if FighterController then
    local prevGetFighterFin = FighterController.GetFighter
    if prevGetFighterFin then
        FighterController.GetFighter = function(self, plr)
            local fighter = prevGetFighterFin(self, plr)
            if plr == player and fighter and fighter.Items then
                if finisherCacheDirty then rebuildFinisherCache() end
                local existingIDs = {}
                for _, item in pairs(fighter.Items) do
                    local oid = item.Get and item:Get("ObjectID")
                    if oid then existingIDs[oid] = true end
                end
                local currentWeapon = constructingFinisher
                for _, cached in pairs(finisherItemCache) do
                    if not existingIDs[cached.ObjectID] then
                        local shouldAdd = true
                        if currentWeapon and finEquipped[currentWeapon] then
                            local found = false
                            for _, cd in pairs(finEquipped[currentWeapon]) do
                                if cd.Name == cached.Name then found = true; break end
                            end
                            shouldAdd = found
                        end
                        if shouldAdd then
                            local name, objectID, cosmetic = cached.Name, cached.ObjectID, cached.Cosmetic
                            table.insert(fighter.Items, {
                                Name = name, ObjectID = objectID,
                                Get = function(_, key)
                                    if key == "ObjectID" then return objectID
                                    elseif key == "Name" then return name
                                    elseif key == "Type" then return cosmetic.Type end
                                end
                            })
                            existingIDs[objectID] = true
                        end
                    end
                end
            end
            return fighter
        end
    end
end

-- ============================================================================
-- FINISHERS — ClientItem._CreateViewModel
-- ============================================================================
if ClientItem and ClientItem._CreateViewModel then
    local prevCreateVMFin = ClientItem._CreateViewModel
    ClientItem._CreateViewModel = function(self, viewmodelRef)
        local weaponName = self.Name
        local weaponPlayer = self.ClientFighter and self.ClientFighter.Player
        constructingFinisher = (weaponPlayer == player) and weaponName or nil
        if weaponPlayer == player and viewmodelRef and finEquipped[weaponName] then
            for ctype, cdata in pairs(finEquipped[weaponName]) do
                local cosmetic = CosmeticLibrary.Cosmetics[cdata.Name]
                if cosmetic and isFinisher(cosmetic, cdata.Name) then
                    local dataKey = self.ToEnum and self:ToEnum("Data")
                    local typeKey = self.ToEnum and self:ToEnum(ctype)
                    local nameKey = self.ToEnum and self:ToEnum("Name")
                    if dataKey and typeKey and viewmodelRef[dataKey] then
                        viewmodelRef[dataKey][typeKey] = cdata
                        viewmodelRef[dataKey][nameKey] = cdata.Name
                    elseif viewmodelRef.Data then
                        viewmodelRef.Data[ctype] = cdata
                        viewmodelRef.Data.Name = cdata.Name
                    end
                end
            end
        end
        local result = prevCreateVMFin(self, viewmodelRef)
        constructingFinisher = nil
        return result
    end
end

-- ============================================================================
-- FINISHERS — ClientViewModel.new
-- ============================================================================
local finViewModelModule = player.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem:FindFirstChild("ClientViewModel")
if finViewModelModule then
    local FinClientViewModel = require(finViewModelModule)
    local prevNewFin = FinClientViewModel.new
    FinClientViewModel.new = function(replicatedData, clientItem)
        local weaponPlayer = clientItem.ClientFighter and clientItem.ClientFighter.Player
        local weaponName = constructingFinisher or clientItem.Name
        if weaponPlayer == player and finEquipped[weaponName] then
            local ok, ReplicatedClass = pcall(require, ReplicatedStorage.Modules.ReplicatedClass)
            if ok and ReplicatedClass then
                local dataKey = ReplicatedClass:ToEnum("Data")
                replicatedData[dataKey] = replicatedData[dataKey] or {}
                for ctype, cdata in pairs(finEquipped[weaponName]) do
                    local cosmetic = CosmeticLibrary.Cosmetics[cdata.Name]
                    if cosmetic and isFinisher(cosmetic, cdata.Name) then
                        local typeKey = ReplicatedClass:ToEnum(ctype)
                        if typeKey then replicatedData[dataKey][typeKey] = cdata
                        else replicatedData[dataKey][ctype] = cdata end
                    end
                end
            end
        end
        return prevNewFin(replicatedData, clientItem)
    end
end

-- ============================================================================
-- FINISHERS — ItemLibrary.GetViewModelImageFromWeaponData
-- ============================================================================
local prevGetImageFin = ItemLibrary.GetViewModelImageFromWeaponData
ItemLibrary.GetViewModelImageFromWeaponData = function(self, weaponData, highRes)
    if not weaponData then return prevGetImageFin(self, weaponData, highRes) end
    local weaponName = weaponData.Name
    local myEquipped = finEquipped[weaponName]
    if myEquipped then
        for _, cdata in pairs(myEquipped) do
            if isFinisher(CosmeticLibrary.Cosmetics[cdata.Name], cdata.Name) then
                local skinInfo = self.ViewModels[cdata.Name]
                if skinInfo then return skinInfo[highRes and "ImageHighResolution" or "Image"] or skinInfo.Image end
            end
        end
    end
    if viewingProfile == player and myEquipped then
        for _, cdata in pairs(myEquipped) do
            if isFinisher(CosmeticLibrary.Cosmetics[cdata.Name], cdata.Name) then
                local skinInfo = self.ViewModels[cdata.Name]
                if skinInfo then return skinInfo[highRes and "ImageHighResolution" or "Image"] or skinInfo.Image end
            end
        end
    end
    return prevGetImageFin(self, weaponData, highRes)
end

-- ============================================================================
-- FINISHERS — ViewProfile.Fetch
-- ============================================================================
pcall(function()
    local ViewProfile = require(player.PlayerScripts.Modules.Pages.ViewProfile)
    if ViewProfile and ViewProfile.Fetch then
        local origFetchFin = ViewProfile.Fetch
        ViewProfile.Fetch = function(self, targetPlayer)
            viewingProfile = targetPlayer
            return origFetchFin(self, targetPlayer)
        end
    end
end)

-- ============================================================================
-- FINISHERS — Periodic auto-save
-- ============================================================================
task.spawn(function()
    while task.wait(5) do
        if finisherConfigDirty then saveFinisherConfig() end
    end
end)

-- ============================================================================
-- SKY PRESETS
-- ============================================================================
local SKY_PRESETS = {
    {
        name = "Nebula Azul",
        brightness = 1.5,
        ambient = Color3.fromRGB(30, 20, 50),
        outdoor = Color3.fromRGB(15, 10, 30),
        fogColor = Color3.fromRGB(10, 5, 25),
        fogEnd = 500,
        fogStart = 50,
        colorShiftTop = Color3.fromRGB(40, 25, 80),
        colorShiftBottom = Color3.fromRGB(5, 0, 15),
        skyId = "17748366052",
        atmosDensity = 0.35,
        atmosOffset = 0.4,
        atmosColor = Color3.fromRGB(60, 40, 120),
        atmosHaze = 0.3,
        atmosGlare = 0.2,
    },
    {
        name = "Meia-Noite",
        brightness = 0.6,
        ambient = Color3.fromRGB(5, 5, 10),
        outdoor = Color3.fromRGB(2, 2, 8),
        fogColor = Color3.fromRGB(0, 0, 5),
        fogEnd = 300,
        fogStart = 20,
        colorShiftTop = Color3.fromRGB(10, 5, 20),
        colorShiftBottom = Color3.fromRGB(0, 0, 5),
        skyId = "17748366052",
        atmosDensity = 0.6,
        atmosOffset = 0.6,
        atmosColor = Color3.fromRGB(20, 10, 40),
        atmosHaze = 0.5,
        atmosGlare = 0.1,
    },
    {
        name = "Lua de Sangue",
        brightness = 1.0,
        ambient = Color3.fromRGB(40, 10, 10),
        outdoor = Color3.fromRGB(50, 5, 5),
        fogColor = Color3.fromRGB(30, 5, 5),
        fogEnd = 400,
        fogStart = 30,
        colorShiftTop = Color3.fromRGB(80, 15, 15),
        colorShiftBottom = Color3.fromRGB(20, 2, 2),
        skyId = "17748366052",
        atmosDensity = 0.5,
        atmosOffset = 0.5,
        atmosColor = Color3.fromRGB(100, 20, 20),
        atmosHaze = 0.4,
        atmosGlare = 0.3,
    },
}

local currentSkyPreset = 1
local visualsEnabled = true
local skyInstance = nil
local atmosInstance = nil

local function applySkyPreset(index)
    pcall(function()
        local preset = SKY_PRESETS[index]
        if not preset then return end

        Lighting.Brightness = preset.brightness
        Lighting.GlobalShadows = true
        Lighting.OutdoorAmbient = preset.outdoor
        Lighting.Ambient = preset.ambient
        Lighting.ColorShift_Bottom = preset.colorShiftBottom
        Lighting.ColorShift_Top = preset.colorShiftTop
        Lighting.FogColor = preset.fogColor
        Lighting.FogEnd = preset.fogEnd
        Lighting.FogStart = preset.fogStart

        if skyInstance then skyInstance:Destroy() end
        skyInstance = Instance.new("Sky")
        skyInstance.Parent = Lighting
        local sid = preset.skyId
        skyInstance.SkyboxBk = "rbxassetid://" .. sid
        skyInstance.SkyboxDn = "rbxassetid://" .. sid
        skyInstance.SkyboxFt = "rbxassetid://" .. sid
        skyInstance.SkyboxLf = "rbxassetid://" .. sid
        skyInstance.SkyboxRt = "rbxassetid://" .. sid
        skyInstance.SkyboxUp = "rbxassetid://" .. sid
        skyInstance.SunTextureId = ""

        if atmosInstance then atmosInstance:Destroy() end
        atmosInstance = Instance.new("Atmosphere")
        atmosInstance.Parent = Lighting
        atmosInstance.Density = preset.atmosDensity
        atmosInstance.Offset = preset.atmosOffset
        atmosInstance.Color = preset.atmosColor
        atmosInstance.Haze = preset.atmosHaze
        atmosInstance.Glare = preset.atmosGlare
    end)
end

local function removeSkyPreset()
    pcall(function()
        if skyInstance then skyInstance:Destroy(); skyInstance = nil end
        if atmosInstance then atmosInstance:Destroy(); atmosInstance = nil end
        Lighting.Brightness = 1
        Lighting.GlobalShadows = true
        Lighting.OutdoorAmbient = Color3.fromRGB(100, 100, 100)
        Lighting.Ambient = Color3.fromRGB(128, 128, 128)
        Lighting.ColorShift_Bottom = Color3.fromRGB(0, 0, 0)
        Lighting.ColorShift_Top = Color3.fromRGB(0, 0, 0)
        Lighting.FogColor = Color3.fromRGB(100, 100, 100)
        Lighting.FogEnd = 1000
        Lighting.FogStart = 0
    end)
end

-- ============================================================================
-- DARK TEXTURES / LOW-POLY APPLY (with incremental update)
-- ============================================================================
local darkTexturesApplied = false
local function applyDarkTextures(fullScan)
    if darkTexturesApplied and not fullScan then return end
    pcall(function()
        for _, v in pairs(workspace:GetDescendants()) do
            if (v:IsA("BasePart") or v:IsA("MeshPart") or v:IsA("UnionOperation")) and not v:IsA("Terrain") then
                v.Material = Enum.Material.SmoothPlastic
                v.Reflectance = 0
                if UserInputService.TouchEnabled then v.CastShadow = false end
            end
            if v:IsA("Decal") or v:IsA("Texture") then v.Transparency = 0.7 end
            if v:IsA("ParticleEmitter") or v:IsA("Smoke") or v:IsA("Fire") then v.Enabled = false end
            if v:IsA("PointLight") or v:IsA("SurfaceLight") or v:IsA("SpotLight") then v.Enabled = false end
            if v:IsA("Water") and not v:IsA("Terrain") then v.Transparency = 0.9; v.Reflectance = 0 end
        end
        local terrain = workspace:FindFirstChild("Terrain")
        if terrain then
            terrain.WaterColor = Color3.fromRGB(5, 0, 15)
            terrain.WaterTransparency = 0.9
            terrain.WaterReflectance = 0
        end
        pcall(function() game:GetService("UserGameSettings").MasterVolume = 0.3 end)
        darkTexturesApplied = true
    end)
end

workspace.DescendantAdded:Connect(function(v)
    if darkTexturesApplied and visualsEnabled then
        pcall(function()
            if (v:IsA("BasePart") or v:IsA("MeshPart") or v:IsA("UnionOperation")) and not v:IsA("Terrain") then
                v.Material = Enum.Material.SmoothPlastic
                v.Reflectance = 0
            elseif v:IsA("Decal") or v:IsA("Texture") then
                v.Transparency = 0.7
            elseif v:IsA("ParticleEmitter") or v:IsA("Smoke") or v:IsA("Fire") then
                v.Enabled = false
            elseif v:IsA("Water") and not v:IsA("Terrain") then
                v.Transparency = 0.9; v.Reflectance = 0
            end
        end)
    end
end)

local function removeDarkTextures()
    -- Can't easily undo material changes, skip
end

-- ============================================================================
-- REMOVE GUI BLUR
-- ============================================================================
local function removeBlur()
    pcall(function()
        for _, v in pairs(Lighting:GetDescendants()) do
            if v:IsA("BlurEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("SunRaysEffect") or v:IsA("BloomEffect") then
                v.Enabled = false
            end
        end
        local playersCopy = Players:GetPlayers()
        for _, plr in pairs(playersCopy) do
            if plr and plr:FindFirstChild("PlayerGui") then
                for _, gui in pairs(plr.PlayerGui:GetDescendants()) do
                    if gui:IsA("BlurEffect") then gui.Enabled = false end
                end
            end
        end
    end)
end

-- ============================================================================
-- AUTO-REAPPLY (on respawn + every 60s)
-- ============================================================================
player.CharacterAdded:Connect(function()
    task.wait(3)
    if visualsEnabled then
        task.spawn(applyDarkTextures, true)
        task.spawn(removeBlur)
    end
end)

task.spawn(function()
    while task.wait(60) do
        if visualsEnabled then
            applyDarkTextures()
            removeBlur()
        end
    end
end)

-- ============================================================================
-- WATERMARK
-- ============================================================================
local watermarkGui
local function createWatermark()
    pcall(function()
        if watermarkGui then watermarkGui:Destroy() end
        watermarkGui = Instance.new("ScreenGui")
        watermarkGui.Name = "RedzWatermark"
        watermarkGui.ResetOnSpawn = false
        watermarkGui.DisplayOrder = 999999
        watermarkGui.IgnoreGuiInset = true
        watermarkGui.Parent = player:WaitForChild("PlayerGui")

        local txt = Instance.new("TextLabel")
        txt.Size = UDim2.new(0, 180, 0, 28)
        txt.Position = UDim2.new(0, 8, 0, 8)
        txt.BackgroundTransparency = 0.5
        txt.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        txt.BorderSizePixel = 0
        txt.TextColor3 = Color3.fromRGB(255, 100, 50)
        txt.Text = "REDZ UNLOCK  |  60 FPS"
        txt.TextSize = 13
        txt.Font = Enum.Font.SourceSansBold
        txt.TextXAlignment = Enum.TextXAlignment.Left
        txt.Parent = watermarkGui

        local pingTxt = txt:Clone()
        pingTxt.Name = "PingLabel"
        pingTxt.Size = UDim2.new(0, 140, 0, 20)
        pingTxt.Position = UDim2.new(0, 8, 0, 34)
        pingTxt.Text = "Ping: --  |  FPS: --"
        pingTxt.TextColor3 = Color3.fromRGB(150, 200, 255)
        pingTxt.TextSize = 11
        pingTxt.Parent = watermarkGui

        task.spawn(function()
            while watermarkGui and watermarkGui.Parent do
                pcall(function()
                    local pingLabel = watermarkGui:FindFirstChild("PingLabel")
                    if pingLabel then
                        local stats = game:GetService("Stats")
                        local ping = math.floor(stats.Network.ServerStatsItem["Data Ping"]:GetValueString())
                        local fps = math.floor(1 / RunService.RenderStepped:Wait())
                        pingLabel.Text = "Ping: " .. ping .. "ms  |  FPS: " .. fps
                    end
                end)
                task.wait(0.5)
            end
        end)
    end)
end



-- ============================================================================
-- KEYBIND TOGGLE
-- ============================================================================
local function cycleSkyPreset()
    currentSkyPreset = currentSkyPreset + 1
    if currentSkyPreset > #SKY_PRESETS then currentSkyPreset = 1 end
    applySkyPreset(currentSkyPreset)
    pcall(function()
        if watermarkGui then
            local label = watermarkGui:FindFirstChild("RedzWatermark")
            if not label then label = watermarkGui:FindFirstChildOfClass("TextLabel") end
            if label then
                label.Text = "REDZ  |  " .. SKY_PRESETS[currentSkyPreset].name
                task.delay(2, function()
                    if label then label.Text = "REDZ UNLOCK  |  60 FPS" end
                end)
            end
        end
    end)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.RightControl or input.KeyCode == Enum.KeyCode.Insert then
        if input.UserInputType == Enum.UserInputType.Keyboard then
            visualsEnabled = not visualsEnabled
            if visualsEnabled then
                applySkyPreset(currentSkyPreset)
                applyDarkTextures(true)
                removeBlur()
            else
                removeSkyPreset()
            end
            pcall(function()
                if watermarkGui then
                    local label = watermarkGui:FindFirstChildOfClass("TextLabel")
                    if label and label.Name ~= "PingLabel" then
                        label.Text = "REDZ  |  " .. (visualsEnabled and "ON" or "OFF")
                        task.delay(1.5, function()
                            if label then label.Text = "REDZ UNLOCK  |  60 FPS" end
                        end)
                    end
                end
            end)
        end
    end
    if input.KeyCode == Enum.KeyCode.R then
        if input.UserInputType == Enum.UserInputType.Keyboard and visualsEnabled then
            cycleSkyPreset()
        end
    end
end)

-- ============================================================================
-- MOBILE TOGGLE BUTTON (Touch)
-- ============================================================================
if UserInputService.TouchEnabled then
    task.spawn(function()
        task.wait(2)
        pcall(function()
            local btn = Instance.new("ImageButton")
            btn.Name = "RedzToggleBtn"
            btn.Size = UDim2.new(0, 50, 0, 50)
            btn.Position = UDim2.new(0.5, -25, 0.88, -25)
            btn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
            btn.BackgroundTransparency = 0.35
            btn.BorderSizePixel = 0
            btn.Image = "rbxassetid://10644988134"
            btn.ImageTransparency = 0.25
            btn.Parent = player:WaitForChild("PlayerGui")

            local presetLabel = Instance.new("TextLabel")
            presetLabel.Name = "RedzPresetLabel"
            presetLabel.Size = UDim2.new(0, 90, 0, 20)
            presetLabel.Position = UDim2.new(0.5, -45, 0, -22)
            presetLabel.BackgroundTransparency = 0.6
            presetLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            presetLabel.BorderSizePixel = 0
            presetLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
            presetLabel.Text = SKY_PRESETS[currentSkyPreset].name
            presetLabel.TextSize = 10
            presetLabel.Font = Enum.Font.SourceSansBold
            presetLabel.Parent = btn

            local dragging, dragStart, btnStart
            local touchBeganTime = 0
            local wasLongPress = false

            btn.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    dragStart = input.Position
                    btnStart = btn.Position
                    touchBeganTime = tick()
                    wasLongPress = false
                end
            end)
            btn.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.Touch then
                    local delta = input.Position - dragStart
                    btn.Position = UDim2.new(btnStart.X.Scale, btnStart.X.Offset + delta.X, btnStart.Y.Scale, btnStart.Y.Offset + delta.Y)
                    if (input.Position - dragStart).Magnitude > 15 then
                        wasLongPress = true
                    end
                end
            end)
            btn.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                    local held = tick() - touchBeganTime
                    local delta = (input.Position - dragStart).Magnitude
                    if delta < 20 and not wasLongPress then
                        if held >= 0.5 then
                            cycleSkyPreset()
                            presetLabel.Text = SKY_PRESETS[currentSkyPreset].name
                        else
                            visualsEnabled = not visualsEnabled
                            if visualsEnabled then
                                applySkyPreset(currentSkyPreset)
                                applyDarkTextures(true)
                                removeBlur()
                                btn.BackgroundTransparency = 0.35
                            else
                                removeSkyPreset()
                                btn.BackgroundTransparency = 0.7
                            end
                        end
                    end
                end
            end)
        end)
    end)
end

-- ============================================================================
-- VIEWPROFILE HOOK
-- ============================================================================
pcall(function()
    local VP = require(player.PlayerScripts.Modules.Pages.ViewProfile)
    if VP and VP.Fetch then
        local origFetchVP = VP.Fetch
        VP.Fetch = function(self, targetPlayer)
            viewingProfile = targetPlayer
            return origFetchVP(self, targetPlayer)
        end
    end
end)

-- ============================================================================
-- SINGLE COMBINED __NAMECALL HOOK
-- ============================================================================
if hookmetamethod then
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local dataRemotes = remotes and remotes:FindFirstChild("Data")
    local equipRemote = dataRemotes and dataRemotes:FindFirstChild("EquipCosmetic")
    local favoriteRemote = dataRemotes and dataRemotes:FindFirstChild("FavoriteCosmetic")
    local replicationRemotes = remotes and remotes:FindFirstChild("Replication")
    local fighterRemotes = replicationRemotes and replicationRemotes:FindFirstChild("Fighter")
    local useItemRemote = fighterRemotes and fighterRemotes:FindFirstChild("UseItem")
    local reconnectAttempts = 0

    local oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        local args = {...}

        -- Kick interception (auto-reconnect)
        if method == "Kick" then
            task.spawn(function()
                if reconnectAttempts < 3 then
                    reconnectAttempts = reconnectAttempts + 1
                    if NotificationLib then
                        NotificationLib:Notify("Reconectando", "Tentativa " .. reconnectAttempts .. "/3", 2)
                    end
                    task.wait(2)
                    pcall(function() TeleportService:Teleport(game.PlaceId, player) end)
                end
            end)
            return
        end

        if method ~= "FireServer" then return oldNamecall(self, ...) end

        -- useItemRemote tracking
        if useItemRemote and self == useItemRemote then
            local objectID = args[1]
            if FighterController then
                pcall(function()
                    local fighter = FighterController:GetFighter(player)
                    if fighter and fighter.Items then
                        for _, item in pairs(fighter.Items) do
                            if item.Get and item:Get("ObjectID") == objectID then lastUsedWeapon = item.Name break end
                        end
                    end
                end)
            end
        end

        -- EquipCosmetic
        if equipRemote and self == equipRemote then
            local weaponName, cosmeticType, cosmeticName, options = args[1], args[2], args[3], args[4] or {}
            local cosmetic = cosmeticName and CosmeticLibrary.Cosmetics[cosmeticName]

            if cosmeticName and cosmeticName ~= "None" and cosmeticName ~= "" then
                local inventory = DataController:Get("CosmeticInventory")
                if inventory and rawget(inventory, cosmeticName) then return oldNamecall(self, ...) end
            end

            -- Finisher
            if cosmetic and isFinisher(cosmetic, cosmeticName) then
                finEquipped[weaponName] = finEquipped[weaponName] or {}
                if not cosmeticName or cosmeticName == "None" or cosmeticName == "" then
                    for ct, cd in pairs(finEquipped[weaponName]) do
                        local c = CosmeticLibrary.Cosmetics[cd.Name]
                        if c and isFinisher(c, cd.Name) then finEquipped[weaponName][ct] = nil end
                    end
                    if not next(finEquipped[weaponName]) then finEquipped[weaponName] = nil end
                else
                    local actualType = cosmetic.Type or cosmeticType
                    local cloned = cloneCosmetic(cosmeticName, actualType, {inverted = options.IsInverted, favoritesOnly = options.OnlyUseFavorites})
                    if cloned then finEquipped[weaponName][actualType] = cloned end
                end
                finisherConfigDirty = true
                finisherCacheDirty = true
                task.defer(function() pcall(function() DataController.CurrentData:Replicate("WeaponInventory") end) end)
                return
            end

            -- Dance / Emote
            if cosmeticType == "Dance" or cosmeticType == "Emote" or (cosmeticName and (cosmeticName:lower():find("dance") or cosmeticName:lower():find("emote"))) then
                equipped.Dances = equipped.Dances or {}
                if not cosmeticName or cosmeticName == "None" or cosmeticName == "" then
                    equipped.Dances[cosmeticType] = nil
                else
                    local cloned = cloneCosmetic(cosmeticName, cosmeticType, {inverted = options.IsInverted, favoritesOnly = options.OnlyUseFavorites})
                    if cloned then equipped.Dances[cosmeticType] = cloned end
                end
                task.defer(function()
                    pcall(function() DataController.CurrentData:Replicate("CosmeticInventory") end)
                    task.wait(0.2)
                    saveConfig()
                end)
                return
            end

            -- Skin / Charm / Wrap
            if cosmeticType ~= "Skin" and cosmeticType ~= "Charm" and cosmeticType ~= "Wrap" and cosmeticType ~= "Wrapping" then
                return oldNamecall(self, ...)
            end
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

        -- FavoriteCosmetic
        if favoriteRemote and self == favoriteRemote then
            local cosmetic = CosmeticLibrary.Cosmetics[args[2]]
            if not cosmetic then return oldNamecall(self, ...) end
            local weapon, name, isFav = args[1], args[2], args[3]

            -- Finisher favorites
            if isFinisher(cosmetic, name) then
                finFavorites[weapon] = finFavorites[weapon] or {}
                finFavorites[weapon][name] = isFav or nil
                finisherConfigDirty = true
                task.spawn(function() pcall(function() DataController.CurrentData:Replicate("FavoritedCosmetics") end) end)
                return
            end

            -- Skin / Charm / Dance / Emote / Wrap favorites
            local t = cosmetic.Type or ""
            if t == "Skin" or t == "Charm" or t == "Dance" or t == "Emote" or t == "Wrap" or t == "Wrapping"
                or name:lower():find("charm") or name:lower():find("dance") or name:lower():find("emote") or name:lower():find("wrap") then
                favorites[weapon] = favorites[weapon] or {}
                favorites[weapon][name] = isFav or nil
                saveConfig()
                task.spawn(function() pcall(function() DataController.CurrentData:Replicate("FavoritedCosmetics") end) end)
                return
            end
        end

        return oldNamecall(self, ...)
    end)
end

-- ============================================================================
-- INIT
-- ============================================================================
loadConfig()
detectFinisherTypes()
loadFinisherConfig()

if visualsEnabled then
    task.spawn(function()
        task.wait(0.5)
        applySkyPreset(currentSkyPreset)
        applyDarkTextures(true)
        removeBlur()
    end)
end

createWatermark()

local finisherTypeCount = 0
if finisherTypes then
    for _ in pairs(finisherTypes) do finisherTypeCount = finisherTypeCount + 1 end
end

if NotificationLib then
    NotificationLib:Notify("REDZ Unlock+Finishers", "Carregado! " .. finisherTypeCount .. " tipos de finisher", 4)
end

return "REDZ Unlock All + Finishers + Visuals carregado com sucesso"
