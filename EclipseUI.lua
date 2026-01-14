--[[
    HEADLESS AFSE SCRIPT
    No UI - Communicates with External Overlay via Files
    
    SETUP: Set SHARED_PATH to match your overlay's folder!
]]

-- ============================================
-- CONFIGURATION
-- ============================================
local SHARED_PATH = getgenv().DOUGY_SHARED_PATH or "C:/Users/" .. game:GetService("Players").LocalPlayer.Name .. "/Documents/DougyHub"

if getgenv().DOUGY_SHARED_PATH then
    SHARED_PATH = getgenv().DOUGY_SHARED_PATH
end

-- ============================================
-- FILE NAMES
-- ============================================
local STATUS_FILE = "dougy_status.json"
local SETTINGS_FILE = "dougy_settings.json"
local COMMANDS_FILE = "dougy_commands.json"
local UPDATE_INTERVAL = 1

-- ============================================
-- SERVICES
-- ============================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

-- ============================================
-- GAMEDATA
-- ============================================
local GameData = nil
local function loadGameData()
    if GameData then return true end
    for attempt = 1, 10 do
        local ok, result = pcall(function()
            local modules = ReplicatedStorage:FindFirstChild("Modules")
            if modules then
                local gameDataModule = modules:FindFirstChild("GameData")
                if gameDataModule then
                    return require(gameDataModule)
                end
            end
            return nil
        end)
        if ok and result then
            GameData = result
            return true
        end
        task.wait(0.5)
    end
    return false
end

-- PlaceId check
local AFSE_PLACE_IDS = {
    17217963498,
    130247632398296,
}

local function isAFSE()
    local currentPlaceId = game.PlaceId
    for _, id in ipairs(AFSE_PLACE_IDS) do
        if currentPlaceId == id then
            return true
        end
    end
    return false
end

local function shouldBeConnected()
    if not isAFSE() then return false end
    if not Players or not Players.LocalPlayer then return false end
    if Players.LocalPlayer.Parent == nil then return false end
    return true
end

local startTime = os.time()
local hasSentDisconnect = false

-- Forward declaration
local writeStatus

local function sendDisconnected(reason)
    if hasSentDisconnect then return end
    hasSentDisconnect = true
    writeStatus({
        connected = false,
        game = "AFSE",
        placeId = game.PlaceId,
        player = Players.LocalPlayer and Players.LocalPlayer.Name or "",
        uptime = os.time() - startTime,
        timestamp = os.time(),
        sharedPath = SHARED_PATH,
        disconnectReason = reason or "LeftGame"
    })
end

-- Check PlaceId
local currentPlaceId = game.PlaceId
print("[Headless] Checking PlaceId: " .. tostring(currentPlaceId))

if not isAFSE() then
    warn("[Headless] Wrong game! Current PlaceId: " .. tostring(currentPlaceId))
    warn("[Headless] Supported PlaceIds: 17217963498, 130247632398296")
    return
end

print("[Headless] PlaceId check passed! Starting script...")

-- Check for file functions
if not writefile or not readfile then
    warn("[Headless] Your executor doesn't support file operations!")
    return
end

-- ============================================
-- FILE PATH HELPERS
-- ============================================
local function getFullPath(filename)
    return SHARED_PATH .. "/" .. filename
end

-- ============================================
-- STATE
-- ============================================
local settings = {
    -- Training
    autoTrainStrength = false,
    autoTrainDurability = false,
    autoTrainChakra = false,
    autoTrainSword = false,
    autoTrainSpeed = false,
    autoTrainAgility = false,
    
    -- Specials
    autoSummonStand = false,
    autoSummonKagune = false,
    autoSummonQuirk = false,
    autoSummonGrimoire = false,
    autoSummonBloodline = false,
    targetSpecialStand = nil,
    targetSpecialKagune = nil,
    targetSpecialQuirk = nil,
    targetSpecialGrimoire = nil,
    targetSpecialBloodline = nil,
    
    -- Champions
    autoSummonChampions = false,
    selectedChampionPodKey = nil,
    autoEquipChampion = false,
    selectedChampion = nil,
    autoSellRarity = 0,
    
    -- Zones
    loopBestZone = false,
    selectedTPStat = "Strength",
    showZoneVisuals = false,
    
    -- Auto use
    autoUseEnabled = false,
    autoUseKeys = {},
    
    -- World
    autoChikaraFarm = false,
    
    -- Mob farm
    mobFarmEnabled = false,
    selectedMob = nil,
    mobHitType = "Fist",
    mobTPPosition = "Front",
    mobTPDistance = 2,
    
    -- Webhooks
    webhookUrl = "",
    webhookOnSpecial = false,
    webhookOnChampion = false,
    
    -- Performance
    lowGraphics = false,
    fpsCap = 60
}

