--[[
    HEADLESS AFSE SCRIPT
    No UI - Communicates with External Overlay via Files
    
    This script has NO detectable UI elements.
    Communication is done via files in a shared folder.
    
    SETUP: Set SHARED_PATH below to match your overlay's folder!
]]

-- ============================================
-- CONFIGURATION - CHANGE THIS TO YOUR PATH!
-- ============================================
-- This should match the path shown in the overlay app
-- Use forward slashes (/) or double backslashes (\\)
local SHARED_PATH = getgenv().DOUGY_SHARED_PATH or "C:/Users/" .. game:GetService("Players").LocalPlayer.Name .. "/Documents/DougyHub"

-- Alternative: Let the loader script set this
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

-- Only run on AFSE (multiple PlaceIds for different versions/servers)
local AFSE_PLACE_IDS = {
    17217963498,      -- Original
    130247632398296,  -- Current/Updated version
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

local hasSentDisconnect = false
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
    warn("[Headless] Required: writefile, readfile")
    return
end

-- ============================================
-- FILE PATH HELPERS
-- ============================================
local function getFullPath(filename)
    return SHARED_PATH .. "/" .. filename
end

-- Test if we can write to the shared folder
local function testFileAccess()
    local testFile = getFullPath("_test_" .. tostring(tick()) .. ".tmp")
    local success = pcall(function()
        writefile(testFile, "test")
        local content = readfile(testFile)
        delfile(testFile)
    end)
    return success
end

-- ============================================
-- STATE
-- ============================================
local settings = {
    autoFarm = false,
    autoTrain = false,
    autoTrainStrength = false,
    autoTrainDurability = false,
    autoTrainChakra = false,
    autoTrainSword = false,
    autoTrainSpeed = false,
    autoTrainAgility = false,
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
    autoSummonChampions = false,
    selectedChampionPodKey = nil,
    autoEquipChampion = false,
    selectedChampion = nil,
    autoSellRarity = 0,
    autoUseEnabled = false,
    autoUseKeys = {},
    loopBestZone = false,
    selectedTPStat = "Strength",
    showZoneVisuals = false,
    showZoneStrength = true,
    showZoneDurability = true,
    showZoneChakra = true,
    showZoneSpeed = true,
    showZoneAgility = true,
    hideLockedZones = false,
    showOnlyBestAndNext = false,
    autoChikaraFarm = false,
    lowGraphics = false
}
local isRunning = true
local connections = {}
local startTime = os.time()
local lastDataRefresh = 0
local cachedChampionPods = {}
local cachedSpecials = {
    Stands = {},
    Kagunes = {},
    Quirks = {},
    Grimoires = {},
    Bloodlines = {}
}
local lastAutoSellRarity = settings.autoSellRarity

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

-- Write status to file (Overlay reads this)
local function writeStatus(statusData)
    local success, err = pcall(function()
        local filePath = getFullPath(STATUS_FILE)
        writefile(filePath, safeEncode(statusData))
        -- Debug: Check if file was created
        if isfile and isfile(filePath) then
            -- File exists - good!
        else
            warn("[Headless] WARNING: File might not exist after write: " .. filePath)
        end
    end)
    if not success then
        warn("[Headless] Failed to write status: " .. tostring(err))
        warn("[Headless] Path: " .. getFullPath(STATUS_FILE))
        warn("[Headless] Your executor might not support absolute paths with writefile!")
    end
end

-- Read settings from file (Overlay writes this)
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

-- Read and clear commands
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
                        end
                    elseif cmd.action == "tpBestZone" then
                        local statId = getTPStatId(cmd.stat or settings.selectedTPStat)
                        local best = findBestZone(statId)
                        if best then
                            teleportToZone(best)
                        end
                    elseif cmd.action == "interactNPC" then
                        if cmd.name then
                            interactWithNPC(cmd.name)
                        end
                    elseif cmd.action == "copyZoneList" then
                        copyZoneList()
                    elseif cmd.action == "pullChampionOnce" then
                        if cmd.podKey and RemoteFunction then
                            pcall(function()
                                local key = tonumber(cmd.podKey) or cmd.podKey
                                RemoteFunction:InvokeServer("BuyContainerChamp", key)
                            end)
                        end
                    elseif cmd.action == "pullSpecialOnce" then
                        if cmd.specialType and RemoteFunction then
                            local remoteName = cmd.specialType
                            pcall(function()
                                RemoteFunction:InvokeServer("BuyContainer", remoteName, 1)
                            end)
                        end
                    end
                end
            end
            -- Clear commands after reading
            writefile(filePath, "[]")
        end
    end)
