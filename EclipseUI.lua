-- EclipseUI v2.3 — Minecraft Hack Client Style (Wurst-inspired)
-- Pure Lua 5.1 (no Luau type annotations)
-- Mobile-friendly with touch support + Settings saving
-- Features: ArrayList, Multi-Select, Search, Blur, Splash, Chat Hide, Snapping, Changelog, Debug

local EclipseUI = {}
EclipseUI.__index = EclipseUI

--=============================================================================
-- SERVICES
--=============================================================================
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TextService = game:GetService("TextService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")
local StarterGui = game:GetService("StarterGui")
local Player = Players.LocalPlayer

--=============================================================================
-- CONFIGURATION
--=============================================================================
local Config = {
    panelWidth = 220,
    panelMinWidth = 180,
    panelMaxWidth = 350,
    headerHeight = 32,
    moduleHeight = 28,
    settingHeight = 26,
    padding = 8,
    cornerRadius = 5,
    animDuration = 0.15,
    notifyDuration = 3,
    isMobile = UIS.TouchEnabled,
    uiScale = 1.0,
    baseTextSize = 14,
    saveFileName = "EclipseUI_Settings.json",
    debugMode = false,
}

--=============================================================================
-- SETTINGS SAVE/LOAD SYSTEM
--=============================================================================
local SavedSettings = {
    theme = "Wurst",
    notifyPosition = "TopRight",
    fpsCap = 60,
    toggleKey = "RightShift",
    debugMode = false,
    arrayListPosition = "Right",
    themeColoredText = true, -- Enable theme-colored text for toggles/buttons
    toggleStates = {}, -- Store toggle states per game: { [placeId] = { [moduleName] = true/false } }
    dropdownStates = {}, -- Store dropdown states per game: { [placeId] = { [dropdownName] = value } }
    -- Note: uiScale is NOT saved to prevent off-screen issues on reload
}

-- Helper function to get current game's PlaceId
local function getCurrentPlaceId()
    return tostring(game.PlaceId)
end

-- Helper function to get game-specific toggle states
local function getGameToggleStates()
    local placeId = getCurrentPlaceId()
    if not SavedSettings.toggleStates then
        SavedSettings.toggleStates = {}
    end
    if not SavedSettings.toggleStates[placeId] then
        SavedSettings.toggleStates[placeId] = {}
    end
    return SavedSettings.toggleStates[placeId]
end

-- Helper function to get game-specific dropdown states
local function getGameDropdownStates()
    local placeId = getCurrentPlaceId()
    if not SavedSettings.dropdownStates then
        SavedSettings.dropdownStates = {}
    end
    if not SavedSettings.dropdownStates[placeId] then
        SavedSettings.dropdownStates[placeId] = {}
    end
    return SavedSettings.dropdownStates[placeId]
end

--=============================================================================
-- GLOBAL STATE FOR ARRAYLIST (tracks all enabled toggles)
--=============================================================================
local ActiveModules = {} -- { [name] = true/false }
local ArrayListSubscribers = {}

local function notifyArrayList()
    for _, fn in ipairs(ArrayListSubscribers) do
        pcall(fn, ActiveModules)
    end
end

local function setModuleActive(name, active)
    if active then
        ActiveModules[name] = true
    else
        ActiveModules[name] = nil
    end
    notifyArrayList()
end

--=============================================================================
-- DEBUG LOG
--=============================================================================
local DebugLogs = {}
local DebugSubscribers = {}

local function debugLog(msg)
    if not Config.debugMode then return end
    local entry = "[" .. os.date("%H:%M:%S") .. "] " .. tostring(msg)
    table.insert(DebugLogs, entry)
    if #DebugLogs > 100 then table.remove(DebugLogs, 1) end
    for _, fn in ipairs(DebugSubscribers) do pcall(fn, entry) end
end

local function canSaveFiles()
    return writefile and readfile and isfile
end

local function loadSettings()
    if not canSaveFiles() then return SavedSettings end
    
    pcall(function()
        if isfile(Config.saveFileName) then
            local data = readfile(Config.saveFileName)
            local decoded = HttpService:JSONDecode(data)
            if decoded then
                for k, v in pairs(decoded) do
                    SavedSettings[k] = v
                end
            end
        end
        -- Ensure dropdownStates and toggleStates are initialized (they might not exist in old save files)
        if not SavedSettings.dropdownStates then
            SavedSettings.dropdownStates = {}
        end
        if not SavedSettings.toggleStates then
            SavedSettings.toggleStates = {}
        end
    end)
    
    return SavedSettings
end

local function saveSettings()
    if not canSaveFiles() then return false end
    
    local ok = pcall(function()
        local data = HttpService:JSONEncode(SavedSettings)
        writefile(Config.saveFileName, data)
    end)
    
    return ok
end

-- Load settings on start
loadSettings()

--=============================================================================
-- THEMES (with animation styles)
--=============================================================================
local Themes = {
    ["Wurst"] = {
        name = "Wurst",
        bg = Color3.fromRGB(20, 20, 20),
        overlay = Color3.fromRGB(0, 0, 0),
        panel = Color3.fromRGB(30, 30, 30),
        panelHeader = Color3.fromRGB(40, 40, 40),
        accent = Color3.fromRGB(0, 200, 83),
        accentDark = Color3.fromRGB(0, 150, 60),
        text = Color3.fromRGB(255, 255, 255),
        textDim = Color3.fromRGB(170, 170, 170),
        enabled = Color3.fromRGB(0, 200, 83),
        disabled = Color3.fromRGB(100, 100, 100),
        hover = Color3.fromRGB(50, 50, 50),
        stroke = Color3.fromRGB(60, 60, 60),
        notification = Color3.fromRGB(0, 200, 83),
        animStyle = "Fade",
    },
    ["Impact"] = {
        name = "Impact",
        bg = Color3.fromRGB(15, 15, 20),
        overlay = Color3.fromRGB(0, 0, 0),
        panel = Color3.fromRGB(25, 25, 35),
        panelHeader = Color3.fromRGB(35, 35, 50),
        accent = Color3.fromRGB(180, 50, 50),
        accentDark = Color3.fromRGB(140, 40, 40),
        text = Color3.fromRGB(255, 255, 255),
        textDim = Color3.fromRGB(160, 160, 170),
        enabled = Color3.fromRGB(180, 50, 50),
        disabled = Color3.fromRGB(80, 80, 90),
        hover = Color3.fromRGB(45, 45, 60),
        stroke = Color3.fromRGB(55, 55, 70),
        notification = Color3.fromRGB(180, 50, 50),
        animStyle = "Slide",
    },
    ["Future"] = {
        name = "Future",
        bg = Color3.fromRGB(10, 10, 15),
        overlay = Color3.fromRGB(0, 0, 0),
        panel = Color3.fromRGB(18, 18, 25),
        panelHeader = Color3.fromRGB(28, 28, 40),
        accent = Color3.fromRGB(100, 180, 255),
        accentDark = Color3.fromRGB(70, 140, 200),
        text = Color3.fromRGB(240, 240, 255),
        textDim = Color3.fromRGB(140, 150, 180),
        enabled = Color3.fromRGB(100, 180, 255),
        disabled = Color3.fromRGB(60, 70, 90),
        hover = Color3.fromRGB(35, 35, 50),
        stroke = Color3.fromRGB(50, 60, 80),
        notification = Color3.fromRGB(100, 180, 255),
        animStyle = "Scale",
    },
    ["Meteor"] = {
        name = "Meteor",
        bg = Color3.fromRGB(15, 10, 20),
        overlay = Color3.fromRGB(0, 0, 0),
        panel = Color3.fromRGB(25, 18, 35),
        panelHeader = Color3.fromRGB(40, 28, 55),
        accent = Color3.fromRGB(190, 80, 250),
        accentDark = Color3.fromRGB(150, 60, 200),
        text = Color3.fromRGB(255, 245, 255),
        textDim = Color3.fromRGB(180, 160, 190),
        enabled = Color3.fromRGB(190, 80, 250),
        disabled = Color3.fromRGB(90, 70, 110),
        hover = Color3.fromRGB(50, 35, 65),
        stroke = Color3.fromRGB(70, 50, 90),
        notification = Color3.fromRGB(190, 80, 250),
        animStyle = "Fade",
    },
    ["Aristois"] = {
        name = "Aristois",
        bg = Color3.fromRGB(20, 18, 15),
        overlay = Color3.fromRGB(0, 0, 0),
        panel = Color3.fromRGB(35, 30, 25),
        panelHeader = Color3.fromRGB(50, 42, 35),
        accent = Color3.fromRGB(255, 170, 50),
        accentDark = Color3.fromRGB(200, 130, 40),
        text = Color3.fromRGB(255, 250, 240),
        textDim = Color3.fromRGB(190, 180, 160),
        enabled = Color3.fromRGB(255, 170, 50),
        disabled = Color3.fromRGB(100, 90, 75),
        hover = Color3.fromRGB(60, 50, 40),
        stroke = Color3.fromRGB(80, 68, 55),
        notification = Color3.fromRGB(255, 170, 50),
        animStyle = "Slide",
    },
}

-- Apply saved theme
local CurrentTheme = Themes[SavedSettings.theme] or Themes["Wurst"]

--=============================================================================
-- UTILITY FUNCTIONS
--=============================================================================
local function create(className, props, children)
    local inst = Instance.new(className)
    if props then
        for k, v in pairs(props) do
            inst[k] = v
        end
    end
    if children then
        for _, child in ipairs(children) do
            if child then child.Parent = inst end
        end
    end
    return inst
end

local function makeRounded(obj, r)
    create("UICorner", { CornerRadius = UDim.new(0, r or Config.cornerRadius), Parent = obj })
end

local function makeStroke(obj, color, thickness)
    create("UIStroke", { Parent = obj, Color = color or CurrentTheme.stroke, Thickness = thickness or 1, Transparency = 0.3 })
end

local function keycodeToString(kc)
    local str = tostring(kc)
    return str:match("([^%.]+)$") or str
end

local function stringToKeycode(str)
    return Enum.KeyCode[str] or Enum.KeyCode.RightShift
end

local function getTextSize(text, size, font)
    return TextService:GetTextSize(text, size, font, Vector2.new(1000, 100))
end

local function tween(obj, props, duration, style, dir)
    local ti = TweenInfo.new(duration or Config.animDuration, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out)
    local t = TweenService:Create(obj, ti, props)
    t:Play()
    return t
end

local function scaled(value)
    return math.floor(value * Config.uiScale + 0.5)
end

--=============================================================================
-- FPS CAP HELPER
--=============================================================================
local function applyFpsCap(v)
    v = math.clamp(tonumber(v) or 60, 10, 500)
    local names = { "setfpscap", "set_fps_cap", "fpscap", "setfps" }
    for _, n in ipairs(names) do
        local fn = rawget(_G, n)
        if type(fn) == "function" then
            local ok = pcall(fn, v)
            if ok then return true end
        end
    end
    local envs = { getgenv and getgenv() or nil, _G, getrenv and getrenv() or nil, _ENV }
    for _, e in ipairs(envs) do
        if type(e) == "table" then
            for _, n in ipairs(names) do
                local fn = rawget(e, n)
                if type(fn) == "function" then
                    local ok = pcall(fn, v)
                    if ok then return true end
                end
            end
        end
    end
    if syn and type(syn.set_fps_cap) == "function" then
        local ok = pcall(syn.set_fps_cap, v)
        if ok then return true end
    end
    if type(setfflag) == "function" then
        local ok = pcall(function() setfflag("DFIntTaskSchedulerTargetFps", tostring(v)) end)
        if ok then return true end
    end
    return false
end

--=============================================================================
-- THEME SUBSCRIBERS (pub/sub for reactive theme changes)
--=============================================================================
local ThemeSubscribers = {}
local function subscribeTheme(fn)
    table.insert(ThemeSubscribers, fn)
    return fn
end
local function publishTheme(theme)
    CurrentTheme = theme
    for _, fn in ipairs(ThemeSubscribers) do
        pcall(fn, theme)
    end
end

--=============================================================================
-- HOVER STATE TRACKER (for fixing theme change hover bug)
--=============================================================================
local HoverStates = {}
local function trackHover(element, baseColor, hoverColor)
    HoverStates[element] = {
        isHovered = false,
        baseColor = baseColor,
        hoverColor = hoverColor,
    }
    
    element.MouseEnter:Connect(function()
        if HoverStates[element] then
            HoverStates[element].isHovered = true
            tween(element, { BackgroundColor3 = HoverStates[element].hoverColor }, 0.1)
        end
    end)
    
    element.MouseLeave:Connect(function()
        if HoverStates[element] then
            HoverStates[element].isHovered = false
            tween(element, { BackgroundColor3 = HoverStates[element].baseColor }, 0.1)
        end
    end)
    
    return HoverStates[element]
end

local function updateHoverColors(element, baseColor, hoverColor)
    if HoverStates[element] then
        HoverStates[element].baseColor = baseColor
        HoverStates[element].hoverColor = hoverColor
        -- Apply correct color based on current state
        if HoverStates[element].isHovered then
            element.BackgroundColor3 = hoverColor
        else
            element.BackgroundColor3 = baseColor
        end
    end
end