local isRunning = true
local connections = {}
local lastDataRefresh = 0
local cachedChampionPods = {}
local cachedSpecials = {
    Stands = {},
    Kagunes = {},
    Quirks = {},
    Grimoires = {},
    Bloodlines = {}
}
local cachedMobs = {}
local lastAutoSellRarity = settings.autoSellRarity
local zoneVisuals = {}

-- ============================================
-- JSON HELPERS
-- ============================================
local function safeEncode(data)
    local success, result = pcall(function()
        return HttpService:JSONEncode(data)
    end)
    return success and result or "{}"
end

local function safeDecode(str)
    local success, result = pcall(function()
        return HttpService:JSONDecode(str)
    end)
    return success and result or nil
end

-- ============================================
-- FILE COMMUNICATION
-- ============================================

function writeStatus(statusData)
    local success, err = pcall(function()
        local filePath = getFullPath(STATUS_FILE)
        writefile(filePath, safeEncode(statusData))
    end)
    if not success then
        warn("[Headless] Failed to write status: " .. tostring(err))
    end
end

local function readSettings()
    pcall(function()
        local filePath = getFullPath(SETTINGS_FILE)
        if isfile and isfile(filePath) then
            local content = readfile(filePath)
            local decoded = safeDecode(content)
            if decoded then
                for key, value in pairs(decoded) do
                    settings[key] = value
                end
            end
        end
    end)
end

-- ============================================
-- REMOTES
-- ============================================
local RemoteFunction, RemoteEvent, TrainRemote

local function loadRemotes()
    print("[Headless] Loading remotes...")
    for attempt = 1, 15 do
        pcall(function()
            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            if remotes then
                RemoteFunction = remotes:FindFirstChild("RemoteFunction")
                RemoteEvent = remotes:FindFirstChild("RemoteEvent")
                TrainRemote = remotes:FindFirstChild("Train") or RemoteEvent
            end
        end)
        if RemoteFunction and RemoteEvent then
            print("[Headless] ✓ Remotes loaded successfully!")
            print("[Headless]   - RemoteFunction: " .. tostring(RemoteFunction))
            print("[Headless]   - RemoteEvent: " .. tostring(RemoteEvent))
            break
        end
        if attempt == 15 then
            print("[Headless] ✗ Failed to load remotes after 15 attempts")
        end
        task.wait(0.5)
    end
end

-- ============================================
-- STATS / ZONES
-- ============================================
local statNames = {
    [1] = "Strength",
    [2] = "Durability",
    [3] = "Chakra",
    [4] = "Sword",
    [5] = "Agility",
    [6] = "Speed"
}

local function getTPStatId(name)
    local map = {
        Strength = 1,
        Durability = 2,
        Chakra = 3,
        Sword = 4,
        Agility = 5,
        Speed = 6
    }
    return map[name] or 1
end

local function getStatPower(statId)
    local stats = LocalPlayer:FindFirstChild("Stats")
    if stats then
        local statValue = stats:FindFirstChild(tostring(statId))
        if statValue and statValue:IsA("ValueBase") then
            return statValue.Value
        end
    end
    return 0
end

local function getStatsSnapshot()
    return {
        Strength = getStatPower(1),
        Durability = getStatPower(2),
        Chakra = getStatPower(3),
        Sword = getStatPower(4),
        Agility = getStatPower(5),
        Speed = getStatPower(6)
    }
end

local function getPower()
    local success, result = pcall(function()
        local powerValue = LocalPlayer:FindFirstChild("Power")
        if powerValue then
            return powerValue.Value
        end
        return 0
    end)
    return success and result or 0
end

local function getCurrentZone()
    local success, result = pcall(function()
        local zoneValue = LocalPlayer:FindFirstChild("CurrentZone")
        if zoneValue then
            return zoneValue.Value
        end
        return "Unknown"
    end)
    return success and result or "Unknown"
end

local function canAccessZone(zone)
    if not zone or not zone.Data then return false end
    local statId = zone.Data.Stat or 1
    local requires = zone.Data.Requires or 0
    local playerStatPower = getStatPower(statId)
    return playerStatPower >= requires
end

local function getZonePosition(zone)
    if not zone or not zone.Position then return nil end
    local pos = zone.Position
    if typeof(pos) == "Vector3" then
        return pos
    end
    return Vector3.new(pos.X or pos[1] or 0, pos.Y or pos[2] or 0, pos.Z or pos[3] or 0)
end

