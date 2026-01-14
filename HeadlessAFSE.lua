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
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer

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
    autoSummonStand = false,
    autoSummonKagune = false,
    autoSummonQuirk = false,
    autoSummonGrimoire = false,
    autoSummonBloodline = false,
    autoEquipChampion = false,
    selectedChampion = nil,
    lowGraphics = false
}
local isRunning = true
local connections = {}
local startTime = os.time()

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
            RemoteFunction = ReplicatedStorage:WaitForChild("RemoteFunction", 5)
            RemoteEvent = ReplicatedStorage:WaitForChild("RemoteEvent", 5)
            TrainRemote = ReplicatedStorage:WaitForChild("Train", 5)
        end)
        if RemoteFunction and RemoteEvent then
            break
        end
        task.wait(1)
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
                table.insert(champions, {
                    id = tonumber(champ.Name) or 0,
                    name = "Champion " .. champ.Name
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
            RemoteFunction:InvokeServer("Summon" .. specialType)
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

loadRemotes()

-- Write initial status immediately
writeStatus({
    connected = true,
    game = "AFSE",
    placeId = game.PlaceId,
    player = LocalPlayer.Name,
    power = getPower(),
    currentZone = getCurrentZone(),
    champions = getOwnedChampions(),
    uptime = 0,
    timestamp = os.time(),
    sharedPath = SHARED_PATH
})

print("[Headless] Initial status written!")
print("[Headless] If overlay still shows 'Disconnected', make sure the paths match!")

-- ============================================
-- MAIN LOOPS
-- ============================================

-- Communication loop
task.spawn(function()
    while isRunning do
        -- Read settings from overlay
        readSettings()
        readCommands()
        
        -- Write status to overlay
        local status = {
            connected = true,
            game = "AFSE",
            placeId = game.PlaceId,
            player = LocalPlayer.Name,
            power = getPower(),
            currentZone = getCurrentZone(),
            champions = getOwnedChampions(),
            uptime = os.time() - startTime,
            timestamp = os.time(),
            sharedPath = SHARED_PATH
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
local lowGraphicsApplied = false

connections.mainLoop = RunService.Heartbeat:Connect(function()
    local now = tick()
    
    -- Auto Train
    if settings.autoTrain then
        if now - lastTrainTime >= 0.1 then
            doTrain()
            lastTrainTime = now
        end
    end
    
    -- Auto Farm (Punch)
    if settings.autoFarm then
        if now - lastPunchTime >= 0.1 then
            doPunch()
            lastPunchTime = now
        end
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
        { setting = "autoSummonStand", type = "Stand" },
        { setting = "autoSummonKagune", type = "Kagune" },
        { setting = "autoSummonQuirk", type = "Quirk" },
        { setting = "autoSummonGrimoire", type = "Grimoire" },
        { setting = "autoSummonBloodline", type = "Bloodline" },
    }
    
    for _, special in ipairs(specialTypes) do
        if settings[special.setting] then
            lastSummonTimes[special.type] = lastSummonTimes[special.type] or 0
            if now - lastSummonTimes[special.type] >= 3 then
                summonSpecial(special.type)
                lastSummonTimes[special.type] = now
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
    isRunning = false
    writeStatus({ connected = false, timestamp = os.time() })
    for _, conn in pairs(connections) do
        pcall(function() conn:Disconnect() end)
    end
end)

print("[Headless] Script running! Check the overlay for status.")