end

-- ============================================
-- GAME SPECIFIC LOGIC
-- ============================================

local RemoteFunction, RemoteEvent, TrainRemote

local function loadRemotes()
    for attempt = 1, 10 do
        pcall(function()
            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            if remotes then
                RemoteFunction = remotes:FindFirstChild("RemoteFunction")
                RemoteEvent = remotes:FindFirstChild("RemoteEvent")
                TrainRemote = remotes:FindFirstChild("Train") or RemoteEvent
            end
        end)
        if RemoteFunction and RemoteEvent then
            break
        end
        task.wait(0.5)
    end
end

-- ============================================
-- STATS / ZONES HELPERS
-- ============================================
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
    if not GameData or not GameData.TrainingAreas then return nil end
    local best = nil
    for _, zone in pairs(GameData.TrainingAreas) do
        if zone.Data and zone.Data.Stat == statId then
            if canAccessZone(zone) then
                if not best or (zone.Data.Multiply or 0) > (best.Data.Multiply or 0) then
                    best = zone
                end
            end
        end
    end
    return best
end

local function getCurrentZone()
    loadGameData()
    if not GameData or not GameData.TrainingAreas then return "Unknown" end
    local char = LocalPlayer.Character
    if not char then return "Unknown" end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return "Unknown" end
    local playerPos = hrp.Position
    for _, zone in pairs(GameData.TrainingAreas) do
        if zone.Position and zone.Data then
            local zonePos = getZonePosition(zone)
            if zonePos then
                local magnitude = zone.Data.Magnitude or 20
                local dist = (playerPos - zonePos).Magnitude
                if dist <= magnitude then
                    return zone.Data.AreaName or "Unknown"
                end
            end
        end
    end
    return "Unknown"
end

local function teleportToZone(zone)
    local char = LocalPlayer.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local zoneCenter = getZonePosition(zone)
    if not zoneCenter then return false end
    hrp.CFrame = CFrame.new(zoneCenter + Vector3.new(0, 5, 0))
    hrp.Velocity = Vector3.new(0, 0, 0)
    hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    return true
end

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

local statNames = {
    [1] = "Strength",
    [2] = "Durability",
    [3] = "Chakra",
    [4] = "Sword",
    [5] = "Agility",
    [6] = "Speed"
}

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
            UserInputService:SendKeyEvent(true, keyCode, false, game)
            task.wait(0.03)
            UserInputService:SendKeyEvent(false, keyCode, false, game)
        end
    end)
end

-- ============================================
-- WORLD / NPC HELPERS
-- ============================================
local questNPCs = {
    {name = "Boom", path = "Workspace.Scriptable.NPC.Quest.Boom"},
    {name = "Reindeer", path = "Workspace.Scriptable.NPC.Quest.Reindeer"},
    {name = "Ghoul", path = "Workspace.Scriptable.NPC.Quest.Ghoul"},
    {name = "Sword Master", path = "Workspace.Scriptable.NPC.Quest.Sword Master"},
    {name = "Santa", path = "Workspace.Scriptable.NPC.Quest.Santa"},
    {name = "Giovanni", path = "Workspace.Scriptable.NPC.Quest.Giovanni"}
}

local function findNPCClickDetector(npcName, npcPath)
    local pathParts = {}
    for part in npcPath:gmatch("[^.]+") do
        table.insert(pathParts, part)
    end
    local current = workspace
    for i, part in ipairs(pathParts) do
        if i == 1 and part == "Workspace" then
            current = workspace
        else
            current = current:FindFirstChild(part)
            if not current then
                return nil
            end
        end
    end
    local npcFolder = current
    local npcModel = npcFolder:FindFirstChild(npcName)
    if npcModel then
        local clickBox = npcModel:FindFirstChild("ClickBox")
        if clickBox then
            local clickDetector = clickBox:FindFirstChild("ClickDetector")
            if clickDetector then
                return clickDetector
            end
        end
    end
    local clickBox = npcFolder:FindFirstChild("ClickBox", true)
    if clickBox then
        local clickDetector = clickBox:FindFirstChild("ClickDetector")
        if clickDetector then return clickDetector end
    end
    local clickDetector = npcFolder:FindFirstChild("ClickDetector", true)
    return clickDetector