local function findBestZone(statId)
    loadGameData()
    if not GameData then 
        print("[Headless] GameData not loaded")
        return nil 
    end
    if not GameData.TrainingAreas then 
        print("[Headless] No TrainingAreas in GameData")
        return nil 
    end
    
    local best = nil
    local zoneCount = 0
    local accessibleCount = 0
    
    for _, zone in pairs(GameData.TrainingAreas) do
        if zone.Data and zone.Data.Stat == statId then
            zoneCount = zoneCount + 1
            if canAccessZone(zone) then
                accessibleCount = accessibleCount + 1
                if not best or (zone.Data.Multiply or 0) > (best.Data.Multiply or 0) then
                    best = zone
                end
            end
        end
    end
    
    if best then
        print(string.format("[Headless] Found best zone for stat %d: %s (x%d)", 
            statId, best.Data.AreaName or "Unknown", best.Data.Multiply or 1))
    else
        print(string.format("[Headless] No accessible zone for stat %d (found %d zones, %d accessible)", 
            statId, zoneCount, accessibleCount))
    end
    
    return best
end

local function teleportToZone(zone)
    local char = LocalPlayer.Character
    if not char then 
        print("[Headless] Cannot TP - no character")
        return false 
    end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then 
        print("[Headless] Cannot TP - no HumanoidRootPart")
        return false 
    end
    local zoneCenter = getZonePosition(zone)
    if not zoneCenter then 
        print("[Headless] Cannot TP - zone has no position")
        return false 
    end
    
    local targetCFrame = CFrame.new(zoneCenter + Vector3.new(0, 5, 0))
    hrp.CFrame = targetCFrame
    pcall(function()
        hrp.Velocity = Vector3.new(0, 0, 0)
        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    end)
    print(string.format("[Headless] Teleported to zone at %.0f, %.0f, %.0f", 
        zoneCenter.X, zoneCenter.Y, zoneCenter.Z))
    return true
end

-- ============================================
-- ZONE VISUALS
-- ============================================
local function clearZoneVisuals()
    for _, visual in pairs(zoneVisuals) do
        pcall(function() visual:Destroy() end)
    end
    zoneVisuals = {}
end

local function createZoneVisuals()
    clearZoneVisuals()
    loadGameData()
    if not GameData or not GameData.TrainingAreas then return end
    
    local colors = {
        [1] = Color3.fromRGB(255, 100, 100), -- Strength (Red)
        [2] = Color3.fromRGB(100, 150, 255), -- Durability (Blue)
        [3] = Color3.fromRGB(100, 255, 100), -- Chakra (Green)
        [4] = Color3.fromRGB(200, 200, 200), -- Sword (Gray)
        [5] = Color3.fromRGB(255, 200, 100), -- Agility (Orange)
        [6] = Color3.fromRGB(255, 255, 100), -- Speed (Yellow)
    }
    
    for _, zone in pairs(GameData.TrainingAreas) do
        if zone.Position and zone.Data then
            local statId = zone.Data.Stat or 1
            local zonePos = getZonePosition(zone)
            if zonePos then
                local canAccess = canAccessZone(zone)
                local color = colors[statId] or Color3.new(1, 1, 1)
                
                local part = Instance.new("Part")
                part.Name = "ZoneVisual_" .. (zone.Data.AreaName or "Unknown")
                part.Anchored = true
                part.CanCollide = false
                part.Size = Vector3.new(zone.Data.Magnitude or 20, 0.5, zone.Data.Magnitude or 20)
                part.Position = zonePos
                part.Color = color
                part.Transparency = canAccess and 0.7 or 0.9
                part.Material = Enum.Material.Neon
                part.Parent = workspace
                
                local billboard = Instance.new("BillboardGui")
                billboard.Size = UDim2.new(0, 150, 0, 50)
                billboard.StudsOffset = Vector3.new(0, 5, 0)
                billboard.AlwaysOnTop = true
                billboard.Parent = part
                
                local label = Instance.new("TextLabel")
                label.Size = UDim2.new(1, 0, 1, 0)
                label.BackgroundTransparency = 1
                label.Text = string.format("%s\n%dx (%s)", zone.Data.AreaName or "?", zone.Data.Multiply or 1, statNames[statId] or "?")
                label.TextColor3 = Color3.new(1, 1, 1)
                label.TextStrokeTransparency = 0.5
                label.Font = Enum.Font.GothamBold
                label.TextSize = 14
                label.Parent = billboard
                
                table.insert(zoneVisuals, part)
            end
        end
    end
end

-- ============================================
-- CHAMPIONS / SPECIALS
-- ============================================
local function getChampionPodsList()
    local podsList = {}
    loadGameData()
    if not GameData or not GameData.ChampPods then return podsList end
    for podKey, podData in pairs(GameData.ChampPods) do
        table.insert(podsList, {
            key = podKey,
            price = podData.Price or 0,
            currency = podData.Currency or "Chikara"
        })
    end
    table.sort(podsList, function(a, b)
        return tonumber(a.key) < tonumber(b.key)
    end)
    return podsList