--=============================================================================
-- MAIN WINDOW CREATION
--=============================================================================
function EclipseUI:CreateWindow(cfg)
    cfg = cfg or {}
    
    -- Apply saved or configured theme
    local themeName = SavedSettings.theme or cfg.Theme or "Wurst"
    if Themes[themeName] then
        CurrentTheme = Themes[themeName]
    end
    
    local theme = CurrentTheme
    local toggleKey = stringToKeycode(SavedSettings.toggleKey) or cfg.ToggleKey or Enum.KeyCode.RightShift
    local notifyPosition = SavedSettings.notifyPosition or cfg.NotifyPosition or "TopRight"
    local overlayOpacity = cfg.OverlayOpacity or 0.4
    
    -- New config options - properly check for nil (default to true) but respect false
    -- Simple ternary: if nil, default to true; otherwise use the value directly
    local showSearchBar = cfg.SearchBar == nil and true or cfg.SearchBar
    local showArrayList = cfg.ArrayList == nil and true or cfg.ArrayList
    local showSplash = cfg.SplashScreen == nil and true or cfg.SplashScreen
    local enableBlur = cfg.BlurEffect == nil and true or cfg.BlurEffect
    -- Panel snapping removed (was causing bugs)
    local autoHideOnChat = cfg.AutoHideOnChat == nil and true or cfg.AutoHideOnChat
    
    -- Always log config values to help debug (print to console)
    print("[DougysUI] Config received:")
    print("  SearchBar:", cfg.SearchBar, "-> showSearchBar:", showSearchBar)
    print("  Title:", cfg.Title, "SplashTitle:", cfg.SplashTitle)
    print("  Subtitle:", cfg.Subtitle, "SplashSubtitle:", cfg.SplashSubtitle)
    
    local splashTitle = cfg.SplashTitle or cfg.Title or "EclipseUI" -- Use Title if SplashTitle not provided
    local splashSubtitle = cfg.SplashSubtitle or cfg.Subtitle or "Loading..."
    
    print("[DougysUI] Using splashTitle:", splashTitle, "splashSubtitle:", splashSubtitle)
    
    Config.debugMode = SavedSettings.debugMode or false
    
    debugLog("CreateWindow called with config")
    
    -- Main ScreenGui
    local gui = create("ScreenGui", {
        Name = cfg.Title or "EclipseUI_v2",
        IgnoreGuiInset = true,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999999,
        Parent = CoreGui
    })

    --=========================================================================
    -- SPLASH SCREEN (Centered box, not fullscreen)
    --=========================================================================
    local splashGui
    local menuReadyToShow = false
    
    if showSplash then
        splashGui = create("Frame", {
            Name = "SplashScreen",
            Size = UDim2.fromOffset(320, 160),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            BackgroundColor3 = theme.panel,
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            ZIndex = 9999,
            Parent = gui
        })
        makeRounded(splashGui, 12)
        makeStroke(splashGui, theme.accent, 2)
        
        -- Start slightly scaled down for animation
        splashGui.Size = UDim2.fromOffset(0, 0)
        
        local splashTitleLabel = create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 40),
            Position = UDim2.fromOffset(0, 25),
            Text = splashTitle,
            TextColor3 = theme.accent,
            Font = Enum.Font.GothamBold,
            TextSize = 28,
            TextTransparency = 1,
            Parent = splashGui
        })
        
        local splashSubLabel = create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 20),
            Position = UDim2.fromOffset(0, 70),
            Text = splashSubtitle,
            TextColor3 = theme.textDim,
            Font = Enum.Font.Gotham,
            TextSize = 14,
            TextTransparency = 1,
            Parent = splashGui
        })
        
        local splashBar = create("Frame", {
        BackgroundColor3 = theme.bg,
        BorderSizePixel = 0,
            Size = UDim2.new(0.8, 0, 0, 6),
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, 110),
            Parent = splashGui
        })
        makeRounded(splashBar, 3)
        
        local splashProgress = create("Frame", {
            BackgroundColor3 = theme.accent,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 0, 1, 0),
            Parent = splashBar
        })
        makeRounded(splashProgress, 3)
        
        -- Animate splash (centered box style)
        task.spawn(function()
            -- Pop in animation
            tween(splashGui, { Size = UDim2.fromOffset(320, 160) }, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            task.wait(0.15)
            tween(splashTitleLabel, { TextTransparency = 0 }, 0.2)
            task.wait(0.1)
            tween(splashSubLabel, { TextTransparency = 0 }, 0.2)
            task.wait(0.1)
            tween(splashProgress, { Size = UDim2.new(1, 0, 1, 0) }, 0.7, Enum.EasingStyle.Quad)
            task.wait(0.8)
            
            -- Fade out and shrink
            tween(splashTitleLabel, { TextTransparency = 1 }, 0.15)
            tween(splashSubLabel, { TextTransparency = 1 }, 0.15)
            task.wait(0.1)
            tween(splashGui, { Size = UDim2.fromOffset(0, 0), BackgroundTransparency = 1 }, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In)
            task.wait(0.3)
            if splashGui then splashGui:Destroy() end
            menuReadyToShow = true
        end)
    else
        menuReadyToShow = true
    end
    
    --=========================================================================
    -- BLUR EFFECT
    --=========================================================================
    local blurEffect
    if enableBlur then
        blurEffect = Instance.new("BlurEffect")
        blurEffect.Name = "EclipseUIBlur"
        blurEffect.Size = 0
        blurEffect.Parent = game:GetService("Lighting")
    end
    
    -- Dark overlay background (when menu is open)
    local overlay = create("Frame", {
        Name = "Overlay",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = theme.overlay,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 0,
        Parent = gui
    })
    
    -- Container for all panels (with UIScale for scaling)
    local panelContainer = create("Frame", {
        Name = "PanelContainer",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Parent = gui
    })
    
    local uiScaleObj = create("UIScale", {
        Scale = Config.uiScale,
        Parent = panelContainer
    })
    
    -- Notification container
    local notifContainer = create("Frame", {
        Name = "NotificationContainer",
        Size = UDim2.fromOffset(500, 600),
        BackgroundTransparency = 1,
        ZIndex = 100,
        Parent = gui
    })
    
    local function updateNotifPosition()
        if notifyPosition == "TopRight" then
            notifContainer.AnchorPoint = Vector2.new(1, 0)
            notifContainer.Position = UDim2.new(1, -15, 0, 15)
        elseif notifyPosition == "TopLeft" then
            notifContainer.AnchorPoint = Vector2.new(0, 0)
            notifContainer.Position = UDim2.new(0, 15, 0, 15)
        elseif notifyPosition == "BottomRight" then
            notifContainer.AnchorPoint = Vector2.new(1, 1)
            notifContainer.Position = UDim2.new(1, -15, 1, -15)
        elseif notifyPosition == "BottomLeft" then
            notifContainer.AnchorPoint = Vector2.new(0, 1)
            notifContainer.Position = UDim2.new(0, 15, 1, -15)
        end
    end
    updateNotifPosition()
    
    create("UIListLayout", {
        Parent = notifContainer,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
        VerticalAlignment = notifyPosition:find("Bottom") and Enum.VerticalAlignment.Bottom or Enum.VerticalAlignment.Top,
        HorizontalAlignment = notifyPosition:find("Left") and Enum.HorizontalAlignment.Left or Enum.HorizontalAlignment.Right
    })
    
    --=========================================================================
    -- ARRAY LIST (shows enabled modules when menu is hidden)
    --=========================================================================
    local arrayList = create("Frame", {
        Name = "ArrayList",
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(200, 400),
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -10, 0, 60),
        Visible = false,
        ZIndex = 50,
        Parent = gui
    })
    
    create("UIListLayout", {
        Parent = arrayList,
        SortOrder = Enum.SortOrder.Name,
        Padding = UDim.new(0, 2),
        HorizontalAlignment = Enum.HorizontalAlignment.Right
    })
    
    local arrayListLabels = {}
    
    local function updateArrayList()
        -- Clear existing
        for _, label in pairs(arrayListLabels) do
            if label and label.Parent then label:Destroy() end
        end
        arrayListLabels = {}
        
        -- Create sorted list of active modules
        local sorted = {}
        for name, _ in pairs(ActiveModules) do
            table.insert(sorted, name)
        end
        table.sort(sorted, function(a, b) return #a > #b end) -- Sort by length (longest first)
        
        for i, name in ipairs(sorted) do
            local sz = getTextSize(name, 14, Enum.Font.GothamBold)
            local label = create("Frame", {
                Name = name,
        BackgroundColor3 = theme.panel,
                BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
                Size = UDim2.fromOffset(sz.X + 24, 24), -- More width for spacing
                LayoutOrder = i,
                Parent = arrayList
            })
            makeRounded(label, 4)
            
            -- Accent bar on right
            create("Frame", {
                BackgroundColor3 = theme.accent,
                BorderSizePixel = 0,
                Size = UDim2.new(0, 3, 1, 0),
                Position = UDim2.new(1, -3, 0, 0),
                Parent = label
            })
            
            -- Text with proper spacing from accent bar
    create("TextLabel", {
        BackgroundTransparency = 1,
                Size = UDim2.new(1, -18, 1, 0), -- More padding: 8px left + 10px from bar
                Position = UDim2.fromOffset(8, 0),
                Text = name,
        TextColor3 = theme.text,
        Font = Enum.Font.GothamBold,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Right,
                Parent = label
            })
            
            arrayListLabels[name] = label
        end
    end
    
    table.insert(ArrayListSubscribers, updateArrayList)
    
    --=========================================================================
    -- GLOBAL SEARCH BAR
    --=========================================================================
    local searchBarFrame, searchInput, searchResults
    local allSearchItems = {} -- Store references to ALL searchable items (modules, dropdowns, sliders, etc.)
    
    if showSearchBar then
        searchBarFrame = create("Frame", {
            Name = "SearchBar",
            BackgroundColor3 = theme.panel,
            BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
            Size = UDim2.fromOffset(300, 36),
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, 10),
            ZIndex = 500,
            Visible = true,
            Parent = panelContainer
        })
        makeRounded(searchBarFrame, 8)
        makeStroke(searchBarFrame, theme.accent, 1)
        
        local searchIcon = create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(30, 36),
            Text = "?",
            TextColor3 = theme.textDim,
        Font = Enum.Font.GothamBold,
            TextSize = 16,
            Parent = searchBarFrame
        })
        
        searchInput = create("TextBox", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -40, 1, 0),
            Position = UDim2.fromOffset(30, 0),
            Text = "",
            PlaceholderText = "Search modules...",
        TextColor3 = theme.text,
            PlaceholderColor3 = theme.textDim,
            Font = Enum.Font.Gotham,
        TextSize = 14,
            ClearTextOnFocus = false,
            Parent = searchBarFrame
        })
        
        searchResults = create("Frame", {
            Name = "SearchResults",
        BackgroundColor3 = theme.panel,
        BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 0),
            Position = UDim2.fromOffset(0, 40),
            ClipsDescendants = true,
            Visible = false,
            ZIndex = 501,
            Parent = searchBarFrame
        })
        makeRounded(searchResults, 6)
        makeStroke(searchResults, theme.stroke)
        
        create("UIListLayout", {
            Parent = searchResults,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 2)
        })
        
        create("UIPadding", {
            Parent = searchResults,
            PaddingTop = UDim.new(0, 4),
            PaddingBottom = UDim.new(0, 4),
            PaddingLeft = UDim.new(0, 4),
            PaddingRight = UDim.new(0, 4)
        })
        
        local function performSearch(query)
            -- Clear previous results
            for _, child in ipairs(searchResults:GetChildren()) do
                if child:IsA("TextButton") then child:Destroy() end
            end
            
            if query == "" then
                searchResults.Visible = false
                return
            end
            
            local matches = {}
            local lowerQuery = string.lower(query)
            
            -- Search through all items (modules, dropdowns, sliders, etc.)
            for _, item in ipairs(allSearchItems) do
                if string.find(string.lower(item.name), lowerQuery, 1, true) then
                    table.insert(matches, item)
        end
    end

            if #matches == 0 then
                searchResults.Visible = false
                return
            end
            
            searchResults.Visible = true
            local resultHeight = math.min(#matches * 28, 200)
            tween(searchResults, { Size = UDim2.new(1, 0, 0, resultHeight + 8) }, 0.15)
            
            for i, mod in ipairs(matches) do
                if i > 7 then break end -- Max 7 results
                local resultBtn = create("TextButton", {
                    BackgroundColor3 = theme.bg,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 26),
                    Text = mod.name .. " [" .. mod.panel .. "]",
                    TextColor3 = theme.text,
                    Font = Enum.Font.Gotham,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 502,
                    Parent = searchResults
                })
                makeRounded(resultBtn, 4)
                create("UIPadding", { Parent = resultBtn, PaddingLeft = UDim.new(0, 8) })
                
                trackHover(resultBtn, theme.bg, theme.hover)
                
                resultBtn.MouseButton1Click:Connect(function()
                    searchInput.Text = ""
                    searchResults.Visible = false
                    
                    -- Find the element to highlight
                    local targetElement = mod.row or mod.instance
                    if targetElement and targetElement.Parent then
                        -- Find parent panel and expand if collapsed
                        local panel = targetElement:FindFirstAncestor("Panel_" .. mod.panel) or targetElement:FindFirstAncestorOfClass("Frame")
                        
                        -- Flash highlight animation
                        local elementsToFlash = {}
                        
                        -- If it's a module holder, flash the row
                        if mod.row and mod.row:IsA("Frame") then
                            table.insert(elementsToFlash, mod.row)
                        end
                        
                        -- Also try to find the actual row within the instance
                        if mod.instance then
                            local row = mod.instance:FindFirstChild("Row")
                            if row then
                                table.insert(elementsToFlash, row)
                            end
                        end
                        
                        -- If no specific elements found, flash the instance itself
                        if #elementsToFlash == 0 and mod.instance and mod.instance:IsA("Frame") then
                            table.insert(elementsToFlash, mod.instance)
                        end
                        
                        -- Perform flash animation
                        for _, elem in ipairs(elementsToFlash) do
                            local orig = elem.BackgroundColor3
                            task.spawn(function()
                                for _ = 1, 3 do
                                    elem.BackgroundColor3 = theme.accent
                                    task.wait(0.12)
                                    elem.BackgroundColor3 = orig
                                    task.wait(0.12)
                                end
                            end)
                        end
                    end
            end)
        end
        end
        
        searchInput:GetPropertyChangedSignal("Text"):Connect(function()
            performSearch(searchInput.Text)
        end)
        
        searchInput.FocusLost:Connect(function()
            task.delay(0.2, function()
                if not searchInput:IsFocused() then
                    searchResults.Visible = false
                end
            end)
        end)
    end
    
    --=========================================================================
    -- CHANGELOG VIEWER
    --=========================================================================
    local changelogEntries = {}
    local changelogFrame
    
    -- Tooltip
    local tooltip = create("Frame", {
        Name = "Tooltip",
        Visible = false,
        BackgroundColor3 = theme.panel,
        BorderSizePixel = 0,
        ZIndex = 1000,
        Parent = gui
    })
    makeRounded(tooltip, 5)
    makeStroke(tooltip, theme.accent, 1)
    create("UIPadding", { Parent = tooltip, PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) })
    
    local tooltipText = create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        TextColor3 = theme.text,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = tooltip
    })
    
    local tooltipTarget = nil
    local tooltipDelay = 0.4
    
    local function showTooltip(text, target)
        if not text or text == "" then return end
        tooltipTarget = target
        tooltipText.Text = text
        local sz = getTextSize(text, 13, Enum.Font.Gotham)
        tooltip.Size = UDim2.fromOffset(sz.X + 20, sz.Y + 12)
        
        task.delay(tooltipDelay, function()
            if tooltipTarget == target then
                local mouse = UIS:GetMouseLocation()
        local screen = gui.AbsoluteSize
                local x = math.clamp(mouse.X + 12, 0, screen.X - tooltip.AbsoluteSize.X)
                local y = math.clamp(mouse.Y + 18, 0, screen.Y - tooltip.AbsoluteSize.Y)
        tooltip.Position = UDim2.fromOffset(x, y)
        tooltip.Visible = true
    end
        end)
    end
    
    local function hideTooltip()
        tooltipTarget = nil
        tooltip.Visible = false
    end
    
    local function attachTooltip(element, text)
        if not text or text == "" then return end
        element.MouseEnter:Connect(function() showTooltip(text, element) end)
        element.MouseLeave:Connect(function() hideTooltip() end)
    end
    
    -- Follow mouse for tooltip
    UIS.InputChanged:Connect(function(input)
        if tooltip.Visible and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local mouse = UIS:GetMouseLocation()
            local screen = gui.AbsoluteSize
            local x = math.clamp(mouse.X + 12, 0, screen.X - tooltip.AbsoluteSize.X)
            local y = math.clamp(mouse.Y + 18, 0, screen.Y - tooltip.AbsoluteSize.Y)
            tooltip.Position = UDim2.fromOffset(x, y)
        end
    end)
    
    -- Reopen hint (when UI is hidden)
    local hint = create("Frame", {
        Name = "ReopenHint",
        Visible = false,
        BackgroundColor3 = theme.panel,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 15),
        Size = UDim2.fromOffset(240, 38),
        ZIndex = 500,
        Parent = gui
    })
    makeRounded(hint, 8)
    makeStroke(hint, theme.accent, 2)
    
    local hintText = create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Text = "Press " .. keycodeToString(toggleKey) .. " to open",
        TextColor3 = theme.text,
        Font = Enum.Font.GothamBold,
        TextSize = 15,
        Parent = hint
    })
    
    -- Mobile open button
    local mobileOpenBtn = create("TextButton", {
        Name = "MobileOpen",
        Visible = false,
        BackgroundColor3 = theme.accent,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(140, 42),
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 60),
        Text = "Open Menu",
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        ZIndex = 500,
        Parent = gui
    })
    makeRounded(mobileOpenBtn, 10)
    
    -- TOGGLE BUTTON (draggable, changes appearance based on state)
    local uiVisible = true
    
    local toggleBtn = create("TextButton", {
        Name = "ToggleButton",
        BackgroundColor3 = Color3.fromRGB(200, 50, 50),
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(50, 50),
        Position = UDim2.new(1, -70, 1, -70),
        Text = "X",
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = 24,
        ZIndex = 999,
        Parent = gui
    })
    makeRounded(toggleBtn, 25)
    makeStroke(toggleBtn, Color3.fromRGB(255, 100, 100), 2)
    
    local function updateToggleBtnAppearance()
        if uiVisible then
            toggleBtn.Text = "X"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
            local stroke = toggleBtn:FindFirstChildOfClass("UIStroke")
            if stroke then stroke.Color = Color3.fromRGB(255, 100, 100) end
        else
            toggleBtn.Text = "="
            toggleBtn.BackgroundColor3 = theme.accent
            local stroke = toggleBtn:FindFirstChildOfClass("UIStroke")
            if stroke then stroke.Color = theme.accentDark end
        end
    end
    
    -- Make toggle button draggable
    do
        local dragging, dragStart, startPos = false, Vector2.new(), toggleBtn.Position
        
        toggleBtn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = toggleBtn.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)
        
        UIS.InputChanged:Connect(function(input)
            if not dragging then return end
            if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
            local delta = input.Position - dragStart
            toggleBtn.Position = UDim2.new(
                startPos.X.Scale, math.floor(startPos.X.Offset + delta.X + 0.5),
                startPos.Y.Scale, math.floor(startPos.Y.Offset + delta.Y + 0.5)
            )
        end)
    end
    
    local function updateHintText()
        hintText.Text = "Press " .. keycodeToString(toggleKey) .. " to open"
        local sz = getTextSize(hintText.Text, 15, Enum.Font.GothamBold)
        hint.Size = UDim2.fromOffset(sz.X + 30, 38)
    end
    
    local function setUIVisible(visible)
        uiVisible = visible
        panelContainer.Visible = visible
        hint.Visible = not visible
        mobileOpenBtn.Visible = not visible and Config.isMobile
        updateToggleBtnAppearance()
        
        -- Show/hide ArrayList (shows when menu is hidden)
        if showArrayList then
            arrayList.Visible = not visible
        end
        
        -- Animate overlay
        if visible then
            tween(overlay, { BackgroundTransparency = 1 - overlayOpacity }, 0.25)
            if blurEffect then
                tween(blurEffect, { Size = 8 }, 0.25)
            end
        else
            tween(overlay, { BackgroundTransparency = 1 }, 0.2)
            if blurEffect then
                tween(blurEffect, { Size = 0 }, 0.2)
            end
        end
        
        debugLog("UI visibility set to: " .. tostring(visible))
    end
    
    --=========================================================================
    -- AUTO-HIDE ON CHAT (lower DisplayOrder when chat is focused)
    --=========================================================================
    if autoHideOnChat then
        local originalDisplayOrder = gui.DisplayOrder
        local isChatActive = false
        
        -- Try to detect chat via multiple methods
        task.spawn(function()
            while gui and gui.Parent do
                local chatFocused = false
                
                -- Method 1: Check TextService focused textbox
                pcall(function()
                    local focused = UIS:GetFocusedTextBox()
                    if focused and not focused:IsDescendantOf(gui) then
                        chatFocused = true
                    end
                end)
                
                -- Method 2: Check CoreGui chat elements
                if not chatFocused then
                    pcall(function()
                        local chatGui = CoreGui:FindFirstChild("ExperienceChat") or CoreGui:FindFirstChild("Chat")
                        if chatGui then
                            for _, desc in ipairs(chatGui:GetDescendants()) do
                                if desc:IsA("TextBox") and desc:IsFocused() then
                                    chatFocused = true
                                    break
                                end
                            end
                        end
                    end)
                end
                
                -- Method 3: Check PlayerGui for any focused textbox
                if not chatFocused then
                    pcall(function()
                        local playerGui = Player:FindFirstChild("PlayerGui")
                        if playerGui then
                            for _, desc in ipairs(playerGui:GetDescendants()) do
                                if desc:IsA("TextBox") and desc:IsFocused() then
                                    chatFocused = true
                                    break
                                end
                            end
                        end
                    end)
                end
                
                -- Update display order based on chat state
                if chatFocused ~= isChatActive then
                    isChatActive = chatFocused
                    if chatFocused then
                        gui.DisplayOrder = 1
                        debugLog("Chat detected - lowering UI priority")
                    else
                        gui.DisplayOrder = originalDisplayOrder
                        debugLog("Chat closed - restoring UI priority")
                    end
                end
                
                task.wait(0.1) -- Check more frequently
            end
        end)
    end
    
    -- Toggle key listener
    local toggleConn = UIS.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == toggleKey then
            setUIVisible(not uiVisible)
        end
    end)
    
    mobileOpenBtn.MouseButton1Click:Connect(function()
        setUIVisible(true)
    end)
    
    toggleBtn.MouseButton1Click:Connect(function()
        setUIVisible(not uiVisible)
    end)
    
    -- Initial overlay state
    overlay.BackgroundTransparency = 1 - overlayOpacity
    updateToggleBtnAppearance()
    
    -- Apply saved FPS cap
    if SavedSettings.fpsCap and SavedSettings.fpsCap ~= 60 then
        task.defer(function()
            applyFpsCap(SavedSettings.fpsCap)
        end)
    end
    
    --=========================================================================
    -- WINDOW OBJECT & METHODS
    --=========================================================================
    local window = {
        Instance = gui,
        Container = panelContainer,
        Theme = theme,
        _panels = {},
        _toggleKey = toggleKey,
        _notifyPosition = notifyPosition,
        _connections = { toggleConn },
    }
    setmetatable(window, { __index = EclipseUI })
    
    --=========================================================================
    -- NOTIFICATION SYSTEM (Configurable)
    --=========================================================================
    -- Store notification config
    local notifyConfig = cfg.NotifyConfig or {
        size = "medium", -- "small", "medium", "large"
        backgroundColor = nil, -- nil = use theme.panel
        textColor = nil, -- nil = use theme.text
        accentColor = nil, -- nil = use theme.accent
        fontSize = 16, -- Default font size
        minWidth = 300, -- Minimum width
        maxWidth = 400, -- Maximum width
        padding = {top = 12, bottom = 12, left = 16, right = 16} -- Padding values
    }
    
    -- Size presets
    local sizePresets = {
        small = {fontSize = 14, minWidth = 250, maxWidth = 320, padding = {top = 10, bottom = 10, left = 14, right = 14}},
        medium = {fontSize = 16, minWidth = 300, maxWidth = 400, padding = {top = 12, bottom = 12, left = 16, right = 16}},
        large = {fontSize = 18, minWidth = 350, maxWidth = 500, padding = {top = 14, bottom = 14, left = 18, right = 18}}
    }
    
    -- Apply size preset if specified
    if notifyConfig.size and sizePresets[notifyConfig.size] then
        local preset = sizePresets[notifyConfig.size]
        notifyConfig.fontSize = notifyConfig.fontSize or preset.fontSize
        notifyConfig.minWidth = notifyConfig.minWidth or preset.minWidth
        notifyConfig.maxWidth = notifyConfig.maxWidth or preset.maxWidth
        notifyConfig.padding = notifyConfig.padding or preset.padding
    end
    
    function window:SetNotifyConfig(config)
        notifyConfig = config or notifyConfig
    end
    
    function window:Notify(text, duration, options)
        options = options or {}
        duration = duration or options.duration or Config.notifyDuration
        
        -- Get config from options or use defaults
        local bgColor = options.backgroundColor or notifyConfig.backgroundColor or theme.panel
        local txtColor = options.textColor or notifyConfig.textColor or theme.text
        local accColor = options.accentColor or notifyConfig.accentColor or theme.accent
        local fontSize = options.fontSize or notifyConfig.fontSize or 16
        local minW = options.minWidth or notifyConfig.minWidth or 300
        local maxW = options.maxWidth or notifyConfig.maxWidth or 400
        local padding = options.padding or notifyConfig.padding or {top = 12, bottom = 12, left = 16, right = 16}
        
        -- Calculate text size to determine notification width
        local textSize = getTextSize(tostring(text), fontSize, Enum.Font.Gotham)
        local notifWidth = math.clamp(textSize.X + padding.left + padding.right + 50, minW, maxW)
        
        local notif = create("Frame", {
            BackgroundColor3 = bgColor,
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(notifWidth, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Parent = notifContainer
        })
        makeRounded(notif, 8)
        makeStroke(notif, theme.stroke, 1)
        
        local accentBar = create("Frame", {
            BackgroundColor3 = accColor,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 5, 1, 0),
            Parent = notif
        })
        makeRounded(accentBar, 2)
        
        create("UIPadding", { 
            Parent = notif, 
            PaddingTop = UDim.new(0, padding.top), 
            PaddingBottom = UDim.new(0, padding.bottom), 
            PaddingLeft = UDim.new(0, padding.left),
            PaddingRight = UDim.new(0, padding.right) 
        })
        
        -- Position text after the accent bar
        local notifTextOffset = create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -35, 1, 0),
            Position = UDim2.fromOffset(8, 0),
            Parent = notif
        })
        
        local notifLabel = create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -30, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Position = UDim2.fromOffset(0, 0),
            Text = tostring(text),
            TextColor3 = txtColor,
            Font = Enum.Font.Gotham,
            TextSize = fontSize,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = notifTextOffset
        })
        
        local closeBtnNotif = create("TextButton", {
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(24, 24),
            Position = UDim2.new(1, -20, 0, 4),
            Text = "×",
            TextColor3 = theme.textDim,
            Font = Enum.Font.GothamBold,
            TextSize = fontSize + 2,
            Parent = notif
        })
        
        notif.BackgroundTransparency = 1
        notifLabel.TextTransparency = 1
        accentBar.BackgroundTransparency = 1
        
        tween(notif, { BackgroundTransparency = 0 }, 0.2)
        tween(notifLabel, { TextTransparency = 0 }, 0.2)
        tween(accentBar, { BackgroundTransparency = 0 }, 0.2)
        
        local function dismiss()
            tween(notif, { BackgroundTransparency = 1 }, 0.15)
            tween(notifLabel, { TextTransparency = 1 }, 0.15)
            tween(accentBar, { BackgroundTransparency = 1 }, 0.15)
            task.delay(0.16, function()
                if notif and notif.Parent then notif:Destroy() end
            end)
        end
        
        closeBtnNotif.MouseButton1Click:Connect(dismiss)
        task.delay(duration, function()
            if notif and notif.Parent then dismiss() end
        end)
        
        return notif
    end
    
    --=========================================================================
    -- SET NOTIFICATION POSITION
    --=========================================================================
    function window:SetNotifyPosition(pos)
        notifyPosition = pos
        window._notifyPosition = pos
        SavedSettings.notifyPosition = pos
        saveSettings()
        updateNotifPosition()
        
        local layout = notifContainer:FindFirstChildOfClass("UIListLayout")
        if layout then
            layout.VerticalAlignment = pos:find("Bottom") and Enum.VerticalAlignment.Bottom or Enum.VerticalAlignment.Top
            layout.HorizontalAlignment = pos:find("Left") and Enum.HorizontalAlignment.Left or Enum.HorizontalAlignment.Right
        end
    end
    
    --=========================================================================
    -- SET THEME
    --=========================================================================
    function window:SetTheme(themeName)
        if Themes[themeName] then
            publishTheme(Themes[themeName])
            window.Theme = CurrentTheme
            theme = CurrentTheme
            SavedSettings.theme = themeName
            saveSettings()
            
            overlay.BackgroundColor3 = CurrentTheme.overlay
            updateToggleBtnAppearance()
            
            window:Notify("Theme changed to " .. themeName, 2)
        end
    end
    
    --=========================================================================
    -- SET TOGGLE KEY
    --=========================================================================
    function window:SetToggleKey(keyCode)
        toggleKey = keyCode
        window._toggleKey = keyCode
        SavedSettings.toggleKey = keycodeToString(keyCode)
        saveSettings()
        updateHintText()
    end
    
    --=========================================================================
    -- SET UI SCALE
    --=========================================================================
    function window:SetScale(scale)
        Config.uiScale = math.clamp(scale, 0.8, 1.3)
        uiScaleObj.Scale = Config.uiScale
        -- Note: Scale is intentionally NOT saved to prevent off-screen issues
    end
    
    function window:GetScale()
        return Config.uiScale
    end
    
    --=========================================================================
    -- TOGGLE VISIBILITY
    --=========================================================================
    function window:Toggle()
        setUIVisible(not uiVisible)
    end
    
    function window:Show()
        setUIVisible(true)
    end
    
    function window:Hide()
        setUIVisible(false)
    end
    
    --=========================================================================
    -- DESTROY
    --=========================================================================
    function window:Destroy()
        -- First, untoggle all enabled toggles by calling their callbacks
        debugLog("Untoggling all active modules before destroy...")
        local modulesToUntoggle = {}
        
        -- Collect all enabled toggle modules first
        for _, panel in ipairs(window._panels) do
            if panel._modules then
                for _, module in ipairs(panel._modules) do
                    pcall(function()
                        -- Check if module is a toggle and is enabled
                        if module._isToggle and module.Get and module.Set and module.Instance then
                            local isEnabled = module:Get()
                            if isEnabled then
                                local moduleName = module.Instance.Name
                                table.insert(modulesToUntoggle, module)
                                debugLog("Will untoggle: " .. moduleName)
                            end
                        end
                    end)
                end
            end
        end
        
        -- Now untoggle them by calling their callbacks
        for _, module in ipairs(modulesToUntoggle) do
            pcall(function()
                -- Trigger the callback with false to properly disable the feature
                module:TriggerCallback(false)
                -- Also update the visual state
                module:Set(false)
            end)
        end
        
        -- Wait a brief moment for callbacks to execute and cleanup
        task.wait(0.3)
        
        -- Now destroy connections and UI
        for _, conn in ipairs(window._connections) do
            if conn then pcall(function() conn:Disconnect() end) end
        end
        if blurEffect then blurEffect:Destroy() end
        if gui then gui:Destroy() end
        debugLog("Window destroyed")
    end
    
    --=========================================================================
    -- CHANGELOG METHODS
    --=========================================================================
    function window:AddChangelog(version, changes)
        table.insert(changelogEntries, {
            version = version,
            changes = changes,
            timestamp = os.date("%Y-%m-%d")
        })
        debugLog("Changelog entry added: " .. version)
    end
    
    function window:ShowChangelog()
        if changelogFrame then
            changelogFrame.Visible = true
            return
        end
        
        changelogFrame = create("Frame", {
            Name = "ChangelogViewer",
            BackgroundColor3 = theme.bg,
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(450, 400),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            ZIndex = 800,
            Parent = gui
        })
        makeRounded(changelogFrame, 10)
        makeStroke(changelogFrame, theme.accent, 2)
        
        local changelogHeader = create("Frame", {
            BackgroundColor3 = theme.panelHeader,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 40),
            Parent = changelogFrame
        })
        makeRounded(changelogHeader, 10)
        
        create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -80, 1, 0),
            Position = UDim2.fromOffset(15, 0),
            Text = "Changelog (drag header to move)",
            TextColor3 = theme.accent,
            Font = Enum.Font.GothamBold,
            TextSize = 16,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = changelogHeader
        })
        
        local closeBtn = create("TextButton", {
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(30, 30),
            Position = UDim2.new(1, -35, 0.5, -15),
            Text = "X",
            TextColor3 = theme.text,
            Font = Enum.Font.GothamBold,
            TextSize = 16,
            ZIndex = 801,
            Parent = changelogHeader
        })
        closeBtn.MouseButton1Click:Connect(function()
            changelogFrame.Visible = false
        end)
        
        -- DRAG functionality for changelog
        local clDragging, clDragStart, clStartPos = false, Vector2.new(), changelogFrame.Position
        changelogHeader.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                clDragging = true
                clDragStart = input.Position
                clStartPos = changelogFrame.Position
                    input.Changed:Connect(function()
                        if input.UserInputState == Enum.UserInputState.End then
                        clDragging = false
                    end
                end)
            end
        end)
        
        local clDragConn = UIS.InputChanged:Connect(function(input)
            if not clDragging then return end
            if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
            local delta = input.Position - clDragStart
            changelogFrame.Position = UDim2.new(
                clStartPos.X.Scale, clStartPos.X.Offset + delta.X,
                clStartPos.Y.Scale, clStartPos.Y.Offset + delta.Y
            )
        end)
        table.insert(window._connections, clDragConn)
        
        -- RESIZE handle (bottom-right corner)
        local resizeHandle = create("TextButton", {
            BackgroundColor3 = theme.accent,
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(20, 20),
            Position = UDim2.new(1, -20, 1, -20),
            Text = "//",
            TextColor3 = theme.text,
            Font = Enum.Font.GothamBold,
            TextSize = 10,
            ZIndex = 801,
            Parent = changelogFrame
        })
        makeRounded(resizeHandle, 4)
        
        local resizing, resizeStart, startSize = false, Vector2.new(), changelogFrame.Size
        resizeHandle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                resizing = true
                resizeStart = input.Position
                startSize = changelogFrame.Size
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        resizing = false
                    end
                end)
            end
        end)
        
        local resizeConn = UIS.InputChanged:Connect(function(input)
            if not resizing then return end
            if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
            local delta = input.Position - resizeStart
            local newW = math.clamp(startSize.X.Offset + delta.X, 300, 800)
            local newH = math.clamp(startSize.Y.Offset + delta.Y, 200, 600)
            changelogFrame.Size = UDim2.fromOffset(newW, newH)
        end)
        table.insert(window._connections, resizeConn)
        
        local changelogScroll = create("ScrollingFrame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -20, 1, -65),
            Position = UDim2.fromOffset(10, 45),
            ScrollBarThickness = 6,
            ScrollBarImageColor3 = theme.accent,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Parent = changelogFrame
        })
        
        create("UIListLayout", {
            Parent = changelogScroll,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 15)
        })
        
        -- Build changelog content (NEWEST FIRST - use positive index for older entries)
        local totalEntries = #changelogEntries
        for i, entry in ipairs(changelogEntries) do
            local entryFrame = create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                LayoutOrder = i, -- First added = first shown (add newest first in script!)
                Parent = changelogScroll
            })
            
            create("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 24),
                Text = "v" .. entry.version .. " - " .. entry.timestamp,
                TextColor3 = theme.accent,
                Font = Enum.Font.GothamBold,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = entryFrame
            })
            
            local changesText = create("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 0),
                Position = UDim2.fromOffset(0, 26),
                AutomaticSize = Enum.AutomaticSize.Y,
                Text = entry.changes,
                TextColor3 = theme.text,
                Font = Enum.Font.Gotham,
                TextSize = 13,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left,
                RichText = true,
                Parent = entryFrame
            })
        end
        
        if #changelogEntries == 0 then
            create("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 40),
                Text = "No changelog entries yet",
                TextColor3 = theme.textDim,
                Font = Enum.Font.Gotham,
                TextSize = 14,
                Parent = changelogScroll
            })
        end
    end
    
    function window:HideChangelog()
        if changelogFrame then changelogFrame.Visible = false end
    end
    
    --=========================================================================
    -- DEBUG MODE
    --=========================================================================
    function window:SetDebugMode(enabled)
        Config.debugMode = enabled
        SavedSettings.debugMode = enabled
        saveSettings()
        debugLog("Debug mode " .. (enabled and "enabled" or "disabled"))
    end
    
    function window:GetDebugLogs()
        return DebugLogs
    end
    
    --=========================================================================
    -- ARRAY LIST METHODS
    --=========================================================================
    function window:SetArrayListPosition(pos)
        -- pos: "Left" or "Right"
        SavedSettings.arrayListPosition = pos
        saveSettings()
        if pos == "Left" then
            arrayList.AnchorPoint = Vector2.new(0, 0)
            arrayList.Position = UDim2.new(0, 10, 0, 60)
            local layout = arrayList:FindFirstChildOfClass("UIListLayout")
            if layout then layout.HorizontalAlignment = Enum.HorizontalAlignment.Left end
        else
            arrayList.AnchorPoint = Vector2.new(1, 0)
            arrayList.Position = UDim2.new(1, -10, 0, 60)
            local layout = arrayList:FindFirstChildOfClass("UIListLayout")
            if layout then layout.HorizontalAlignment = Enum.HorizontalAlignment.Right end
        end
    end
    
    --=========================================================================
    -- ADD PANEL (Section/Category)
    --=========================================================================
    function window:AddPanel(name, position)
        local theme = CurrentTheme
        local panelWidth = scaled(Config.panelWidth)
        
        if Config.isMobile then
            panelWidth = math.min(panelWidth, gui.AbsoluteSize.X * 0.45)
        end
        
        position = position or UDim2.fromOffset(15 + (#window._panels * (panelWidth + 15)), 15)
        
        local panel = create("Frame", {
            Name = "Panel_" .. name,
            BackgroundColor3 = theme.panel,
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(panelWidth, scaled(Config.headerHeight)),
            Position = position,
            AutomaticSize = Enum.AutomaticSize.Y,
            Parent = panelContainer
        })
        makeRounded(panel, Config.cornerRadius)
        makeStroke(panel, theme.stroke)
        
        local header = create("Frame", {
            Name = "Header",
            BackgroundColor3 = theme.panelHeader,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, scaled(Config.headerHeight)),
            Parent = panel
        })
        makeRounded(header, Config.cornerRadius)
        
        local headerTitle = create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -35, 1, 0),
            Position = UDim2.fromOffset(10, 0),
            Text = name,
            TextColor3 = theme.accent,
            Font = Enum.Font.GothamBold,
            TextSize = scaled(15),
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = header
        })
        
        local collapseBtn = create("TextButton", {
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(24, 24),
            Position = UDim2.new(1, -28, 0.5, -12),
            Text = "v",
            TextColor3 = theme.textDim,
            Font = Enum.Font.GothamBold,
            TextSize = scaled(14),
            Parent = header
        })
        
        local content = create("Frame", {
            Name = "Content",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            Position = UDim2.fromOffset(0, scaled(Config.headerHeight)),
            AutomaticSize = Enum.AutomaticSize.Y,
            ClipsDescendants = true,
            Parent = panel
        })
        
        create("UIListLayout", {
            Parent = content,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 3)
        })
        
        create("UIPadding", {
            Parent = content,
            PaddingTop = UDim.new(0, 6),
            PaddingBottom = UDim.new(0, 6),
            PaddingLeft = UDim.new(0, 6),
            PaddingRight = UDim.new(0, 6)
        })
        
        local collapsed = false
        local contentHeight = 0
        
        -- Track content height
        local function measureContentHeight()
            local layout = content:FindFirstChildOfClass("UIListLayout")
            if layout then
                return layout.AbsoluteContentSize.Y + 12 -- Add padding
            end
            return 100
        end
        
        collapseBtn.MouseButton1Click:Connect(function()
            collapsed = not collapsed
            
            -- Smooth rotation animation for arrow
            tween(collapseBtn, { Rotation = collapsed and -90 or 0 }, 0.2, Enum.EasingStyle.Quad)
            
            if collapsed then
                -- Collapse: IMMEDIATELY hide content to prevent janky text showing
                content.Visible = false
                panel.AutomaticSize = Enum.AutomaticSize.None
                local currentHeight = panel.AbsoluteSize.Y / Config.uiScale
                panel.Size = UDim2.fromOffset(panelWidth, currentHeight)
                
                tween(panel, { Size = UDim2.fromOffset(panelWidth, scaled(Config.headerHeight)) }, 0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            else
                -- Expand: animate panel first, then show content
                contentHeight = measureContentHeight()
                local targetHeight = scaled(Config.headerHeight) + contentHeight
                
                tween(panel, { Size = UDim2.fromOffset(panelWidth, targetHeight) }, 0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
                task.delay(0.1, function()
                    content.Visible = true
                    task.delay(0.15, function()
                        panel.AutomaticSize = Enum.AutomaticSize.Y
                    end)
                end)
            end
        end)
        
        -- Simple delta-based dragging
        local dragging = false
        local lastMousePos = Vector2.new()
        local dragStartPanelPos = UDim2.new()
        local dragStartMousePos = Vector2.new()
        
        header.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStartMousePos = Vector2.new(input.Position.X, input.Position.Y)
                dragStartPanelPos = panel.Position
                lastMousePos = dragStartMousePos
            end
        end)
        
        header.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                            dragging = false
                        end
                    end)
        
        local dragConn = UIS.InputChanged:Connect(function(input)
            if not dragging then return end
            if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
            
            local mousePos = Vector2.new(input.Position.X, input.Position.Y)
            local totalDelta = mousePos - dragStartMousePos
            
            -- Apply delta to the ORIGINAL position (preserving Scale if any)
            local newX = dragStartPanelPos.X.Scale * gui.AbsoluteSize.X + dragStartPanelPos.X.Offset + totalDelta.X / Config.uiScale
            local newY = dragStartPanelPos.Y.Scale * gui.AbsoluteSize.Y + dragStartPanelPos.Y.Offset + totalDelta.Y / Config.uiScale
            
            -- Set as pure offset (Scale = 0)
            panel.Position = UDim2.fromOffset(math.floor(newX), math.floor(newY))
        end)
        table.insert(window._connections, dragConn)
        
        -- Theme subscriber
        subscribeTheme(function(t)
            panel.BackgroundColor3 = t.panel
            header.BackgroundColor3 = t.panelHeader
            headerTitle.TextColor3 = t.accent
            collapseBtn.TextColor3 = t.textDim
            local stroke = panel:FindFirstChildOfClass("UIStroke")
            if stroke then stroke.Color = t.stroke end
        end)
        
        --=====================================================================
        -- PANEL OBJECT & MODULE METHODS
        --=====================================================================
        local panelObj = {
            Instance = panel,
            Header = header,
            Content = content,
            _modules = {},
        }
        
        table.insert(window._panels, panelObj)
        
        --=====================================================================
        -- ADD MODULE (with expandable settings)
        --=====================================================================
        function panelObj:AddModule(cfg)
            cfg = cfg or {}
            local theme = CurrentTheme
            local hasSettings = cfg.settings and #cfg.settings > 0
            
            local moduleHolder = create("Frame", {
                Name = "Module_" .. (cfg.name or "Module"),
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, scaled(Config.moduleHeight)),
                AutomaticSize = Enum.AutomaticSize.Y,
                Parent = content
            })
            
            local moduleRow = create("Frame", {
                Name = "Row",
                BackgroundColor3 = theme.panel,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, scaled(Config.moduleHeight)),
                Parent = moduleHolder
            })
            makeRounded(moduleRow, 4)
            
            -- Track hover state for this module
            trackHover(moduleRow, theme.panel, theme.hover)
            
            local moduleBtn = create("TextButton", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, hasSettings and -24 or 0, 1, 0),
                Text = "",
                Parent = moduleRow
            })
            
            -- Determine if this is a toggle or button type
            local isToggle = cfg.type == "toggle" or cfg.type == nil
            local isButton = cfg.type == "button"
            
            -- Toggle indicator (small switch visual for toggles only)
            local toggleIndicator, toggleKnob
            if isToggle then
                -- Use CurrentTheme for initial creation (not captured theme variable)
                local currentTheme = CurrentTheme
                toggleIndicator = create("Frame", {
                    Name = "ToggleIndicator",
                    BackgroundColor3 = cfg.default and currentTheme.accent or currentTheme.disabled, -- Use currentTheme.accent when enabled (theme-adaptive)
                    BorderSizePixel = 0,
                    Size = UDim2.fromOffset(28, 14),
                    Position = UDim2.new(0, 8, 0.5, -7),
                    Parent = moduleRow
                })
                makeRounded(toggleIndicator, 7)
                
                -- Add subtle stroke for better visibility and theme adaptation
                local indicatorStroke = create("UIStroke", {
                    Color = cfg.default and currentTheme.accentDark or currentTheme.stroke,
                    Thickness = 1,
                    Transparency = 0.3,
                    Parent = toggleIndicator
                })
                
                toggleKnob = create("Frame", {
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    BorderSizePixel = 0,
                    Size = UDim2.fromOffset(10, 10),
                    Position = cfg.default and UDim2.fromOffset(16, 2) or UDim2.fromOffset(2, 2),
                    Parent = toggleIndicator
                })
                makeRounded(toggleKnob, 5)
            elseif isButton then
                -- Subtle button visual indicator (thin accent bar on left)
                local btnIndicator = create("Frame", {
                    Name = "ButtonIndicator",
                    BackgroundColor3 = theme.accent,
                    BorderSizePixel = 0,
                    Size = UDim2.fromOffset(2, scaled(Config.moduleHeight) - 10),
                    Position = UDim2.new(0, 4, 0.5, -(scaled(Config.moduleHeight) - 10) / 2),
                    Parent = moduleRow
                })
                makeRounded(btnIndicator, 1)
            end
            
            -- Check for saved toggle state first, then fall back to default (BEFORE creating UI elements)
            local moduleNameStr = cfg.name or "Module" -- String name for saving/loading
            local enabled = cfg.default or false
            local gameToggleStates = getGameToggleStates()
            if gameToggleStates[moduleNameStr] ~= nil then
                enabled = gameToggleStates[moduleNameStr]
            end
            
            -- Helper function to get initial text color based on theme colored text setting
            local function getInitialTextColor()
                local currentTheme = CurrentTheme -- Use CurrentTheme, not captured theme
                if not SavedSettings.themeColoredText then
                    return currentTheme.text -- Plain white when disabled
                end
                if isButton then
                    return currentTheme.accent -- Buttons always use accent
                end
                -- Toggles use accent when enabled, text when disabled
                return (enabled and currentTheme.accent) or currentTheme.text
            end
            
            local moduleNameLabel = create("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, isToggle and -45 or (isButton and -20 or -10), 1, 0),
                Position = UDim2.fromOffset(isToggle and 42 or (isButton and 12 or 10), 0),
                Text = cfg.name or "Module",
                TextColor3 = getInitialTextColor(), -- Theme-adaptive text color
                Font = isButton and Enum.Font.GothamBold or Enum.Font.Gotham,
                TextSize = scaled(13),
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = moduleBtn
            })
            local moduleName = moduleNameLabel -- Keep moduleName for backward compatibility
            
            local expandBtn
            local expanded = false
            
            if hasSettings then
                expandBtn = create("TextButton", {
                    BackgroundTransparency = 1,
                    Size = UDim2.fromOffset(24, scaled(Config.moduleHeight)),
                    Position = UDim2.new(1, -24, 0, 0),
                    Text = ">",
                    TextColor3 = theme.textDim,
                    Font = Enum.Font.GothamBold,
                    TextSize = scaled(14),
                    Parent = moduleRow
                })
            end
            
            local settingsContainer
            if hasSettings then
                settingsContainer = create("Frame", {
                    Name = "Settings",
                    BackgroundColor3 = theme.bg,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 0),
                    Position = UDim2.fromOffset(0, scaled(Config.moduleHeight)),
                    ClipsDescendants = true,
                    Visible = false,
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Parent = moduleHolder
                })
                makeRounded(settingsContainer, 4)
                
                create("UIListLayout", {
                    Parent = settingsContainer,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 3)
                })
                
                create("UIPadding", {
                    Parent = settingsContainer,
                    PaddingTop = UDim.new(0, 6),
                    PaddingBottom = UDim.new(0, 6),
                    PaddingLeft = UDim.new(0, 10),
                    PaddingRight = UDim.new(0, 10)
                })
            end
            
            local function updateState()
                -- Always use CurrentTheme (not the captured theme variable) so it updates when theme changes
                local currentTheme = CurrentTheme
                -- Update text color based on theme colored text setting (use moduleNameLabel to avoid conflicts)
                -- Defensive check: ensure moduleNameLabel is a TextLabel instance
                if moduleNameLabel and typeof(moduleNameLabel) == "Instance" and moduleNameLabel:IsA("TextLabel") and moduleNameLabel.Parent then
                    if SavedSettings.themeColoredText then
                        if isButton then
                            moduleNameLabel.TextColor3 = currentTheme.accent
                        else
                            moduleNameLabel.TextColor3 = enabled and currentTheme.accent or currentTheme.text
                        end
                    else
                        moduleNameLabel.TextColor3 = currentTheme.text -- Plain white when setting is disabled
                    end
                end
                -- Animate toggle indicator if it exists (use currentTheme.accent when enabled for theme-adaptation)
                if toggleIndicator then
                    tween(toggleIndicator, { BackgroundColor3 = enabled and currentTheme.accent or currentTheme.disabled }, 0.15)
                    -- Update stroke color too
                    local stroke = toggleIndicator:FindFirstChildOfClass("UIStroke")
                    if stroke then
                        tween(stroke, { Color = enabled and currentTheme.accentDark or currentTheme.stroke }, 0.15)
                    end
                end
                if toggleKnob then
                    tween(toggleKnob, { Position = enabled and UDim2.fromOffset(16, 2) or UDim2.fromOffset(2, 2) }, 0.15)
                end
            end
            
            -- Function to toggle settings expansion (with smooth animation)
            local function toggleExpand()
                if not hasSettings then return end
                expanded = not expanded
                
                -- Animate arrow rotation
                if expandBtn then
                    tween(expandBtn, { Rotation = expanded and 90 or 0 }, 0.15, Enum.EasingStyle.Quad)
                end
                
                if expanded then
                    -- Show container and animate expansion
                    settingsContainer.Visible = true
                    settingsContainer.BackgroundTransparency = 1
                    
                    -- Measure target height
                    local layout = settingsContainer:FindFirstChildOfClass("UIListLayout")
                    local targetHeight = layout and (layout.AbsoluteContentSize.Y + 12) or 50
                    
                    -- Animate the container fade in
                    tween(settingsContainer, { BackgroundTransparency = 0 }, 0.15)
                    
                    -- Set auto size after a brief delay
                    task.delay(0.05, function()
                        moduleHolder.AutomaticSize = Enum.AutomaticSize.Y
                    end)
                else
                    -- Animate collapse
                    tween(settingsContainer, { BackgroundTransparency = 1 }, 0.1)
                    task.delay(0.1, function()
                        settingsContainer.Visible = false
                        moduleHolder.AutomaticSize = Enum.AutomaticSize.None
                        moduleHolder.Size = UDim2.new(1, 0, 0, scaled(Config.moduleHeight))
                    end)
                end
                debugLog("Module '" .. (cfg.name or "Module") .. "' expanded: " .. tostring(expanded))
            end
            
            if cfg.type == "toggle" or cfg.type == nil then
                -- Apply initial state if it was loaded from saved settings
                local gameToggleStates = getGameToggleStates()
                local wasLoadedFromSave = gameToggleStates[moduleNameStr] ~= nil
                if wasLoadedFromSave then
                    -- State was loaded from saved settings, apply it visually
                    updateState()
                    setModuleActive(moduleNameStr, enabled)
                    -- Call callback with saved state (but don't notify) - delay slightly to ensure game is ready
                    if cfg.callback then
                        task.delay(0.5, function()
                            task.spawn(cfg.callback, enabled)
                        end)
                    end
                end
                
                moduleBtn.MouseButton1Click:Connect(function()
                    enabled = not enabled
                    updateState()
                    -- Save toggle state (game-specific)
                    local gameToggleStates = getGameToggleStates()
                    gameToggleStates[moduleNameStr] = enabled
                    saveSettings()
                    -- Update ArrayList
                    setModuleActive(moduleNameStr, enabled)
                    if cfg.callback then
                        task.spawn(cfg.callback, enabled)
                    end
                    if cfg.notify then
                        local notifyMsg = cfg.notifyText or (cfg.name .. (enabled and " enabled" or " disabled"))
                        local notifyDur = cfg.notifyDuration or 2
                        local notifyOpts = cfg.notifyConfig
                        if notifyOpts == "default" or notifyOpts == nil then
                            window:Notify(notifyMsg, notifyDur)
                        else
                            window:Notify(notifyMsg, notifyDur, notifyOpts)
                        end
                    end
                end)
            elseif cfg.type == "button" then
                -- Enhanced button click animation
                local baseSize = moduleRow.Size
                moduleBtn.MouseButton1Down:Connect(function()
                    tween(moduleRow, { Size = UDim2.new(1, -2, 0, scaled(Config.moduleHeight) - 2) }, 0.1)
                end)
                
                moduleBtn.MouseButton1Up:Connect(function()
                    tween(moduleRow, { Size = baseSize }, 0.1)
                end)
                
                moduleBtn.MouseButton1Click:Connect(function()
                    if cfg.callback then
                        task.spawn(cfg.callback)
                    end
                    if cfg.notify then
                        local notifyMsg = cfg.notifyText or (cfg.name .. " activated")
                        local notifyDur = cfg.notifyDuration or 2
                        local notifyOpts = cfg.notifyConfig
                        if notifyOpts == "default" or notifyOpts == nil then
                            window:Notify(notifyMsg, notifyDur)
                        else
                            window:Notify(notifyMsg, notifyDur, notifyOpts)
                        end
                    end
                end)
            end
            
            if cfg.tooltip then
                attachTooltip(moduleRow, cfg.tooltip)
            end
            
            -- Expand button click
            if hasSettings and expandBtn then
                expandBtn.MouseButton1Click:Connect(toggleExpand)
            end
            
            -- RIGHT-CLICK to expand settings (alternative to arrow)
            if hasSettings then
                moduleRow.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton2 then
                        toggleExpand()
                        end
                    end)
            end
            
            -- Track module for search
            table.insert(allSearchItems, {
                name = cfg.name or "Module",
                panel = name,
                itemType = "module",
                instance = moduleHolder,
                row = moduleRow
            })
            
            -- Theme subscriber - update hover colors and toggle indicator
            subscribeTheme(function(t)
                updateHoverColors(moduleRow, t.panel, t.hover)
                -- Update text color based on theme colored text setting
                if moduleNameLabel and moduleNameLabel.Parent then
                    if SavedSettings.themeColoredText then
                        if isButton then
                            moduleNameLabel.TextColor3 = t.accent
                        else
                            moduleNameLabel.TextColor3 = enabled and t.accent or t.text
                        end
                    else
                        moduleNameLabel.TextColor3 = t.text -- Plain white when setting is disabled
                    end
                end
                local btnIndicator = moduleRow:FindFirstChild("ButtonIndicator")
                if btnIndicator then btnIndicator.BackgroundColor3 = t.accent end
                if expandBtn then expandBtn.TextColor3 = t.textDim end
                if settingsContainer then settingsContainer.BackgroundColor3 = t.bg end
                -- Update toggle indicator with theme colors (theme-adaptive)
                if toggleIndicator then
                    toggleIndicator.BackgroundColor3 = enabled and t.accent or t.disabled
                    local stroke = toggleIndicator:FindFirstChildOfClass("UIStroke")
                    if stroke then
                        stroke.Color = enabled and t.accentDark or t.stroke
                    end
                end
            end)
            
            local moduleObj = {
                Instance = moduleHolder,
                Row = moduleRow,
                SettingsContainer = settingsContainer,
                _controls = {},
                _callback = cfg.callback, -- Store callback for destroy functionality
                _isToggle = isToggle, -- Store if this is a toggle
                _moduleName = moduleNameLabel, -- Store reference to update text color when setting changes
                _isButton = isButton, -- Store if this is a button
            }
            
            function moduleObj:Set(val)
                enabled = val
                updateState()
                -- Also update ArrayList
                if self._isToggle then
                    setModuleActive(cfg.name or "Module", enabled)
                end
            end
            
            function moduleObj:Get()
                return enabled
            end
            
            -- Method to trigger the callback (for destroy functionality)
            function moduleObj:TriggerCallback(val)
                if self._callback then
                    task.spawn(self._callback, val)
                end
            end
            
            if hasSettings and settingsContainer then
                for _, setting in ipairs(cfg.settings) do
                    panelObj:_addSetting(settingsContainer, setting)
                end
            end
            
            table.insert(panelObj._modules, moduleObj)
            return moduleObj
        end
        
        --=====================================================================
        -- INTERNAL: Add setting to a container
        --=====================================================================
        function panelObj:_addSetting(container, setting)
            local theme = CurrentTheme
            local settingType = setting.type or "label"
            
            if settingType == "label" then
                local isBold = setting.bold == true
                local fontSize = setting.fontSize or 12
                local fontColor = setting.color or theme.textDim
                
                -- Use RichText with <b> tags for bold text (more reliable than Font property)
                local displayText = setting.text or ""
                if isBold then
                    displayText = "<b>" .. displayText .. "</b>"
                end
                
                -- Calculate proper height based on font size
                local labelHeight = math.max(scaled(fontSize + 4), scaled(Config.settingHeight))
                
                local label = create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, labelHeight),
                    Text = displayText,
                    TextColor3 = fontColor or theme.text, -- Use theme.text as default
                    Font = Enum.Font.Gotham, -- Always use Gotham, bold is handled by RichText
                    TextSize = fontSize, -- Use fontSize directly (not scaled)
                    RichText = true, -- Enable RichText for bold tags
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextWrapped = true,
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Parent = container
                })
                
                -- Store preferences as attributes
                label:SetAttribute("IsBold", isBold)
                label:SetAttribute("FontSize", fontSize)
                label:SetAttribute("OriginalText", setting.text or "")
                if setting.color then
                    label:SetAttribute("HasCustomColor", true)
                    label:SetAttribute("CustomColorR", fontColor.R)
                    label:SetAttribute("CustomColorG", fontColor.G)
                    label:SetAttribute("CustomColorB", fontColor.B)
                end
                
                -- Use RunService to continuously enforce RichText and properties
                local fontEnforcer
                fontEnforcer = RunService.RenderStepped:Connect(function()
                    if not label or not label.Parent then
                        if fontEnforcer then
                            fontEnforcer:Disconnect()
                        end
                        return
                    end
                    
                    -- Ensure RichText is enabled
                    if not label.RichText then
                        label.RichText = true
                    end
                    
                    -- Enforce bold text using RichText tags
                    local originalText = label:GetAttribute("OriginalText")
                    if originalText then
                        local isBoldAttr = label:GetAttribute("IsBold")
                        local currentText = label.Text
                        local expectedText
                        
                        if isBoldAttr == true then
                            expectedText = "<b>" .. originalText .. "</b>"
                        else
                            expectedText = originalText
                        end
                        
                        -- Only update if text doesn't match (avoid infinite loops)
                        if currentText ~= expectedText then
                            label.Text = expectedText
                        end
                    end
                    
                    -- Enforce font size
                    local savedSize = label:GetAttribute("FontSize")
                    if savedSize and label.TextSize ~= savedSize then
                        label.TextSize = savedSize
                    end
                    
                    -- Enforce custom color if set
                    if label:GetAttribute("HasCustomColor") == true then
                        local r = label:GetAttribute("CustomColorR")
                        local g = label:GetAttribute("CustomColorG")
                        local b = label:GetAttribute("CustomColorB")
                        if r and g and b then
                            local customColor = Color3.new(r, g, b)
                            if label.TextColor3 ~= customColor then
                                label.TextColor3 = customColor
                            end
                        end
                    end
                end)
                
                -- Clean up connection when label is destroyed
                label.AncestryChanged:Connect(function()
                    if not label.Parent and fontEnforcer then
                        fontEnforcer:Disconnect()
                    end
                end)
                
                if setting.tooltip then attachTooltip(label, setting.tooltip) end
                return label
                
            elseif settingType == "divider" then
                local divider = create("Frame", {
                    BackgroundColor3 = theme.stroke,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 1),
                    Parent = container
                })
                return divider
                
            elseif settingType == "toggle" then
                local row = create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, scaled(Config.settingHeight)),
                    Parent = container
                })
                
                local label = create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -36, 1, 0),
                    Text = setting.text or "Toggle",
                    TextColor3 = theme.text, -- Consistent text color
                    Font = Enum.Font.Gotham,
                    TextSize = scaled(12),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = row
                })
                
                local toggleBtn = create("TextButton", {
                    BackgroundColor3 = setting.default and theme.enabled or theme.disabled,
                    BorderSizePixel = 0,
                    Size = UDim2.fromOffset(30, 16),
                    Position = UDim2.new(1, -30, 0.5, -8),
                    Text = "",
                    Parent = row
                })
                makeRounded(toggleBtn, 8)
                
                local knob = create("Frame", {
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    BorderSizePixel = 0,
                    Size = UDim2.fromOffset(12, 12),
                    Position = setting.default and UDim2.fromOffset(16, 2) or UDim2.fromOffset(2, 2),
                    Parent = toggleBtn
                })
                makeRounded(knob, 6)
                
                local state = setting.default or false
                
                toggleBtn.MouseButton1Click:Connect(function()
                    state = not state
                    tween(toggleBtn, { BackgroundColor3 = state and theme.enabled or theme.disabled }, 0.1)
                    tween(knob, { Position = state and UDim2.fromOffset(16, 2) or UDim2.fromOffset(2, 2) }, 0.1)
                    if setting.callback then task.spawn(setting.callback, state) end
                end)
                
                if setting.tooltip then attachTooltip(row, setting.tooltip) end
                
                return {
                    Set = function(_, v)
                        state = v
                        toggleBtn.BackgroundColor3 = state and theme.enabled or theme.disabled
                        knob.Position = state and UDim2.fromOffset(16, 2) or UDim2.fromOffset(2, 2)
                    end,
                    Get = function() return state end
                }
                
            elseif settingType == "slider" then
                local row = create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, scaled(Config.settingHeight) + 14),
                    Parent = container
                })
                
                local label = create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0.6, 0, 0, 16),
                    Text = setting.text or "Slider",
                    TextColor3 = theme.text,
                    Font = Enum.Font.Gotham,
                    TextSize = scaled(12),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = row
                })
                
                local valueLabel = create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0.4, 0, 0, 16),
                    Position = UDim2.new(0.6, 0, 0, 0),
                    Text = tostring(setting.default or setting.min or 0) .. (setting.suffix or ""),
                    TextColor3 = theme.accent,
                    Font = Enum.Font.GothamBold,
                    TextSize = scaled(12),
                    TextXAlignment = Enum.TextXAlignment.Right,
                    Parent = row
                })
                
                local sliderBg = create("Frame", {
                    BackgroundColor3 = theme.bg,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 10),
                    Position = UDim2.fromOffset(0, 20),
                    Parent = row
                })
                makeRounded(sliderBg, 5)
                
                local sliderFill = create("Frame", {
                    BackgroundColor3 = theme.accent,
                    BorderSizePixel = 0,
                    Size = UDim2.new(0, 0, 1, 0),
                    Parent = sliderBg
                })
                makeRounded(sliderFill, 5)
                
                local min = setting.min or 0
                local max = setting.max or 100
                local step = setting.step or 1
                local value = math.clamp(setting.default or min, min, max)
                local rounding = setting.rounding or 0
                local suffix = setting.suffix or ""
                
                local function updateSlider(v)
                    value = math.clamp(v, min, max)
                    value = math.floor(value / step + 0.5) * step
                    local pct = (value - min) / math.max(0.0001, max - min)
                    sliderFill.Size = UDim2.new(pct, 0, 1, 0)
                    local display = rounding > 0 and (math.floor(value * 10^rounding + 0.5) / 10^rounding) or value
                    valueLabel.Text = tostring(display) .. suffix
                end
                updateSlider(value)
                
                local dragging = false
                
                local function updateFromInput(input)
                    local rel = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
                    local newVal = min + (max - min) * rel
                    updateSlider(newVal)
                    if setting.callback then task.spawn(setting.callback, value) end
                end
                
                sliderBg.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = true
                        updateFromInput(input)
                    end
                end)
                
                local sliderDragConn = UIS.InputChanged:Connect(function(input)
                    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        updateFromInput(input)
                    end
                end)
                table.insert(window._connections, sliderDragConn)
                
                local sliderEndConn = UIS.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = false
                    end
                end)
                table.insert(window._connections, sliderEndConn)
                
                if setting.tooltip then attachTooltip(row, setting.tooltip) end
                
                -- Theme subscriber for slider
                subscribeTheme(function(t)
                    label.TextColor3 = t.text
                    valueLabel.TextColor3 = t.accent
                    sliderBg.BackgroundColor3 = t.bg
                    sliderFill.BackgroundColor3 = t.accent
                end)
                
                return {
                    _row = row,
                    _sliderBg = sliderBg, -- For highlighting
                    Set = function(_, v) updateSlider(v); if setting.callback then task.spawn(setting.callback, value) end end,
                    Get = function() return value end
                }
                
            elseif settingType == "button" then
                local btn = create("TextButton", {
                    BackgroundColor3 = theme.panelHeader,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, scaled(Config.settingHeight) + 2),
                    Text = setting.text or "Button",
                    TextColor3 = theme.text,
                    Font = Enum.Font.Gotham,
                    TextSize = scaled(12),
                    Parent = container
                })
                makeRounded(btn, 4)
                
                -- Subtle accent bar on left (instead of full background)
                local accentBar = create("Frame", {
                    BackgroundColor3 = theme.accent,
                    BorderSizePixel = 0,
                    Size = UDim2.fromOffset(3, scaled(Config.settingHeight) - 4),
                    Position = UDim2.new(0, 4, 0.5, -(scaled(Config.settingHeight) - 4) / 2),
                    Parent = btn
                })
                makeRounded(accentBar, 1)
                
                -- Subtle hover effect
                local baseColor = theme.panelHeader
                local hoverColor = theme.hover
                
                btn.MouseEnter:Connect(function()
                    tween(btn, { BackgroundColor3 = hoverColor }, 0.15)
                    tween(accentBar, { Size = UDim2.fromOffset(4, scaled(Config.settingHeight) - 2) }, 0.15)
                end)
                
                btn.MouseLeave:Connect(function()
                    tween(btn, { BackgroundColor3 = baseColor }, 0.15)
                    tween(accentBar, { Size = UDim2.fromOffset(3, scaled(Config.settingHeight) - 4) }, 0.15)
                end)
                
                -- Subtle click animation
                local baseSize = btn.Size
                btn.MouseButton1Down:Connect(function()
                    tween(btn, { Size = UDim2.new(1, -1, 0, scaled(Config.settingHeight)) }, 0.1)
                end)
                
                btn.MouseButton1Up:Connect(function()
                    tween(btn, { Size = baseSize }, 0.1)
                end)
                
                btn.MouseButton1Click:Connect(function()
                    if setting.callback then task.spawn(setting.callback) end
                    if setting.notify then
                        local notifyMsg = setting.notifyText or (setting.text .. " clicked")
                        local notifyDur = setting.notifyDuration or 2
                        local notifyOpts = setting.notifyConfig
                        if notifyOpts == "default" or notifyOpts == nil then
                            window:Notify(notifyMsg, notifyDur)
                        else
                            window:Notify(notifyMsg, notifyDur, notifyOpts)
                        end
                    end
                end)
                
                -- Theme subscriber for button
                subscribeTheme(function(t)
                    baseColor = t.panelHeader
                    hoverColor = t.hover
                    btn.BackgroundColor3 = t.panelHeader
                    btn.TextColor3 = t.text
                    if accentBar then accentBar.BackgroundColor3 = t.accent end
                    if not btn:IsMouseOver() then
                        btn.BackgroundColor3 = baseColor
                    end
                end)
                
                if setting.tooltip then attachTooltip(btn, setting.tooltip) end
                return btn
                
            elseif settingType == "input" then
                local row = create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, scaled(Config.settingHeight) + 26),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Parent = container
                })
                
                local label = create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, scaled(Config.settingHeight)),
                    Text = setting.text or "Input",
                    TextColor3 = theme.text,
                    Font = Enum.Font.Gotham,
                    TextSize = scaled(12),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = row
                })
                
                local inputBox = create("TextBox", {
                    BackgroundColor3 = theme.bg,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 22),
                    Position = UDim2.new(0, 0, 0, scaled(Config.settingHeight) + 4),
                    Text = setting.default or "",
                    PlaceholderText = setting.placeholder or "",
                    TextColor3 = theme.text,
                    PlaceholderColor3 = theme.textDim,
                    Font = Enum.Font.Gotham,
                    TextSize = scaled(12),
                    ClearTextOnFocus = setting.clearOnFocus or false,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    Parent = row
                })
                makeRounded(inputBox, 4)
                create("UIPadding", { Parent = inputBox, PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) })
                
                inputBox.FocusLost:Connect(function(enter)
                    if setting.callback then task.spawn(setting.callback, inputBox.Text) end
                end)
                
                if setting.tooltip then attachTooltip(row, setting.tooltip) end
                
                return {
                    _row = row,
                    _inputBox = inputBox, -- For highlighting
                    Set = function(_, t) inputBox.Text = tostring(t or "") end,
                    Get = function() return inputBox.Text end
                }
                
            elseif settingType == "keybind" then
                local row = create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, scaled(Config.settingHeight)),
                    Parent = container
                })
                
                local label = create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0.5, 0, 1, 0),
                    Text = setting.text or "Keybind",
                    TextColor3 = theme.text,
                    Font = Enum.Font.Gotham,
                    TextSize = scaled(12),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = row
                })
                
                local keyBtn = create("TextButton", {
                    BackgroundColor3 = theme.bg,
                    BorderSizePixel = 0,
                    Size = UDim2.new(0.48, 0, 0, 20),
                    Position = UDim2.new(0.52, 0, 0.5, -10),
                    Text = keycodeToString(setting.default or Enum.KeyCode.Unknown),
                    TextColor3 = theme.accent,
                    Font = Enum.Font.GothamBold,
                    TextSize = scaled(11),
                    Parent = row
                })
                makeRounded(keyBtn, 4)
                
                local listening = false
                local currentKey = setting.default or Enum.KeyCode.Unknown
                
                keyBtn.MouseButton1Click:Connect(function()
                    if listening then return end
                    listening = true
                    keyBtn.Text = "..."
                    
                    local conn
                    conn = UIS.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            currentKey = input.KeyCode
                            keyBtn.Text = keycodeToString(currentKey)
                            listening = false
                            if conn then conn:Disconnect() end
                            if setting.callback then task.spawn(setting.callback, currentKey) end
                        end
                    end)
                end)
                
                if setting.tooltip then attachTooltip(row, setting.tooltip) end
                
                return {
                    _row = row,
                    _keyBtn = keyBtn, -- For highlighting
                    Set = function(_, kc) currentKey = kc; keyBtn.Text = keycodeToString(kc) end,
                    Get = function() return currentKey end
                }
                
            elseif settingType == "dropdown" then
                local row = create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, scaled(Config.settingHeight) + 26),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Parent = container
                })
                
                local label = create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, scaled(Config.settingHeight)),
                    Text = setting.text or "Dropdown",
                    TextColor3 = theme.text,
                    Font = Enum.Font.Gotham,
                    TextSize = scaled(12),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = row
                })
                
                local isMultiple = setting.multiple == true
                local options = setting.options or {}
                local selectedValues = {}
                
                -- Get dropdown name for saving/loading (prioritize name, then text)
                local dropdownNameStr = (setting.name or setting.text) or "Dropdown"
                local gameDropdownStates = getGameDropdownStates()
                
                -- Initialize selected values (check for saved state first)
                if isMultiple then
                    -- Check for saved multi-select state
                    if gameDropdownStates[dropdownNameStr] and type(gameDropdownStates[dropdownNameStr]) == "table" then
                        for _, v in ipairs(gameDropdownStates[dropdownNameStr]) do
                            selectedValues[v] = true
                        end
                    elseif setting.default and type(setting.default) == "table" then
                        for _, v in ipairs(setting.default) do
                            selectedValues[v] = true
                        end
                    end
                else
                    -- Check for saved single-select state
                    if gameDropdownStates[dropdownNameStr] ~= nil then
                        selectedValues = gameDropdownStates[dropdownNameStr]
                    else
                        selectedValues = setting.default or options[1] or ""
                    end
                end
                
                local function getDisplayText()
                    if isMultiple then
                        local selected = {}
                        for opt, _ in pairs(selectedValues) do
                            table.insert(selected, opt)
                        end
                        if #selected == 0 then return "None selected" end
                        if #selected == 1 then return selected[1] end
                        if #selected <= 2 then return table.concat(selected, ", ") end
                        return #selected .. " selected"
                    else
                        return tostring(selectedValues)
                    end
                end
                
                local dropBtn = create("TextButton", {
                    BackgroundColor3 = theme.bg,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, scaled(Config.settingHeight) - 4),
                    Position = UDim2.new(0, 0, 0, scaled(Config.settingHeight) + 4),
                    Text = getDisplayText() .. " v",
                    TextColor3 = theme.text,
                    Font = Enum.Font.Gotham,
                    TextSize = scaled(11),
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    Parent = row
                })
                makeRounded(dropBtn, 4)
                
                -- Call callback with saved value if it was loaded (delay slightly to ensure game is ready)
                local wasLoadedFromSave = gameDropdownStates[dropdownNameStr] ~= nil
                if wasLoadedFromSave and setting.callback then
                    task.delay(0.5, function()
                        if isMultiple then
                            local result = {}
                            for k, _ in pairs(selectedValues) do
                                table.insert(result, k)
                            end
                            task.spawn(setting.callback, result)
                        else
                            task.spawn(setting.callback, selectedValues)
                        end
                    end)
                end
                
                -- Call callback with saved value if it was loaded (delay slightly to ensure game is ready)
                local wasLoadedFromSave = gameDropdownStates[dropdownNameStr] ~= nil
                if wasLoadedFromSave and setting.callback then
                    task.delay(0.5, function()
                        if isMultiple then
                            local result = {}
                            for k, _ in pairs(selectedValues) do
                                table.insert(result, k)
                            end
                            task.spawn(setting.callback, result)
                        else
                            task.spawn(setting.callback, selectedValues)
                        end
                    end)
                end
                
                -- Use ScrollingFrame for dropdowns with many options
                local maxVisibleOptions = 6
                local needsScroll = #options > maxVisibleOptions
                
                local dropList = create(needsScroll and "ScrollingFrame" or "Frame", {
                    BackgroundColor3 = theme.bg,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 0),
                    Position = UDim2.new(0, 0, 0, scaled(Config.settingHeight) * 2 + 4),
                    ClipsDescendants = true,
                    Visible = false,
                    ZIndex = 100,
                    Parent = row
                })
                
                if needsScroll then
                    dropList.ScrollBarThickness = 6
                    dropList.ScrollBarImageColor3 = theme.accent
                    dropList.CanvasSize = UDim2.new(0, 0, 0, 0)
                    dropList.AutomaticCanvasSize = Enum.AutomaticSize.Y
                end
                
                makeRounded(dropList, 4)
                makeStroke(dropList, theme.stroke)
                
                create("UIListLayout", {
                    Parent = dropList,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 2)
                })

                local open = false
                local optionButtons = {}

                local function updateOptionVisuals()
                    for _, data in ipairs(optionButtons) do
                        if isMultiple then
                            local isSelected = selectedValues[data.opt] == true
                            data.check.Text = isSelected and "[X]" or "[ ]"
                            data.check.TextColor3 = isSelected and theme.accent or theme.textDim
                        end
                    end
                    dropBtn.Text = getDisplayText() .. (open and " ^" or " v")
                end
                
                local function buildOptions()
                    for _, child in ipairs(dropList:GetChildren()) do
                        if child:IsA("Frame") or child:IsA("TextButton") then child:Destroy() end
                    end
                    optionButtons = {}
                    
                    for _, opt in ipairs(options) do
                        if isMultiple then
                            -- Multi-select: show checkbox style
                            local optRow = create("Frame", {
                                BackgroundColor3 = theme.panel,
                                BorderSizePixel = 0,
                                Size = UDim2.new(1, 0, 0, 24),
                                ZIndex = 101,
                                Parent = dropList
                            })
                            makeRounded(optRow, 2)
                            trackHover(optRow, theme.panel, theme.hover)
                            
                            local check = create("TextLabel", {
                                BackgroundTransparency = 1,
                                Size = UDim2.fromOffset(28, 24),
                                Text = selectedValues[opt] and "[X]" or "[ ]",
                                TextColor3 = selectedValues[opt] and theme.accent or theme.textDim,
                                Font = Enum.Font.GothamBold,
                                TextSize = 10,
                                ZIndex = 102,
                                Parent = optRow
                            })
                            
                            local optLabel = create("TextLabel", {
                                BackgroundTransparency = 1,
                                Size = UDim2.new(1, -30, 1, 0),
                                Position = UDim2.fromOffset(28, 0),
                                Text = opt,
                                TextColor3 = theme.text,
                                Font = Enum.Font.Gotham,
                                TextSize = scaled(11),
                                TextXAlignment = Enum.TextXAlignment.Left,
                                ZIndex = 102,
                                Parent = optRow
                            })
                            
                            local clickBtn = create("TextButton", {
                                BackgroundTransparency = 1,
                                Size = UDim2.fromScale(1, 1),
                                Text = "",
                                ZIndex = 103,
                                Parent = optRow
                            })
                            
                            table.insert(optionButtons, { btn = optRow, check = check, opt = opt })
                            
                            clickBtn.MouseButton1Click:Connect(function()
                                selectedValues[opt] = not selectedValues[opt]
                                if not selectedValues[opt] then selectedValues[opt] = nil end
                                updateOptionVisuals()
                                -- Save dropdown state (multi-select)
                                local gameDropdownStates = getGameDropdownStates()
                                local result = {}
                                for k, _ in pairs(selectedValues) do
                                    table.insert(result, k)
                                end
                                gameDropdownStates[dropdownNameStr] = result
                                saveSettings()
                                if setting.callback then
                                    task.spawn(setting.callback, result)
                                end
                            end)
                        else
                            -- Single select
                            local optBtn = create("TextButton", {
                                BackgroundColor3 = theme.panel,
                                BorderSizePixel = 0,
                                Size = UDim2.new(1, 0, 0, 22),
                                Text = opt,
                                TextColor3 = theme.text,
                                Font = Enum.Font.Gotham,
                                TextSize = scaled(11),
                                ZIndex = 101,
                                Parent = dropList
                            })
                            
                            trackHover(optBtn, theme.panel, theme.hover)
                            table.insert(optionButtons, { btn = optBtn, opt = opt })
                            
                            optBtn.MouseButton1Click:Connect(function()
                                selectedValues = opt
                                dropBtn.Text = selectedValues .. " v"
                                open = false
                                dropList.Visible = false
                                row.Size = UDim2.new(1, 0, 0, scaled(Config.settingHeight) + 26)
                                -- Save dropdown state (single-select)
                                local gameDropdownStates = getGameDropdownStates()
                                gameDropdownStates[dropdownNameStr] = selectedValues
                                -- Ensure dropdownStates exists in SavedSettings before saving
                                if not SavedSettings.dropdownStates then
                                    SavedSettings.dropdownStates = {}
                                end
                                saveSettings()
                                print("[Dropdown Save] '" .. dropdownNameStr .. "' = '" .. tostring(selectedValues) .. "'")
                                if setting.callback then task.spawn(setting.callback, selectedValues) end
                            end)
                    end
                end
                end
                buildOptions()
                
                dropBtn.MouseButton1Click:Connect(function()
                    open = not open
                    updateOptionVisuals()
                    
                    if open then
                        -- Opening animation
                        local optionHeight = isMultiple and 26 or 24
                        local maxHeight = optionHeight * maxVisibleOptions
                        local listH = math.min(#options * optionHeight, maxHeight)
                        dropList.Visible = true
                        dropList.Size = UDim2.new(1, 0, 0, 0)
                        dropList.BackgroundTransparency = 1
                        
                        -- Animate dropdown opening
                        tween(dropList, { 
                            Size = UDim2.new(1, 0, 0, listH),
                            BackgroundTransparency = 0 
                        }, 0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
                        tween(row, { Size = UDim2.new(1, 0, 0, scaled(Config.settingHeight) + 26 + listH + 6) }, 0.15, Enum.EasingStyle.Quart)
                    else
                        -- Closing animation
                        tween(dropList, { 
                            Size = UDim2.new(1, 0, 0, 0),
                            BackgroundTransparency = 1 
                        }, 0.1, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
                        tween(row, { Size = UDim2.new(1, 0, 0, scaled(Config.settingHeight) + 26) }, 0.1, Enum.EasingStyle.Quart)
                        task.delay(0.1, function()
                            if not open then dropList.Visible = false end
                        end)
                    end
                end)
                
                -- Theme subscriber for dropdown options
                subscribeTheme(function(t)
                    dropBtn.BackgroundColor3 = t.bg
                    dropBtn.TextColor3 = t.text
                    dropList.BackgroundColor3 = t.bg
                    for _, data in ipairs(optionButtons) do
                        if data.btn then
                            updateHoverColors(data.btn, t.panel, t.hover)
                            if data.btn:FindFirstChild("TextLabel") then
                                data.btn.TextLabel.TextColor3 = t.text
                            elseif data.btn:IsA("TextButton") then
                                data.btn.TextColor3 = t.text
                            end
                        end
                        if data.check then
                            data.check.TextColor3 = selectedValues[data.opt] and t.accent or t.textDim
                        end
                    end
                end)
                
                if setting.tooltip then attachTooltip(row, setting.tooltip) end

                return {
                    _row = row, -- Expose row for search tracking
                    _dropBtn = dropBtn, -- Expose button for highlighting
                    Set = function(_, v)
                        if isMultiple and type(v) == "table" then
                            selectedValues = {}
                            for _, val in ipairs(v) do selectedValues[val] = true end
                        else
                            selectedValues = v
                        end
                        updateOptionVisuals()
                    end,
                    Get = function()
                        if isMultiple then
                            local result = {}
                            for k, _ in pairs(selectedValues) do table.insert(result, k) end
                            return result
                        end
                        return selectedValues
                    end,
                    SetOptions = function(_, newOpts) options = newOpts; buildOptions() end
                }
            end
        end
        
        --=====================================================================
        -- SHORTHAND METHODS
        --=====================================================================
        function panelObj:AddLabel(text, tooltip, formatOptions)
            formatOptions = formatOptions or {}
            return self:_addSetting(content, { 
                type = "label", 
                text = text, 
                tooltip = tooltip,
                bold = formatOptions.bold,
                fontSize = formatOptions.fontSize,
                color = formatOptions.color
            })
        end
        
        function panelObj:AddDivider()
            return self:_addSetting(content, { type = "divider" })
        end
        
        function panelObj:AddToggle(cfg)
            cfg.type = "toggle"
            return self:AddModule(cfg)
        end
        
        function panelObj:AddButton(cfg)
            cfg.type = "button"
            return self:AddModule(cfg)
        end
        
        function panelObj:AddDropdown(cfg)
            local control = self:_addSetting(content, {
                type = "dropdown",
                text = cfg.text or cfg.name,
                name = cfg.name, -- Also pass name separately for saving
                options = cfg.options,
                default = cfg.default,
                multiple = cfg.multiple, -- Enable multi-select with multiple = true
                callback = cfg.callback,
                tooltip = cfg.tooltip
            })
            -- Track for search (use returned row and dropBtn for proper highlighting)
            table.insert(allSearchItems, {
                name = cfg.text or cfg.name or "Dropdown",
                panel = name,
                itemType = "dropdown",
                instance = control._row,
                row = control._dropBtn or control._row -- Highlight the button
            })
            return control
        end
        
        function panelObj:AddSlider(cfg)
            local control = self:_addSetting(content, {
                type = "slider",
                text = cfg.text or cfg.name,
                min = cfg.min,
                max = cfg.max,
                step = cfg.step,
                default = cfg.default,
                rounding = cfg.rounding,
                suffix = cfg.suffix,
                callback = cfg.callback,
                tooltip = cfg.tooltip
            })
            -- Track for search (use returned row for proper highlighting)
            table.insert(allSearchItems, {
                name = cfg.text or cfg.name or "Slider",
                panel = name,
                itemType = "slider",
                instance = control._row,
                row = control._sliderBg or control._row
            })
            return control
        end
        
        function panelObj:AddInput(cfg)
            local control = self:_addSetting(content, {
                type = "input",
                text = cfg.text or cfg.name,
                default = cfg.default,
                placeholder = cfg.placeholder,
                clearOnFocus = cfg.clearOnFocus,
                callback = cfg.callback,
                tooltip = cfg.tooltip
            })
            -- Track for search (use returned row for proper highlighting)
            table.insert(allSearchItems, {
                name = cfg.text or cfg.name or "Input",
                panel = name,
                itemType = "input",
                instance = control._row,
                row = control._inputBox or control._row
            })
            return control
        end
        
        function panelObj:AddKeybind(cfg)
            local control = self:_addSetting(content, {
                type = "keybind",
                text = cfg.text or cfg.name,
                default = cfg.default,
                callback = cfg.callback,
                tooltip = cfg.tooltip
            })
            -- Track for search (use returned row for proper highlighting)
            table.insert(allSearchItems, {
                name = cfg.text or cfg.name or "Keybind",
                panel = name,
                itemType = "keybind",
                instance = control._row,
                row = control._keyBtn or control._row
            })
            return control
        end
        
        return panelObj
    end
    
    --=========================================================================
    -- CREATE DEFAULT SETTINGS PANEL
    --=========================================================================
    local settingsPanel = window:AddPanel("Settings", UDim2.new(1, -240, 0, 15))
    
    -- UI Scale control with +/- buttons
    do
        local scaleRow = create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, scaled(Config.settingHeight) + 4),
            Parent = settingsPanel.Content
        })
        
        local scaleLabel = create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(0.4, 0, 1, 0),
            Text = "UI Scale",
            TextColor3 = theme.text,
            Font = Enum.Font.Gotham,
            TextSize = scaled(12),
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = scaleRow
        })
        
        local minusBtn = create("TextButton", {
            BackgroundColor3 = theme.panelHeader,
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(28, 24),
            Position = UDim2.new(0.42, 0, 0.5, -12),
            Text = "-",
            TextColor3 = theme.text,
            Font = Enum.Font.GothamBold,
            TextSize = 16,
            Parent = scaleRow
        })
        makeRounded(minusBtn, 4)
        trackHover(minusBtn, theme.panelHeader, theme.hover)
        
        local scaleDisplay = create("TextLabel", {
            BackgroundColor3 = theme.bg,
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(50, 24),
            Position = UDim2.new(0.42, 32, 0.5, -12),
            Text = string.format("%.2fx", Config.uiScale),
            TextColor3 = theme.accent,
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            Parent = scaleRow
        })
        makeRounded(scaleDisplay, 4)
        
        local plusBtn = create("TextButton", {
            BackgroundColor3 = theme.panelHeader,
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(28, 24),
            Position = UDim2.new(0.42, 86, 0.5, -12),
            Text = "+",
            TextColor3 = theme.text,
            Font = Enum.Font.GothamBold,
            TextSize = 16,
            Parent = scaleRow
        })
        makeRounded(plusBtn, 4)
        trackHover(plusBtn, theme.panelHeader, theme.hover)
        
        local function updateScaleDisplay()
            scaleDisplay.Text = string.format("%.2fx", Config.uiScale)
        end
        
        minusBtn.MouseButton1Click:Connect(function()
            local newScale = math.max(0.8, Config.uiScale - 0.05)
            window:SetScale(newScale)
            updateScaleDisplay()
        end)
        
        plusBtn.MouseButton1Click:Connect(function()
            local newScale = math.min(1.3, Config.uiScale + 0.05)
            window:SetScale(newScale)
            updateScaleDisplay()
        end)
        
        attachTooltip(scaleRow, "Adjust UI size with +/- buttons (0.8x - 1.3x)")
        
        -- Theme subscriber
        subscribeTheme(function(t)
            scaleLabel.TextColor3 = t.text
            scaleDisplay.BackgroundColor3 = t.bg
            scaleDisplay.TextColor3 = t.accent
            updateHoverColors(minusBtn, t.panelHeader, t.hover)
            updateHoverColors(plusBtn, t.panelHeader, t.hover)
            minusBtn.TextColor3 = t.text
            plusBtn.TextColor3 = t.text
        end)
    end
    
    settingsPanel:AddDivider()
    
    -- UI Toggle Key
    settingsPanel:AddKeybind({
        text = "Toggle Key",
        default = toggleKey,
        tooltip = "Key to show/hide the UI",
        callback = function(kc)
            window:SetToggleKey(kc)
            window:Notify("Toggle key changed to " .. keycodeToString(kc), 2)
        end
    })
    
    -- FPS Cap
    settingsPanel:AddSlider({
        text = "FPS Cap",
        min = 10,
        max = 500,
        step = 10,
        default = SavedSettings.fpsCap or 60,
        suffix = " fps",
        tooltip = "Limit client FPS (requires executor support)",
        callback = function(v)
            SavedSettings.fpsCap = v
            saveSettings()
            local ok = applyFpsCap(v)
            if not ok then
                window:Notify("FPS cap not supported by your executor", 3)
            end
        end
    })
    
    settingsPanel:AddDivider()
    
    -- Notification Position
    settingsPanel:AddDropdown({
        text = "Notify Pos",
        options = { "TopRight", "TopLeft", "BottomRight", "BottomLeft" },
        default = notifyPosition,
        tooltip = "Where notifications appear",
        callback = function(v)
            window:SetNotifyPosition(v)
        end
    })
    
    settingsPanel:AddDivider()
    
    -- Theme Selection
    local themeNames = {}
    for name, _ in pairs(Themes) do
        table.insert(themeNames, name)
    end
    table.sort(themeNames)
    
    settingsPanel:AddDropdown({
        text = "Theme",
        options = themeNames,
        default = CurrentTheme.name,
        tooltip = "Change UI color theme and animations",
        callback = function(v)
            window:SetTheme(v)
        end
    })
    
    settingsPanel:AddDivider()
    
    -- ArrayList Position
    settingsPanel:AddDropdown({
        text = "ArrayList Pos",
        options = { "Right", "Left" },
        default = SavedSettings.arrayListPosition or "Right",
        tooltip = "Position of the active modules list",
        callback = function(v)
            window:SetArrayListPosition(v)
        end
    })
    
    settingsPanel:AddDivider()
    
    -- Theme Colored Text Toggle
    settingsPanel:_addSetting(settingsPanel.Content, {
        type = "toggle",
        text = "Theme Colored Text",
        default = SavedSettings.themeColoredText ~= false, -- Default to true
        tooltip = "Enable theme-colored text for toggles and buttons (disable for plain white)",
        callback = function(v)
            SavedSettings.themeColoredText = v
            saveSettings()
            
            -- Update all existing modules
            for _, panel in ipairs(window._panels) do
                if panel._modules then
                    for _, module in ipairs(panel._modules) do
                        if module._moduleName then
                            local theme = CurrentTheme
                            if SavedSettings.themeColoredText then
                                if module._isButton then
                                    module._moduleName.TextColor3 = theme.accent
                                else
                                    local isEnabled = module:Get()
                                    module._moduleName.TextColor3 = isEnabled and theme.accent or theme.text
                                end
                            else
                                module._moduleName.TextColor3 = theme.text
                            end
                        end
                    end
                end
            end
            
            window:Notify("Theme colored text " .. (v and "enabled" or "disabled"), 2)
        end
    })
    
    settingsPanel:AddDivider()
    
    -- Debug Mode Toggle
    settingsPanel:_addSetting(settingsPanel.Content, {
        type = "toggle",
        text = "Debug Mode",
        default = Config.debugMode,
        tooltip = "Show debug information for troubleshooting",
        callback = function(v)
            window:SetDebugMode(v)
            window:Notify("Debug mode " .. (v and "enabled" or "disabled"), 2)
        end
    })
    
    settingsPanel:AddDivider()
    
    -- Show Changelog button
    settingsPanel:AddButton({
        name = "View Changelog",
        type = "button",
        tooltip = "View update history",
        notify = false,
        callback = function()
            window:ShowChangelog()
        end
    })
    
    settingsPanel:AddDivider()
    
    -- Destroy UI button
    settingsPanel:AddButton({
        name = "Destroy UI",
        type = "button",
        tooltip = "Completely removes the UI from the game",
        notify = false,
        callback = function()
            window:Notify("UI will be destroyed in 1 second...", 1)
            task.delay(1, function()
                window:Destroy()
            end)
        end
    })
    
    -- Apply saved ArrayList position
    if SavedSettings.arrayListPosition then
        window:SetArrayListPosition(SavedSettings.arrayListPosition)
    end
    
    --=========================================================================
    -- MENU ENTRANCE ANIMATION (after splash)
    --=========================================================================
    if showSplash then
        -- COMPLETELY hide menu until splash finishes
        panelContainer.Visible = false
        if searchBarFrame then searchBarFrame.Visible = false end
        
        -- Show menu AFTER splash disappears
        task.defer(function()
            -- Wait for splash to fully complete
            task.wait(1.5)
            
            -- Now show the container
            panelContainer.Visible = true
            if searchBarFrame and showSearchBar then searchBarFrame.Visible = true end
        end)
    end
    
    -- Welcome notification (after splash)
    task.defer(function()
        task.wait(showSplash and 2 or 0)
        local saveStatus = canSaveFiles() and "Settings will be saved" or "Settings won't save (no file access)"
        window:Notify("EclipseUI v2.3 loaded - " .. saveStatus, 4)
    end)

    return window
end

--=============================================================================
-- RETURN MODULE
--=============================================================================
return EclipseUI