end

local function interactWithNPC(npcName)
    for _, npc in ipairs(questNPCs) do
        if npc.name == npcName then
            local clickDetector = findNPCClickDetector(npc.name, npc.path)
            if not clickDetector then return false end
            if fireclickdetector then
                fireclickdetector(clickDetector)
                return true
            end
            local mouseClickEvent = clickDetector:FindFirstChild("MouseClick")
            if mouseClickEvent and mouseClickEvent:IsA("RemoteEvent") then
                local char = LocalPlayer.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    mouseClickEvent:FireServer(char.HumanoidRootPart.Position)
                    return true
                end
            end
        end
    end
    return false
end

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

local function copyZoneList()
    loadGameData()
    if not GameData or not GameData.TrainingAreas then return end
    local output = "=== TRAINING ZONES ===\n\n"
    for statId = 1, 6 do
        if statId ~= 4 then
            local statName = statNames[statId]
            local power = getStatPower(statId)
            output = output .. "--- " .. statName .. " (Your power: " .. tostring(power) .. ") ---\n"
            local zones = {}
            for _, zone in pairs(GameData.TrainingAreas) do
                if zone.Data and zone.Data.Stat == statId then
                    table.insert(zones, zone)
                end
            end
            table.sort(zones, function(a, b) return (a.Data.Multiply or 0) > (b.Data.Multiply or 0) end)
            for _, zone in ipairs(zones) do
                local canAccess = canAccessZone(zone)
                output = output .. (canAccess and "[OK] " or "[X] ") ..
                    (zone.Data.AreaName or "?") .. " - " ..
                    tostring(zone.Data.Multiply or 1) .. "x (Req: " ..
                    tostring(zone.Data.Requires or 0) .. ")\n"
            end
            output = output .. "\n"
        end
    end
    if setclipboard then
        pcall(function() setclipboard(output) end)
    end
end

-- Get player power
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

-- Get current zone
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

-- Get owned champions
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

-- Check if champion is equipped
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

-- Equip champion
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

-- Auto train
local function doTrain()
    pcall(function()
        if TrainRemote then
            TrainRemote:FireServer()
        end
    end)
end

local function doTrainStat(statId)
    pcall(function()
        if TrainRemote then
            TrainRemote:FireServer("Train", statId)
        end
    end)
end

-- Auto farm (punch)
local function doPunch()
    pcall(function()
        if RemoteFunction then
            RemoteFunction:InvokeServer("Punch")
        end
    end)
end

-- Summon special
local function summonSpecial(specialType)
    pcall(function()
        if RemoteFunction then
            RemoteFunction:InvokeServer("BuyContainer", specialType, 1)
        end
    end)
end

-- Apply low graphics
local function applyLowGraphics()
    pcall(function()
        local settings_table = {
            Lighting = {
                GlobalShadows = false,
                FogEnd = 9e9
            }
        }
        
        for property, value in pairs(settings_table.Lighting) do
            Lighting[property] = value
        end
        
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
-- INITIALIZATION
-- ============================================

print("[Headless] Starting Dougy's Hub Headless Script...")
print("[Headless] Shared folder: " .. SHARED_PATH)

-- Test if writefile works with absolute paths
local testFilePath = getFullPath("_test_write.txt")
local testSuccess, testErr = pcall(function()
    writefile(testFilePath, "test")
    if isfile and isfile(testFilePath) then
        local content = readfile(testFilePath)
        if content == "test" then
            print("[Headless] ✓ File operations working! Testing with: " .. testFilePath)
            if delfile then
                pcall(function() delfile(testFilePath) end)
            end
        else
            warn("[Headless] ✗ File read failed - content doesn't match!")
        end
    else
        warn("[Headless] ✗ File doesn't exist after write! Your executor might not support absolute paths.")
        warn("[Headless] Try using a relative path or your executor's workspace folder instead.")
    end
end)
if not testSuccess then
    warn("[Headless] ✗ File write test failed: " .. tostring(testErr))
    warn("[Headless] Your executor might not support absolute paths with writefile!")
    warn("[Headless] Solution: Use your executor's workspace folder path instead.")
end

-- Preload GameData lists for UI
loadGameData()
cachedChampionPods = getChampionPodsList()
cachedSpecials.Stands = getSpecialList("Stands")
cachedSpecials.Kagunes = getSpecialList("Kagunes")
cachedSpecials.Quirks = getSpecialList("Quirks")
cachedSpecials.Grimoires = getSpecialList("Grimoires")
cachedSpecials.Bloodlines = getSpecialList("Bloodlines")

-- Write initial status immediately
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
    uptime = 0,
    timestamp = os.time(),
    sharedPath = SHARED_PATH,
    disconnectReason = nil
})