end

local function getSpecialList(specialType)
    local specials = {}
    loadGameData()
    if not GameData or not GameData.Specials then return specials end
    local specialData = GameData.Specials[specialType]
    if not specialData or not specialData.List then return specials end
    for itemId, itemData in pairs(specialData.List) do
        if itemData.Name then
            table.insert(specials, {
                id = tonumber(itemId) or 0,
                name = itemData.Name
            })
        end
    end
    table.sort(specials, function(a, b) return a.name < b.name end)
    return specials
end

local function isSpecialOwned(itemId)
    local specialsList = LocalPlayer:FindFirstChild("SpecialsList")
    if not specialsList then return false end
    local specialValue = specialsList:FindFirstChild(tostring(itemId))
    if specialValue and (specialValue:IsA("IntValue") or specialValue:IsA("NumberValue")) then
        return specialValue.Value == 1
    end
    return false
end

local function getChampionRarity(championId)
    loadGameData()
    if not GameData or not GameData.Champions then return nil end
    local champData = GameData.Champions[tostring(championId)]
    return champData and champData.Rarity or nil
end

local function getOwnedChampions()
    local champions = {}
    pcall(function()
        local champFolder = LocalPlayer:WaitForChild("Champions", 5)
        if champFolder then
            for _, champ in ipairs(champFolder:GetChildren()) do
                local champId = tonumber(champ.Name) or 0
                local champName = "Champion " .. champ.Name
                loadGameData()
                if GameData and GameData.Champions then
                    local champData = GameData.Champions[tostring(champId)]
                    if champData and champData.Name then
                        champName = champData.Name
                    end
                end
                table.insert(champions, {
                    id = champId,
                    name = champName
                })
            end
        end
    end)
    return champions
end

local function isChampionEquipped(championId)
    local equipped = false
    pcall(function()
        local equippedValue = LocalPlayer:FindFirstChild("ChampionEquipped")
        if equippedValue then
            equipped = tonumber(equippedValue.Value) == tonumber(championId)
        end
    end)
    return equipped
end

local function equipChampion(championId)
    pcall(function()
        if RemoteFunction then
            local champFolder = LocalPlayer:FindFirstChild("Champions")
            if champFolder then
                local champInstance = champFolder:FindFirstChild(tostring(championId))
                if champInstance then
                    RemoteFunction:InvokeServer("SummonChamp", champInstance)
                end
            end
        end
    end)
end

local function sellChampion(championInstance)
    if not RemoteEvent then return false end
    local ok = pcall(function()
        RemoteEvent:FireServer("SellChamp", championInstance)
    end)
    return ok
end

local autoSellConnection = nil
local function setupAutoSell()
    if autoSellConnection then
        autoSellConnection:Disconnect()
        autoSellConnection = nil
    end
    local rarityThreshold = tonumber(settings.autoSellRarity) or 0
    if rarityThreshold > 0 then
        local championsFolder = LocalPlayer:FindFirstChild("Champions")
        if championsFolder then
            autoSellConnection = championsFolder.ChildAdded:Connect(function(championValue)
                if championValue:IsA("NumberValue") then
                    task.wait(0.5)
                    local championId = tonumber(championValue.Name) or 0
                    local rarity = getChampionRarity(championId)
                    if rarity and rarity <= rarityThreshold then
                        sellChampion(championValue)
                    end
                end
            end)
        end
    end
end

-- ============================================
-- TRAINING
-- ============================================
local function doTrainStat(statId)
    pcall(function()
        if TrainRemote then
            TrainRemote:FireServer("Train", statId)
        elseif RemoteEvent then
            RemoteEvent:FireServer("Train", statId)
        end
    end)
end

-- ============================================
-- AUTO USE (KEYS)
-- ============================================
local function pressKey(keyName)
    local keyCode = Enum.KeyCode[string.upper(keyName)]
    if not keyCode then return end
    pcall(function()
        local ok = pcall(function()
            local vim = game:GetService("VirtualInputManager")
            vim:SendKeyEvent(true, keyCode, false, game)
            task.wait(0.03)
            vim:SendKeyEvent(false, keyCode, false, game)
        end)
        if not ok then
            pcall(function()
                UserInputService:SendKeyEvent(true, keyCode, false, game)
                task.wait(0.03)
                UserInputService:SendKeyEvent(false, keyCode, false, game)
            end)
        end
    end)
end

