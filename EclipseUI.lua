-- EclipseUI v2.0 — Minecraft Hack Client Style (Wurst-inspired)
-- Pure Lua 5.1 (no Luau type annotations)
-- Mobile-friendly with touch support

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
local Player = Players.LocalPlayer

--=============================================================================
-- CONFIGURATION
--=============================================================================
local Config = {
    panelWidth = 180,
    panelMinWidth = 140,
    panelMaxWidth = 280,
    headerHeight = 28,
    moduleHeight = 24,
    settingHeight = 22,
    padding = 6,
    cornerRadius = 4,
    animDuration = 0.15,
    notifyDuration = 3,
    isMobile = UIS.TouchEnabled,
}

--=============================================================================
-- THEMES (with animation styles)
--=============================================================================
local Themes = {
    ["Wurst"] = {
        name = "Wurst",
        bg = Color3.fromRGB(20, 20, 20),
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
        animStyle = "Fade", -- Fade, Slide, Scale
    },
    ["Impact"] = {
        name = "Impact",
        bg = Color3.fromRGB(15, 15, 20),
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

local CurrentTheme = Themes["Wurst"]

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

local function lerp(a, b, t)
    return a + (b - a) * t
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

-- Animate based on theme style
local function animateIn(obj, style)
    style = style or CurrentTheme.animStyle
    if style == "Fade" then
        obj.BackgroundTransparency = 1
        tween(obj, { BackgroundTransparency = 0 }, 0.2)
    elseif style == "Slide" then
        local orig = obj.Position
        obj.Position = orig - UDim2.fromOffset(0, 20)
        tween(obj, { Position = orig }, 0.25, Enum.EasingStyle.Back)
    elseif style == "Scale" then
        obj.Size = UDim2.fromScale(0.8, 0.8)
        obj.AnchorPoint = Vector2.new(0.5, 0.5)
        tween(obj, { Size = obj.Size }, 0.2, Enum.EasingStyle.Back)
    end
end

local function animateOut(obj, style, callback)
    style = style or CurrentTheme.animStyle
    local dur = 0.15
    if style == "Fade" then
        tween(obj, { BackgroundTransparency = 1 }, dur)
    elseif style == "Slide" then
        tween(obj, { Position = obj.Position + UDim2.fromOffset(0, -20) }, dur)
    elseif style == "Scale" then
        tween(obj, { Size = UDim2.fromScale(0.8, 0.8) }, dur)
    end
    if callback then
        task.delay(dur, callback)
    end
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
-- MAIN WINDOW CREATION
--=============================================================================
function EclipseUI:CreateWindow(cfg)
    cfg = cfg or {}
    
    -- Apply theme
    if cfg.Theme and Themes[cfg.Theme] then
        CurrentTheme = Themes[cfg.Theme]
    end
    
    local theme = CurrentTheme
    local toggleKey = cfg.ToggleKey or Enum.KeyCode.RightShift
    local notifyPosition = cfg.NotifyPosition or "TopRight" -- TopRight, TopLeft, BottomRight, BottomLeft
    
    -- Main ScreenGui
    local gui = create("ScreenGui", {
        Name = "EclipseUI_v2",
        IgnoreGuiInset = true,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = CoreGui
    })
    
    -- Container for all panels
    local panelContainer = create("Frame", {
        Name = "PanelContainer",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Parent = gui
    })
    
    -- Notification container
    local notifContainer = create("Frame", {
        Name = "NotificationContainer",
        Size = UDim2.fromOffset(280, 400),
        BackgroundTransparency = 1,
        Parent = gui
    })
    
    local function updateNotifPosition()
        if notifyPosition == "TopRight" then
            notifContainer.AnchorPoint = Vector2.new(1, 0)
            notifContainer.Position = UDim2.new(1, -10, 0, 10)
        elseif notifyPosition == "TopLeft" then
            notifContainer.AnchorPoint = Vector2.new(0, 0)
            notifContainer.Position = UDim2.new(0, 10, 0, 10)
        elseif notifyPosition == "BottomRight" then
            notifContainer.AnchorPoint = Vector2.new(1, 1)
            notifContainer.Position = UDim2.new(1, -10, 1, -10)
        elseif notifyPosition == "BottomLeft" then
            notifContainer.AnchorPoint = Vector2.new(0, 1)
            notifContainer.Position = UDim2.new(0, 10, 1, -10)
        end
    end
    updateNotifPosition()
    
    create("UIListLayout", {
        Parent = notifContainer,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
        VerticalAlignment = notifyPosition:find("Bottom") and Enum.VerticalAlignment.Bottom or Enum.VerticalAlignment.Top,
        HorizontalAlignment = notifyPosition:find("Left") and Enum.HorizontalAlignment.Left or Enum.HorizontalAlignment.Right
    })
    
    -- Tooltip
    local tooltip = create("Frame", {
        Name = "Tooltip",
        Visible = false,
        BackgroundColor3 = theme.panel,
        BorderSizePixel = 0,
        ZIndex = 1000,
        Parent = gui
    })
    makeRounded(tooltip, 4)
    makeStroke(tooltip, theme.accent, 1)
    create("UIPadding", { Parent = tooltip, PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) })
    
    local tooltipText = create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        TextColor3 = theme.text,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = tooltip
    })
    
    local tooltipTarget = nil
    local tooltipDelay = 0.4
    
    local function showTooltip(text, target)
        if not text or text == "" then return end
        tooltipTarget = target
        tooltipText.Text = text
        local sz = getTextSize(text, 12, Enum.Font.Gotham)
        tooltip.Size = UDim2.fromOffset(sz.X + 16, sz.Y + 8)
        
        task.delay(tooltipDelay, function()
            if tooltipTarget == target then
                local mouse = UIS:GetMouseLocation()
                local screen = gui.AbsoluteSize
                local x = math.clamp(mouse.X + 10, 0, screen.X - tooltip.AbsoluteSize.X)
                local y = math.clamp(mouse.Y + 15, 0, screen.Y - tooltip.AbsoluteSize.Y)
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
            local x = math.clamp(mouse.X + 10, 0, screen.X - tooltip.AbsoluteSize.X)
            local y = math.clamp(mouse.Y + 15, 0, screen.Y - tooltip.AbsoluteSize.Y)
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
        Position = UDim2.new(0.5, 0, 0, 10),
        Size = UDim2.fromOffset(200, 32),
        ZIndex = 500,
        Parent = gui
    })
    makeRounded(hint, 6)
    makeStroke(hint, theme.accent, 1)
    
    local hintText = create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Text = "Press " .. keycodeToString(toggleKey) .. " to open",
        TextColor3 = theme.text,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        Parent = hint
    })
    
    -- Mobile open button
    local mobileOpenBtn = create("TextButton", {
        Name = "MobileOpen",
        Visible = false,
        BackgroundColor3 = theme.accent,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(120, 36),
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 50),
        Text = "Open Menu",
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        ZIndex = 500,
        Parent = gui
    })
    makeRounded(mobileOpenBtn, 8)
    
    -- UI visibility state
    local uiVisible = true
    
    local function updateHintText()
        hintText.Text = "Press " .. keycodeToString(toggleKey) .. " to open"
        local sz = getTextSize(hintText.Text, 13, Enum.Font.GothamBold)
        hint.Size = UDim2.fromOffset(sz.X + 24, 32)
    end
    
    local function setUIVisible(visible)
        uiVisible = visible
        panelContainer.Visible = visible
        hint.Visible = not visible
        mobileOpenBtn.Visible = not visible and Config.isMobile
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
    }
    setmetatable(window, { __index = EclipseUI })
    
    --=========================================================================
    -- NOTIFICATION SYSTEM
    --=========================================================================
    function window:Notify(text, duration, icon)
        duration = duration or Config.notifyDuration
        
        local notif = create("Frame", {
            BackgroundColor3 = theme.panel,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Parent = notifContainer
        })
        makeRounded(notif, 6)
        
        local accentBar = create("Frame", {
            BackgroundColor3 = theme.accent,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 3, 1, 0),
            Parent = notif
        })
        
        create("UIPadding", { Parent = notif, PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 8) })
        
        local notifLabel = create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -20, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Position = UDim2.fromOffset(0, 0),
            Text = tostring(text),
            TextColor3 = theme.text,
            Font = Enum.Font.Gotham,
            TextSize = 13,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = notif
        })
        
        -- Close button
        local closeBtn = create("TextButton", {
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(16, 16),
            Position = UDim2.new(1, -16, 0, 0),
            Text = "×",
            TextColor3 = theme.textDim,
            Font = Enum.Font.GothamBold,
            TextSize = 16,
            Parent = notif
        })
        
        -- Animate in
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
        
        closeBtn.MouseButton1Click:Connect(dismiss)
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
            window:Notify("Theme changed to " .. themeName, 2)
        end
    end
    
    --=========================================================================
    -- SET TOGGLE KEY
    --=========================================================================
    function window:SetToggleKey(keyCode)
        toggleKey = keyCode
        window._toggleKey = keyCode
        updateHintText()
    end
    
    --=========================================================================
    -- DESTROY
    --=========================================================================
    function window:Destroy()
        if toggleConn then toggleConn:Disconnect() end
        if gui then gui:Destroy() end
    end
    
    --=========================================================================
    -- ADD PANEL (Section/Category)
    --=========================================================================
    function window:AddPanel(name, position)
        local theme = CurrentTheme
        local panelWidth = Config.panelWidth
        
        -- Adjust for mobile
        if Config.isMobile then
            panelWidth = math.min(panelWidth, gui.AbsoluteSize.X * 0.45)
        end
        
        position = position or UDim2.fromOffset(10 + (#window._panels * (panelWidth + 10)), 10)
        
        local panel = create("Frame", {
            Name = "Panel_" .. name,
            BackgroundColor3 = theme.panel,
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(panelWidth, Config.headerHeight),
            Position = position,
            AutomaticSize = Enum.AutomaticSize.Y,
            Parent = panelContainer
        })
        makeRounded(panel, Config.cornerRadius)
        makeStroke(panel, theme.stroke)
        
        -- Header
        local header = create("Frame", {
            Name = "Header",
            BackgroundColor3 = theme.panelHeader,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, Config.headerHeight),
            Parent = panel
        })
        makeRounded(header, Config.cornerRadius)
        
        local headerTitle = create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -30, 1, 0),
            Position = UDim2.fromOffset(8, 0),
            Text = name,
            TextColor3 = theme.accent,
            Font = Enum.Font.GothamBold,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = header
        })
        
        -- Collapse arrow
        local collapseBtn = create("TextButton", {
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(20, 20),
            Position = UDim2.new(1, -24, 0.5, -10),
            Text = "▼",
            TextColor3 = theme.textDim,
            Font = Enum.Font.GothamBold,
            TextSize = 10,
            Parent = header
        })
        
        -- Content container
        local content = create("Frame", {
            Name = "Content",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            Position = UDim2.fromOffset(0, Config.headerHeight),
            AutomaticSize = Enum.AutomaticSize.Y,
            ClipsDescendants = true,
            Parent = panel
        })
        
        create("UIListLayout", {
            Parent = content,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 2)
        })
        
        create("UIPadding", {
            Parent = content,
            PaddingTop = UDim.new(0, 4),
            PaddingBottom = UDim.new(0, 4),
            PaddingLeft = UDim.new(0, 4),
            PaddingRight = UDim.new(0, 4)
        })
        
        -- Collapse state
        local collapsed = false
        
        collapseBtn.MouseButton1Click:Connect(function()
            collapsed = not collapsed
            collapseBtn.Text = collapsed and "▶" or "▼"
            content.Visible = not collapsed
            
            if collapsed then
                panel.AutomaticSize = Enum.AutomaticSize.None
                tween(panel, { Size = UDim2.fromOffset(panelWidth, Config.headerHeight) }, 0.15)
            else
                task.delay(0.15, function()
                    panel.AutomaticSize = Enum.AutomaticSize.Y
                end)
            end
        end)
        
        -- Dragging
        local dragging, dragStart, startPos = false, Vector2.new(), panel.Position
        
        local function beginDrag(input)
            dragging = true
            dragStart = input.Position
            startPos = panel.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
        
        header.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                beginDrag(input)
            end
        end)
        
        UIS.InputChanged:Connect(function(input)
            if not dragging then return end
            if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
            local delta = input.Position - dragStart
            panel.Position = UDim2.new(
                startPos.X.Scale, math.floor(startPos.X.Offset + delta.X + 0.5),
                startPos.Y.Scale, math.floor(startPos.Y.Offset + delta.Y + 0.5)
            )
        end)
        
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
                Size = UDim2.new(1, 0, 0, Config.moduleHeight),
                AutomaticSize = Enum.AutomaticSize.Y,
                Parent = content
            })
            
            local moduleRow = create("Frame", {
                Name = "Row",
                BackgroundColor3 = theme.panel,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, Config.moduleHeight),
                Parent = moduleHolder
            })
            makeRounded(moduleRow, 3)
            
            -- Module name/toggle
            local moduleBtn = create("TextButton", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, hasSettings and -20 or 0, 1, 0),
                Text = "",
                Parent = moduleRow
            })
            
            local moduleName = create("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -8, 1, 0),
                Position = UDim2.fromOffset(8, 0),
                Text = cfg.name or "Module",
                TextColor3 = cfg.default and theme.enabled or theme.disabled,
                Font = Enum.Font.Gotham,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = moduleBtn
            })
            
            -- Expand arrow (only if has settings)
            local expandBtn
            local expanded = false
            
            if hasSettings then
                expandBtn = create("TextButton", {
                    BackgroundTransparency = 1,
                    Size = UDim2.fromOffset(20, Config.moduleHeight),
                    Position = UDim2.new(1, -20, 0, 0),
                    Text = "›",
                    TextColor3 = theme.textDim,
                    Font = Enum.Font.GothamBold,
                    TextSize = 14,
                    Parent = moduleRow
                })
            end
            
            -- Settings container
            local settingsContainer
            if hasSettings then
                settingsContainer = create("Frame", {
                    Name = "Settings",
                    BackgroundColor3 = theme.bg,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 0),
                    Position = UDim2.fromOffset(0, Config.moduleHeight),
                    ClipsDescendants = true,
                    Visible = false,
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Parent = moduleHolder
                })
                makeRounded(settingsContainer, 3)
                
                create("UIListLayout", {
                    Parent = settingsContainer,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 2)
                })
                
                create("UIPadding", {
                    Parent = settingsContainer,
                    PaddingTop = UDim.new(0, 4),
                    PaddingBottom = UDim.new(0, 4),
                    PaddingLeft = UDim.new(0, 8),
                    PaddingRight = UDim.new(0, 8)
                })
            end
            
            -- Toggle state
            local enabled = cfg.default or false
            
            local function updateState()
                moduleName.TextColor3 = enabled and theme.enabled or theme.disabled
            end
            
            -- Hover effect
            moduleRow.MouseEnter:Connect(function()
                tween(moduleRow, { BackgroundColor3 = theme.hover }, 0.1)
            end)
            moduleRow.MouseLeave:Connect(function()
                tween(moduleRow, { BackgroundColor3 = theme.panel }, 0.1)
            end)
            
            -- Click to toggle (if toggle type)
            if cfg.type == "toggle" or cfg.type == nil then
                moduleBtn.MouseButton1Click:Connect(function()
                    enabled = not enabled
                    updateState()
                    if cfg.callback then
                        task.spawn(cfg.callback, enabled)
                    end
                    if cfg.notify then
                        window:Notify(cfg.name .. (enabled and " enabled" or " disabled"), 2)
                    end
                end)
            elseif cfg.type == "button" then
                moduleBtn.MouseButton1Click:Connect(function()
                    if cfg.callback then
                        task.spawn(cfg.callback)
                    end
                    if cfg.notify then
                        window:Notify(cfg.notifyText or (cfg.name .. " activated"), 2)
                    end
                end)
            end
            
            -- Tooltip
            if cfg.tooltip then
                attachTooltip(moduleRow, cfg.tooltip)
            end
            
            -- Expand settings
            if hasSettings and expandBtn then
                expandBtn.MouseButton1Click:Connect(function()
                    expanded = not expanded
                    expandBtn.Text = expanded and "ˇ" or "›"
                    settingsContainer.Visible = expanded
                    
                    if expanded then
                        moduleHolder.AutomaticSize = Enum.AutomaticSize.Y
                    else
                        moduleHolder.AutomaticSize = Enum.AutomaticSize.None
                        moduleHolder.Size = UDim2.new(1, 0, 0, Config.moduleHeight)
                    end
                end)
            end
            
            -- Theme subscriber
            subscribeTheme(function(t)
                moduleRow.BackgroundColor3 = t.panel
                updateState()
                if expandBtn then expandBtn.TextColor3 = t.textDim end
                if settingsContainer then settingsContainer.BackgroundColor3 = t.bg end
            end)
            
            --=================================================================
            -- MODULE CONTROLS API
            --=================================================================
            local moduleObj = {
                Instance = moduleHolder,
                Row = moduleRow,
                SettingsContainer = settingsContainer,
                _controls = {},
            }
            
            function moduleObj:Set(val)
                enabled = val
                updateState()
            end
            
            function moduleObj:Get()
                return enabled
            end
            
            -- Build settings if provided
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
                local label = create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, Config.settingHeight),
                    Text = setting.text or "",
                    TextColor3 = theme.textDim,
                    Font = Enum.Font.Gotham,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextWrapped = true,
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Parent = container
                })
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
                    Size = UDim2.new(1, 0, 0, Config.settingHeight),
                    Parent = container
                })
                
                local label = create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -30, 1, 0),
                    Text = setting.text or "Toggle",
                    TextColor3 = theme.text,
                    Font = Enum.Font.Gotham,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = row
                })
                
                local toggleBtn = create("TextButton", {
                    BackgroundColor3 = setting.default and theme.enabled or theme.disabled,
                    BorderSizePixel = 0,
                    Size = UDim2.fromOffset(24, 12),
                    Position = UDim2.new(1, -24, 0.5, -6),
                    Text = "",
                    Parent = row
                })
                makeRounded(toggleBtn, 6)
                
                local knob = create("Frame", {
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    BorderSizePixel = 0,
                    Size = UDim2.fromOffset(10, 10),
                    Position = setting.default and UDim2.fromOffset(13, 1) or UDim2.fromOffset(1, 1),
                    Parent = toggleBtn
                })
                makeRounded(knob, 5)
                
                local state = setting.default or false
                
                toggleBtn.MouseButton1Click:Connect(function()
                    state = not state
                    tween(toggleBtn, { BackgroundColor3 = state and theme.enabled or theme.disabled }, 0.1)
                    tween(knob, { Position = state and UDim2.fromOffset(13, 1) or UDim2.fromOffset(1, 1) }, 0.1)
                    if setting.callback then task.spawn(setting.callback, state) end
                end)
                
                if setting.tooltip then attachTooltip(row, setting.tooltip) end
                
                return {
                    Set = function(_, v)
                        state = v
                        toggleBtn.BackgroundColor3 = state and theme.enabled or theme.disabled
                        knob.Position = state and UDim2.fromOffset(13, 1) or UDim2.fromOffset(1, 1)
                    end,
                    Get = function() return state end
                }
                
            elseif settingType == "slider" then
                local row = create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, Config.settingHeight + 12),
                    Parent = container
                })
                
                local label = create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0.6, 0, 0, 14),
                    Text = setting.text or "Slider",
                    TextColor3 = theme.text,
                    Font = Enum.Font.Gotham,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = row
                })
                
                local valueLabel = create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0.4, 0, 0, 14),
                    Position = UDim2.new(0.6, 0, 0, 0),
                    Text = tostring(setting.default or setting.min or 0) .. (setting.suffix or ""),
                    TextColor3 = theme.accent,
                    Font = Enum.Font.GothamBold,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    Parent = row
                })
                
                local sliderBg = create("Frame", {
                    BackgroundColor3 = theme.bg,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 8),
                    Position = UDim2.fromOffset(0, 18),
                    Parent = row
                })
                makeRounded(sliderBg, 4)
                
                local sliderFill = create("Frame", {
                    BackgroundColor3 = theme.accent,
                    BorderSizePixel = 0,
                    Size = UDim2.new(0, 0, 1, 0),
                    Parent = sliderBg
                })
                makeRounded(sliderFill, 4)
                
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
                
                UIS.InputChanged:Connect(function(input)
                    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        updateFromInput(input)
                    end
                end)
                
                UIS.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = false
                    end
                end)
                
                if setting.tooltip then attachTooltip(row, setting.tooltip) end
                
                return {
                    Set = function(_, v) updateSlider(v); if setting.callback then task.spawn(setting.callback, value) end end,
                    Get = function() return value end
                }
                
            elseif settingType == "button" then
                local btn = create("TextButton", {
                    BackgroundColor3 = theme.panelHeader,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, Config.settingHeight),
                    Text = setting.text or "Button",
                    TextColor3 = theme.text,
                    Font = Enum.Font.GothamBold,
                    TextSize = 11,
                    Parent = container
                })
                makeRounded(btn, 3)
                
                btn.MouseEnter:Connect(function() tween(btn, { BackgroundColor3 = theme.hover }, 0.1) end)
                btn.MouseLeave:Connect(function() tween(btn, { BackgroundColor3 = theme.panelHeader }, 0.1) end)
                
                btn.MouseButton1Click:Connect(function()
                    if setting.callback then task.spawn(setting.callback) end
                    if setting.notify then window:Notify(setting.notifyText or (setting.text .. " clicked"), 2) end
                end)
                
                if setting.tooltip then attachTooltip(btn, setting.tooltip) end
                return btn
                
            elseif settingType == "input" then
                local row = create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, Config.settingHeight + 4),
                    Parent = container
                })
                
                local label = create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0.4, 0, 1, 0),
                    Text = setting.text or "Input",
                    TextColor3 = theme.text,
                    Font = Enum.Font.Gotham,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = row
                })
                
                local inputBox = create("TextBox", {
                    BackgroundColor3 = theme.bg,
                    BorderSizePixel = 0,
                    Size = UDim2.new(0.58, 0, 0, 18),
                    Position = UDim2.new(0.42, 0, 0.5, -9),
                    Text = setting.default or "",
                    PlaceholderText = setting.placeholder or "",
                    TextColor3 = theme.text,
                    PlaceholderColor3 = theme.textDim,
                    Font = Enum.Font.Gotham,
                    TextSize = 11,
                    ClearTextOnFocus = setting.clearOnFocus or false,
                    Parent = row
                })
                makeRounded(inputBox, 3)
                create("UIPadding", { Parent = inputBox, PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) })
                
                inputBox.FocusLost:Connect(function(enter)
                    if setting.callback then task.spawn(setting.callback, inputBox.Text) end
                end)
                
                if setting.tooltip then attachTooltip(row, setting.tooltip) end
                
                return {
                    Set = function(_, t) inputBox.Text = tostring(t or "") end,
                    Get = function() return inputBox.Text end
                }
                
            elseif settingType == "keybind" then
                local row = create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, Config.settingHeight),
                    Parent = container
                })
                
                local label = create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0.5, 0, 1, 0),
                    Text = setting.text or "Keybind",
                    TextColor3 = theme.text,
                    Font = Enum.Font.Gotham,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = row
                })
                
                local keyBtn = create("TextButton", {
                    BackgroundColor3 = theme.bg,
                    BorderSizePixel = 0,
                    Size = UDim2.new(0.48, 0, 0, 16),
                    Position = UDim2.new(0.52, 0, 0.5, -8),
                    Text = keycodeToString(setting.default or Enum.KeyCode.Unknown),
                    TextColor3 = theme.accent,
                    Font = Enum.Font.GothamBold,
                    TextSize = 10,
                    Parent = row
                })
                makeRounded(keyBtn, 3)
                
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
                    Set = function(_, kc) currentKey = kc; keyBtn.Text = keycodeToString(kc) end,
                    Get = function() return currentKey end
                }
                
            elseif settingType == "dropdown" then
                local row = create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, Config.settingHeight),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Parent = container
                })
                
                local label = create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0.4, 0, 0, Config.settingHeight),
                    Text = setting.text or "Dropdown",
                    TextColor3 = theme.text,
                    Font = Enum.Font.Gotham,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = row
                })
                
                local dropBtn = create("TextButton", {
                    BackgroundColor3 = theme.bg,
                    BorderSizePixel = 0,
                    Size = UDim2.new(0.58, 0, 0, Config.settingHeight - 4),
                    Position = UDim2.new(0.42, 0, 0, 2),
                    Text = (setting.default or setting.options[1] or "Select") .. " ▼",
                    TextColor3 = theme.text,
                    Font = Enum.Font.Gotham,
                    TextSize = 10,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    Parent = row
                })
                makeRounded(dropBtn, 3)
                
                local dropList = create("Frame", {
                    BackgroundColor3 = theme.bg,
                    BorderSizePixel = 0,
                    Size = UDim2.new(0.58, 0, 0, 0),
                    Position = UDim2.new(0.42, 0, 0, Config.settingHeight),
                    ClipsDescendants = true,
                    Visible = false,
                    ZIndex = 100,
                    Parent = row
                })
                makeRounded(dropList, 3)
                makeStroke(dropList, theme.stroke)
                
                create("UIListLayout", {
                    Parent = dropList,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 1)
                })
                
                local options = setting.options or {}
                local value = setting.default or options[1] or ""
                local open = false
                
                local function buildOptions()
                    for _, child in ipairs(dropList:GetChildren()) do
                        if child:IsA("TextButton") then child:Destroy() end
                    end
                    
                    for _, opt in ipairs(options) do
                        local optBtn = create("TextButton", {
                            BackgroundColor3 = theme.panel,
                            BorderSizePixel = 0,
                            Size = UDim2.new(1, 0, 0, 18),
                            Text = opt,
                            TextColor3 = theme.text,
                            Font = Enum.Font.Gotham,
                            TextSize = 10,
                            ZIndex = 101,
                            Parent = dropList
                        })
                        
                        optBtn.MouseEnter:Connect(function() optBtn.BackgroundColor3 = theme.hover end)
                        optBtn.MouseLeave:Connect(function() optBtn.BackgroundColor3 = theme.panel end)
                        
                        optBtn.MouseButton1Click:Connect(function()
                            value = opt
                            dropBtn.Text = value .. " ▼"
                            open = false
                            dropList.Visible = false
                            row.Size = UDim2.new(1, 0, 0, Config.settingHeight)
                            if setting.callback then task.spawn(setting.callback, value) end
                        end)
                    end
                end
                buildOptions()
                
                dropBtn.MouseButton1Click:Connect(function()
                    open = not open
                    dropList.Visible = open
                    dropBtn.Text = value .. (open and " ▲" or " ▼")
                    
                    if open then
                        local listH = math.min(#options * 19, 100)
                        dropList.Size = UDim2.new(0.58, 0, 0, listH)
                        row.Size = UDim2.new(1, 0, 0, Config.settingHeight + listH + 4)
                    else
                        row.Size = UDim2.new(1, 0, 0, Config.settingHeight)
                    end
                end)
                
                if setting.tooltip then attachTooltip(row, setting.tooltip) end
                
                return {
                    Set = function(_, v) value = v; dropBtn.Text = v .. " ▼" end,
                    Get = function() return value end,
                    SetOptions = function(_, newOpts) options = newOpts; buildOptions() end
                }
            end
        end
        
        --=====================================================================
        -- SHORTHAND METHODS (add controls directly to panel)
        --=====================================================================
        function panelObj:AddLabel(text, tooltip)
            return self:_addSetting(content, { type = "label", text = text, tooltip = tooltip })
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
        
        function panelObj:AddSlider(cfg)
            return self:_addSetting(content, {
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
        end
        
        function panelObj:AddInput(cfg)
            return self:_addSetting(content, {
                type = "input",
                text = cfg.text or cfg.name,
                default = cfg.default,
                placeholder = cfg.placeholder,
                clearOnFocus = cfg.clearOnFocus,
                callback = cfg.callback,
                tooltip = cfg.tooltip
            })
        end
        
        function panelObj:AddKeybind(cfg)
            return self:_addSetting(content, {
                type = "keybind",
                text = cfg.text or cfg.name,
                default = cfg.default,
                callback = cfg.callback,
                tooltip = cfg.tooltip
            })
        end
        
        function panelObj:AddDropdown(cfg)
            return self:_addSetting(content, {
                type = "dropdown",
                text = cfg.text or cfg.name,
                options = cfg.options,
                default = cfg.default,
                callback = cfg.callback,
                tooltip = cfg.tooltip
            })
        end
        
        return panelObj
    end
    
    --=========================================================================
    -- CREATE DEFAULT SETTINGS PANEL
    --=========================================================================
    local settingsPanel = window:AddPanel("⚙ Settings", UDim2.new(1, -200, 0, 10))
    
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
        default = 60,
        suffix = " fps",
        tooltip = "Limit client FPS (requires executor support)",
        callback = function(v)
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
    
    -- Welcome notification
    task.defer(function()
        window:Notify("EclipseUI v2.0 loaded • Press " .. keycodeToString(toggleKey) .. " to toggle", 4)
    end)
    
    return window
end

--=============================================================================
-- RETURN MODULE
--=============================================================================
return EclipseUI