print("[Headless] Initial status written!")
print("[Headless] If overlay still shows 'Disconnected', make sure the paths match!")

-- Load remotes after status so overlay connects instantly
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
            -- Stop loops if we left the game (e.g., Roblox app menu / teleport)
            isRunning = false
            break
        end
        -- Read settings from overlay
        readSettings()
        readCommands()

        if settings.autoSellRarity ~= lastAutoSellRarity then
            setupAutoSell()
            lastAutoSellRarity = settings.autoSellRarity
        end

        if type(settings.autoUseKeys) ~= "table" then
            settings.autoUseKeys = {}
        end

        -- Refresh cached lists occasionally
        if tick() - lastDataRefresh > 30 then
            loadGameData()
            cachedChampionPods = getChampionPodsList()
            cachedSpecials.Stands = getSpecialList("Stands")
            cachedSpecials.Kagunes = getSpecialList("Kagunes")
            cachedSpecials.Quirks = getSpecialList("Quirks")
            cachedSpecials.Grimoires = getSpecialList("Grimoires")
            cachedSpecials.Bloodlines = getSpecialList("Bloodlines")
            lastDataRefresh = tick()
        end
        
        -- Write status to overlay
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
local lastTrainTime = 0
local lastPunchTime = 0
local lastChampCheck = 0
local lastSummonTimes = {}
local lastStatTrainTimes = {}
local lastKeyPressTime = 0
local lastChampionSummon = 0
local lastZoneLoop = 0
local lowGraphicsApplied = false
local autoUseIndex = 1

connections.mainLoop = RunService.Heartbeat:Connect(function()
    local now = tick()
    
    -- Auto Train
    if settings.autoTrain then
        if now - lastTrainTime >= 0.1 then
            doTrain()
            lastTrainTime = now
        end
    end

    -- Auto Train Stats (per stat)
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
    
    -- Auto Farm (Punch)
    if settings.autoFarm then
        if now - lastPunchTime >= 0.1 then
            doPunch()
            lastPunchTime = now
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
            autoUseIndex += 1
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
            -- Stop if target special is owned
            local targetId = settings[special.targetKey]
            if targetId and isSpecialOwned(targetId) then
                settings[special.setting] = false
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

    -- Auto Chikara Farm (click crates)
    if settings.autoChikaraFarm then
        if now - (lastSummonTimes.__chikara or 0) >= 1 then
            lastSummonTimes.__chikara = now
            local crates = findChikaraCrates()
            for _, detector in ipairs(crates) do
                pcall(function()
                    if fireclickdetector then
                        fireclickdetector(detector)
                    else
                        local mouseClickEvent = detector:FindFirstChild("MouseClick")
                        if mouseClickEvent and mouseClickEvent:IsA("RemoteEvent") then
                            local char = LocalPlayer.Character
                            if char and char:FindFirstChild("HumanoidRootPart") then
                                mouseClickEvent:FireServer(char.HumanoidRootPart.Position)
                            end
                        end
                    end
                end)
            end
        end
    end
    
    -- Low Graphics
    if settings.lowGraphics and not lowGraphicsApplied then
        applyLowGraphics()
        lowGraphicsApplied = true
    end
end)

-- Cleanup on leave
LocalPlayer.AncestryChanged:Connect(function()
    sendDisconnected("PlayerRemoved")
    isRunning = false
    for _, conn in pairs(connections) do
        pcall(function() conn:Disconnect() end)
    end
end)

-- Fast watchdog: detect leaving AFSE immediately (menu, teleport, place change)
connections.watchdog = RunService.RenderStepped:Connect(function()
    if not isRunning then return end
    if not shouldBeConnected() then
        sendDisconnected("Watchdog")
        isRunning = false
    end
end)

print("[Headless] Script running! Check the overlay for status.")