-- ============================================
-- NPC INTERACTIONS
-- ============================================
local function interactWithNPC(npcName)
    -- Try to find NPC in workspace
    local function findNPC()
        local scriptable = workspace:FindFirstChild("Scriptable")
        if not scriptable then return nil end
        
        local npcFolder = scriptable:FindFirstChild("NPC")
        if not npcFolder then return nil end
        
        local questFolder = npcFolder:FindFirstChild("Quest")
        if not questFolder then return nil end
        
        -- Try exact match first
        local npcModel = questFolder:FindFirstChild(npcName)
        if npcModel then return npcModel end
        
        -- Try to find by name within children
        for _, child in ipairs(questFolder:GetChildren()) do
            if child.Name == npcName or child.Name:find(npcName) then
                return child
            end
        end
        
        return nil
    end
    
    local npc = findNPC()
    if not npc then
        print("[Headless] NPC not found: " .. npcName)
        return false
    end
    
    -- Find click detector
    local clickDetector = nil
    local clickBox = npc:FindFirstChild("ClickBox")
    if clickBox then
        clickDetector = clickBox:FindFirstChildOfClass("ClickDetector")
    end
    
    if not clickDetector then
        clickDetector = npc:FindFirstChildOfClass("ClickDetector", true)
    end
    
    if not clickDetector then
        print("[Headless] No ClickDetector found for NPC: " .. npcName)
        return false
    end
    
    -- Fire the click detector
    if fireclickdetector then
        fireclickdetector(clickDetector)
        print("[Headless] Interacted with NPC: " .. npcName)
        return true
    end
    
    -- Fallback: Try ProximityPrompt
    local proximityPrompt = npc:FindFirstChildOfClass("ProximityPrompt", true)
    if proximityPrompt and fireproximityprompt then
        fireproximityprompt(proximityPrompt)
        print("[Headless] Interacted with NPC via ProximityPrompt: " .. npcName)
        return true
    end
    
    print("[Headless] fireclickdetector not available")
    return false
end

-- ============================================
-- CHIKARA CRATES
-- ============================================
local function findChikaraCrates()
    local crates = {}
    local chikaraBoxesFolder = workspace:FindFirstChild("Scriptable")
    if chikaraBoxesFolder then
        local chikaraBoxes = chikaraBoxesFolder:FindFirstChild("ChikaraBoxes")
        if chikaraBoxes then
            for _, child in pairs(chikaraBoxes:GetChildren()) do
                if child.Name == "ChikaraCrate" then
                    local clickBox = child:FindFirstChild("ClickBox")
                    if clickBox then
                        local clickDetector = clickBox:FindFirstChild("ClickDetector")
                        if clickDetector then
                            table.insert(crates, clickDetector)
                        end
                    end
                end
            end
        end
    end
    return crates
end

-- ============================================
-- WEBHOOKS
-- ============================================
local function sendWebhook(title, description, color)
    if not settings.webhookUrl or settings.webhookUrl == "" then return end
    
    pcall(function()
        local data = {
            embeds = {{
                title = title,
                description = description,
                color = color or 5763719,
                footer = { text = "Dougy's Hub • " .. LocalPlayer.Name },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }}
        }
        
        local requestFunc = request or http_request or syn and syn.request or http and http.request
        if requestFunc then
            requestFunc({
                Url = settings.webhookUrl,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = HttpService:JSONEncode(data)
            })
        end
    end)
end

-- ============================================
-- MOB FARM
-- ============================================
local function getMobsList()
    local mobs = {}
    loadGameData()
    if GameData and GameData.Enemies then
        for enemyId, enemyData in pairs(GameData.Enemies) do
            if enemyData.Name then
                table.insert(mobs, {
                    id = enemyId,
                    name = enemyData.Name
                })
            end
        end
    end
    table.sort(mobs, function(a, b) return a.name < b.name end)
    return mobs
end

local function findMob(mobId)
    local enemies = workspace:FindFirstChild("Enemies")
    if not enemies then return nil end
    
    for _, enemy in ipairs(enemies:GetChildren()) do
        if enemy:GetAttribute("EnemyId") == mobId or enemy.Name == mobId then
            local humanoid = enemy:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                return enemy
            end
        end
    end
    return nil
end

local function teleportToMob(mob)
    local char = LocalPlayer.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    local mobHRP = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("Torso") or mob.PrimaryPart
    if not mobHRP then return false end
    
    local offset = Vector3.new(0, 0, settings.mobTPDistance or 2)
    local position = settings.mobTPPosition or "Front"
    
    if position == "Behind" then
        offset = mobHRP.CFrame.LookVector * -(settings.mobTPDistance or 2)
    elseif position == "Above" then
        offset = Vector3.new(0, settings.mobTPDistance or 2, 0)
    else -- Front
        offset = mobHRP.CFrame.LookVector * (settings.mobTPDistance or 2)
    end
    
    hrp.CFrame = CFrame.new(mobHRP.Position + offset, mobHRP.Position)
    return true
end

-- ============================================
-- FPS CAP
-- ============================================
local function applyFpsCap(value)
    value = math.clamp(tonumber(value) or 60, 10, 500)
    local names = { "setfpscap", "set_fps_cap", "fpscap", "setfps" }
    
    for _, n in ipairs(names) do
        local fn = rawget(_G, n)
        if type(fn) == "function" then
            if pcall(fn, value) then return true end
        end
    end
    
    if getgenv then
        for _, n in ipairs(names) do
            local fn = rawget(getgenv(), n)
            if type(fn) == "function" then
                if pcall(fn, value) then return true end
            end
        end
    end
    
    if syn and type(syn.set_fps_cap) == "function" then
        if pcall(syn.set_fps_cap, value) then return true end
    end
    
    return false
end

-- ============================================
-- LOW GRAPHICS
-- ============================================
local function applyLowGraphics()
    pcall(function()
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("Part") or v:IsA("MeshPart") or v:IsA("UnionOperation") then
                v.Material = Enum.Material.SmoothPlastic
                v.Reflectance = 0
            elseif v:IsA("Decal") or v:IsA("Texture") then
                v.Transparency = 1
            elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
                v.Enabled = false
            elseif v:IsA("Fire") or v:IsA("SpotLight") or v:IsA("Smoke") then
                v.Enabled = false
            end
        end
    end)
end

-- ============================================
-- SUMMON SPECIALS
-- ============================================
local function summonSpecial(specialType)
    if not RemoteFunction then
        print("[Headless] RemoteFunction not loaded - cannot summon " .. tostring(specialType))
        return false
    end
    
    local success, err = pcall(function()
        -- Try both argument orders since different game versions might use different formats
        RemoteFunction:InvokeServer("BuyContainer", specialType, 1)
    end)
    
    if not success then
        print("[Headless] summonSpecial error: " .. tostring(err))
    end
    return success
end

-- ============================================
-- COMMAND PROCESSOR
-- ============================================
local function readCommands()
    pcall(function()
        local filePath = getFullPath(COMMANDS_FILE)
        if isfile and isfile(filePath) then
            local content = readfile(filePath)
            local commands = safeDecode(content)
            if commands and type(commands) == "table" then
                for _, cmd in ipairs(commands) do
                    if cmd.action == "setting" then
                        settings[cmd.key] = cmd.value
                        
                        if cmd.key == "autoSellRarity" then
                            setupAutoSell()
                        elseif cmd.key == "showZoneVisuals" then
                            if cmd.value then
                                createZoneVisuals()
                            else
                                clearZoneVisuals()
                            end
                        elseif cmd.key == "fpsCap" then
                            applyFpsCap(cmd.value)
                        elseif cmd.key == "lowGraphics" and cmd.value then
                            applyLowGraphics()
                        end
                        
                    elseif cmd.action == "tpBestZone" then
                        local statId = getTPStatId(cmd.stat or settings.selectedTPStat)
                        local best = findBestZone(statId)
                        if best then
                            teleportToZone(best)
                            print("[Headless] Teleported to best zone for " .. (cmd.stat or settings.selectedTPStat))
                        end
                        
                    elseif cmd.action == "interactNPC" then
                        if cmd.name then
                            interactWithNPC(cmd.name)
                        end
                        
                    elseif cmd.action == "pullChampionOnce" then
                        if cmd.podKey and RemoteFunction then
                            pcall(function()
                                local key = tonumber(cmd.podKey) or cmd.podKey
                                RemoteFunction:InvokeServer("BuyContainerChamp", key)
                                print("[Headless] Pulled champion from pod: " .. tostring(key))
                            end)
                        end
                        
                    elseif cmd.action == "pullSpecialOnce" then
                        if cmd.specialType and RemoteFunction then
                            pcall(function()
                                RemoteFunction:InvokeServer("BuyContainer", cmd.specialType, 1)
                                print("[Headless] Pulled from: " .. tostring(cmd.specialType))
                            end)
                        end
                        
                    elseif cmd.action == "testWebhook" then
                        sendWebhook("Test Webhook", "This is a test from Dougy's Hub!", 5763719)
                        
                    elseif cmd.action == "findAllMobs" then
                        cachedMobs = getMobsList()
                        print("[Headless] Found " .. #cachedMobs .. " mobs")
                    end
                end
            end
            -- Clear commands after reading
            writefile(filePath, "[]")
        end
    end)
end

-- ============================================
-- INITIALIZATION
-- ============================================

print("[Headless] Starting Dougy's Hub Headless Script...")
print("[Headless] Shared folder: " .. SHARED_PATH)

-- Test file access
local testFilePath = getFullPath("_test_write.txt")
local testSuccess = pcall(function()
    writefile(testFilePath, "test")
    if isfile and isfile(testFilePath) then
        local content = readfile(testFilePath)
        if content == "test" then
            print("[Headless] ✓ File operations working!")
            if delfile then
                pcall(function() delfile(testFilePath) end)
            end
        end
    end
end)
if not testSuccess then
    warn("[Headless] ✗ File write test failed!")
end

-- Load game data
loadGameData()
cachedChampionPods = getChampionPodsList()
cachedSpecials.Stands = getSpecialList("Stands")
cachedSpecials.Kagunes = getSpecialList("Kagunes")
cachedSpecials.Quirks = getSpecialList("Quirks")
cachedSpecials.Grimoires = getSpecialList("Grimoires")
cachedSpecials.Bloodlines = getSpecialList("Bloodlines")
cachedMobs = getMobsList()

-- Write initial status
writeStatus({
    connected = true,
    game = "AFSE",
    placeId = game.PlaceId,
    player = LocalPlayer.Name,
    power = getPower(),
    currentZone = getCurrentZone(),
    champions = getOwnedChampions(),
    stats = getStatsSnapshot(),
    championPods = cachedChampionPods,
    specials = cachedSpecials,
    mobs = cachedMobs,
    uptime = 0,
    timestamp = os.time(),
    sharedPath = SHARED_PATH,
    disconnectReason = nil
})

print("[Headless] Initial status written!")

-- Load remotes
loadRemotes()
setupAutoSell()

-- ============================================
-- MAIN LOOPS
-- ============================================

-- Communication loop
task.spawn(function()
    while isRunning do
        if not shouldBeConnected() then
            sendDisconnected("NotInAFSE")
            isRunning = false
            break
        end
        
        readSettings()
        readCommands()
        
        if settings.autoSellRarity ~= lastAutoSellRarity then
            setupAutoSell()
            lastAutoSellRarity = settings.autoSellRarity
        end
        
        if type(settings.autoUseKeys) ~= "table" then
            settings.autoUseKeys = {}
        end
        
        -- Refresh cached lists
        if tick() - lastDataRefresh > 30 then
            loadGameData()
            cachedChampionPods = getChampionPodsList()
            cachedSpecials.Stands = getSpecialList("Stands")
            cachedSpecials.Kagunes = getSpecialList("Kagunes")
            cachedSpecials.Quirks = getSpecialList("Quirks")
            cachedSpecials.Grimoires = getSpecialList("Grimoires")
            cachedSpecials.Bloodlines = getSpecialList("Bloodlines")
            cachedMobs = getMobsList()
            lastDataRefresh = tick()
        end
        
        -- Write status
        local status = {
            connected = true,
            game = "AFSE",
            placeId = game.PlaceId,
            player = LocalPlayer.Name,
            power = getPower(),
            currentZone = getCurrentZone(),
            champions = getOwnedChampions(),
            stats = getStatsSnapshot(),
            championPods = cachedChampionPods,
            specials = cachedSpecials,
            mobs = cachedMobs,
            uptime = os.time() - startTime,
            timestamp = os.time(),
            sharedPath = SHARED_PATH,
            disconnectReason = nil
        }
        writeStatus(status)
        
        task.wait(UPDATE_INTERVAL)
    end
end)

-- Main game loop
local lastStatTrainTimes = {}
local lastSummonTimes = {}
local lastKeyPressTime = 0
local lastChampCheck = 0
local lastChampionSummon = 0
local lastZoneLoop = 0
local lastChikaraFarm = 0
local lastMobFarm = 0
local lowGraphicsApplied = false
local lastFpsCap = 60
local autoUseIndex = 1

connections.mainLoop = RunService.Heartbeat:Connect(function()
    local now = tick()
    
    -- Auto Train Stats
    local statToggles = {
        { key = "autoTrainStrength", id = 1 },
        { key = "autoTrainDurability", id = 2 },
        { key = "autoTrainChakra", id = 3 },
        { key = "autoTrainSword", id = 4 },
        { key = "autoTrainSpeed", id = 6 },
        { key = "autoTrainAgility", id = 5 }
    }
    for _, st in ipairs(statToggles) do
        if settings[st.key] then
            lastStatTrainTimes[st.id] = lastStatTrainTimes[st.id] or 0
            if now - lastStatTrainTimes[st.id] >= 0.1 then
                doTrainStat(st.id)
                lastStatTrainTimes[st.id] = now
            end
        end
    end
    
    -- Auto Use Keys
    if settings.autoUseEnabled and type(settings.autoUseKeys) == "table" and #settings.autoUseKeys > 0 then
        if now - lastKeyPressTime >= 0.15 then
            if autoUseIndex > #settings.autoUseKeys then
                autoUseIndex = 1
            end
            local keyName = settings.autoUseKeys[autoUseIndex]
            if keyName then
                pressKey(keyName)
            end
            autoUseIndex = autoUseIndex + 1
            lastKeyPressTime = now
        end
    else
        autoUseIndex = 1
    end
    
    -- Auto Equip Champion
    if settings.autoEquipChampion and settings.selectedChampion then
        if now - lastChampCheck >= 5 then
            if not isChampionEquipped(settings.selectedChampion) then
                equipChampion(settings.selectedChampion)
            end
            lastChampCheck = now
        end
    end
    
    -- Auto Summon Specials
    local specialTypes = {
        { setting = "autoSummonStand", type = "Stands", targetKey = "targetSpecialStand" },
        { setting = "autoSummonKagune", type = "Kagunes", targetKey = "targetSpecialKagune" },
        { setting = "autoSummonQuirk", type = "Quirks", targetKey = "targetSpecialQuirk" },
        { setting = "autoSummonGrimoire", type = "Grimoires", targetKey = "targetSpecialGrimoire" },
        { setting = "autoSummonBloodline", type = "Bloodlines", targetKey = "targetSpecialBloodline" },
    }
    
    for _, special in ipairs(specialTypes) do
        if settings[special.setting] then
            lastSummonTimes[special.type] = lastSummonTimes[special.type] or 0
            local targetId = settings[special.targetKey]
            if targetId and isSpecialOwned(targetId) then
                settings[special.setting] = false
                if settings.webhookOnSpecial then
                    loadGameData()
                    local specialName = "Unknown"
                    if GameData and GameData.Specials and GameData.Specials[special.type] then
                        local itemData = GameData.Specials[special.type].List[tostring(targetId)]
                        if itemData then specialName = itemData.Name end
                    end
                    sendWebhook("🎉 Special Obtained!", "Got **" .. specialName .. "** from " .. special.type, 5763719)
                end
            else
                if now - lastSummonTimes[special.type] >= 3 then
                    summonSpecial(special.type)
                    lastSummonTimes[special.type] = now
                end
            end
        end
    end
    
    -- Auto Summon Champions
    if settings.autoSummonChampions and settings.selectedChampionPodKey then
        if now - lastChampionSummon >= 2 then
            pcall(function()
                if RemoteFunction then
                    local key = tonumber(settings.selectedChampionPodKey) or settings.selectedChampionPodKey
                    RemoteFunction:InvokeServer("BuyContainerChamp", key)
                end
            end)
            lastChampionSummon = now
        end
    end
    
    -- Loop Best Zone
    if settings.loopBestZone then
        if now - lastZoneLoop >= 5 then
            local statId = getTPStatId(settings.selectedTPStat)
            local best = findBestZone(statId)
            if best then
                teleportToZone(best)
            end
            lastZoneLoop = now
        end
    end
    
    -- Auto Chikara Farm
    if settings.autoChikaraFarm then
        if now - lastChikaraFarm >= 1 then
            lastChikaraFarm = now
            local crates = findChikaraCrates()
            for _, detector in ipairs(crates) do
                pcall(function()
                    if fireclickdetector then
                        fireclickdetector(detector)
                    end
                end)
            end
        end
    end
    
    -- Mob Farm
    if settings.mobFarmEnabled and settings.selectedMob then
        if now - lastMobFarm >= 0.5 then
            lastMobFarm = now
            local mob = findMob(settings.selectedMob)
            if mob then
                teleportToMob(mob)
                -- Attack based on hit type
                if settings.mobHitType == "Fist" then
                    pressKey("f")
                elseif settings.mobHitType == "Sword" then
                    pressKey("e")
                elseif settings.mobHitType == "Special" then
                    pressKey("r")
                end
            end
        end
    end
    
    -- Low Graphics
    if settings.lowGraphics and not lowGraphicsApplied then
        applyLowGraphics()
        lowGraphicsApplied = true
    end
    
    -- FPS Cap - reapply when value changes
    local fpsCap = tonumber(settings.fpsCap) or 60
    if fpsCap ~= lastFpsCap then
        applyFpsCap(fpsCap)
        lastFpsCap = fpsCap
        print("[Headless] FPS cap set to: " .. fpsCap)
    end
end)

-- Cleanup
LocalPlayer.AncestryChanged:Connect(function()
    sendDisconnected("PlayerRemoved")
    isRunning = false
    clearZoneVisuals()
    for _, conn in pairs(connections) do
        pcall(function() conn:Disconnect() end)
    end
end)

-- Watchdog
connections.watchdog = RunService.RenderStepped:Connect(function()
    if not isRunning then return end
    if not shouldBeConnected() then
        sendDisconnected("Watchdog")
        isRunning = false
    end
end)

print("[Headless] Script running! Check the overlay for status.")
