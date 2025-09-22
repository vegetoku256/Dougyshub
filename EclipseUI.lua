--!strict
-- EclipseUI.lua — v9.1-scroll (mobile-friendly)
-- Changes:
--  • Responsive size: auto smaller on touch (cfg.Responsive ~= false; cfg.MobileSize to override)
--  • Touch "Open Menu" button below the reopen hint (visible only when hidden + on touch)
--  • Touch-enabled dragging (title bar & banner)

local EclipseUI = {}
EclipseUI.__index = EclipseUI

-- ========= Services =========
local UISg = game:GetService("UserInputService")
local TextService = game:GetService("TextService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- ========= Utils =========
local function create(className, props, children)
    local inst = Instance.new(className)
    if props then for k,v in pairs(props) do (inst :: any)[k] = v end end
    if children then for _,child in ipairs(children) do if child then child.Parent = inst end end end
    return inst
end
local function makeRounded(obj, r) create("UICorner", { CornerRadius = UDim.new(0, r), Parent = obj }) end
local function tweenSizeSafe(obj: GuiObject, newSize: UDim2, ed, es, dur)
    if obj and obj.Parent and obj:IsDescendantOf(game) then
        obj:TweenSize(newSize, ed or Enum.EasingDirection.Out, es or Enum.EasingStyle.Quad, dur or 0.2, true)
    end
end
local function keycodeToString(kc: Enum.KeyCode): string
    return (tostring(kc):match("([^%.]+)$")) or tostring(kc)
end

-- ========= Accent Pub/Sub =========
local AccentSubscribers : { (newColor: Color3) -> () } = {}
local function _accent_subscribe(fn)
    table.insert(AccentSubscribers, fn)
    return fn
end
local function _accent_publish(c: Color3)
    for _,fn in ipairs(AccentSubscribers) do pcall(fn, c) end
end

-- ========= Robust FPS Cap =========
local function applyFpsCap(v: number)
    v = math.clamp(tonumber(v) or 60, 10, 240)
    local tried = {}
    local function try(fn, label)
        if typeof(fn) == "function" then table.insert(tried, label); local ok = pcall(fn, v); if ok then return true end end
        return false
    end
    local names = { "setfpscap", "set_fps_cap", "fpscap", "setfps" }
    for _, name in ipairs(names) do if try(rawget(_G, name), name) or try(_G[name], name) then return true end end
    local envs = { (getgenv and getgenv()) or nil, (getfenv and getfenv()) or nil, _G, (getrenv and getrenv()) or nil, _ENV }
    for _, env in ipairs(envs) do if typeof(env)=="table" then for _,n in ipairs(names) do if try(rawget(env,n),"env."..n) then return true end end end end
    if syn and typeof(syn.set_fps_cap)=="function" and try(syn.set_fps_cap,"syn.set_fps_cap") then return true end
    if typeof(setfflag)=="function" then local ok=pcall(function() setfflag("DFIntTaskSchedulerTargetFps", tostring(v)) end); if ok then return true end end
    warn("[EclipseUI] No FPS cap API found. Tried: "..table.concat(tried, ", "))
    return false
end

-- ========= Theme =========
local DefaultTheme = {
    bg = Color3.fromRGB(16,16,18), panel = Color3.fromRGB(22,22,26), panel2 = Color3.fromRGB(28,28,34),
    accent = Color3.fromRGB(120,90,255), text = Color3.fromRGB(235,235,240), subtext = Color3.fromRGB(180,180,190),
    stroke = Color3.fromRGB(70,70,84), buttonBase = Color3.fromRGB(36,36,44), buttonHover = Color3.fromRGB(46,46,56), bad = Color3.fromRGB(240,80,95)
}

-- ========= Window =========
function EclipseUI:CreateWindow(cfg)
    cfg = cfg or {}
    local theme = cfg.Theme or DefaultTheme
    local dockCfg = cfg.NotifyDock or { mode = "window-left", align = "title", width = 260, gap = 12, offsetY = 8 }

    local gui = create("ScreenGui", { Name = "EclipseUI", IgnoreGuiInset = true, ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = game:GetService("CoreGui") })

    -- Responsive size: smaller on touch unless disabled
    local isTouch = UISg.TouchEnabled
    local defaultDesktopSize = cfg.Size or UDim2.fromOffset(600, 440)
    local mobileSize = cfg.MobileSize or UDim2.fromOffset(520, 360)
    local responsive = (cfg.Responsive ~= false)
    local initialSize = (responsive and isTouch) and mobileSize or defaultDesktopSize

    local root = create("Frame", { Size = initialSize, Position = UDim2.fromScale(0.5,0.5), AnchorPoint = Vector2.new(0.5,0.5), BackgroundColor3 = theme.bg, BorderSizePixel = 0, Parent = gui })
    makeRounded(root, 16); create("UIStroke", { Parent = root, Color = theme.panel2, Transparency = 0.25 })

    local titleBarH = 40
    local titleBar = create("Frame", { Size = UDim2.new(1,0,0,titleBarH), BackgroundColor3 = theme.panel, BorderSizePixel = 0, Parent = root })
    makeRounded(titleBar, 16)
    create("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1,-150,1,0), Position = UDim2.new(0,16,0,0), Text = tostring(cfg.Title or "Eclipse UI"), TextColor3 = theme.text, TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.GothamBold, TextSize = 16, Parent = titleBar })

    local function styleBtn(btn: TextButton, kind)
        btn.AutoButtonColor = false
        local base, hover, press = theme.buttonBase, theme.buttonHover, theme.accent
        if kind == "close" then base = Color3.fromRGB(50,28,32); hover = theme.bad; press = theme.bad end
        btn.BackgroundColor3 = base
        create("UIStroke", { Parent = btn, Color = theme.stroke, Thickness = 1.2, Transparency = 0.15 })
        btn.MouseEnter:Connect(function() btn.BackgroundColor3 = hover end)
        btn.MouseLeave:Connect(function() btn.BackgroundColor3 = base end)
        btn.MouseButton1Down:Connect(function() btn.BackgroundColor3 = press end)
        btn.MouseButton1Up:Connect(function() btn.BackgroundColor3 = hover end)
    end

    local closeBtn = create("TextButton", { Size = UDim2.fromOffset(26, 26), Position = UDim2.new(1,-36,0.5,-13), BackgroundColor3 = theme.buttonBase, BorderSizePixel = 0, Text = "X", TextColor3 = theme.text, Font = Enum.Font.GothamBold, TextSize = 14, Parent = titleBar })
    makeRounded(closeBtn, 8); styleBtn(closeBtn, "close")
    local miniBtn  = create("TextButton", { Size = UDim2.fromOffset(26,26), Position = UDim2.new(1,-68,0.5,-13), BackgroundColor3 = theme.buttonBase, BorderSizePixel = 0, Text = "□", TextColor3 = theme.text, Font = Enum.Font.GothamBold, TextSize = 14, Parent = titleBar })
    makeRounded(miniBtn, 8); styleBtn(miniBtn)

    -- ===== Top Banner (outside window, draggable) =====
    local bannerH = 30
    local banner = create("Frame", { Name = "TopBanner", BackgroundColor3 = theme.panel, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, bannerH), Position = UDim2.new(0, 0, 0, -bannerH + 1), ZIndex = 5, Parent = root })
    makeRounded(banner, 14)
    create("UIStroke", { Parent = banner, Color = theme.stroke, Transparency = 0.25 })
    create("UIPadding", { Parent = banner, PaddingLeft = UDim.new(0,14), PaddingRight = UDim.new(0,14) })
    create("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1,0,1,0), Text = "This script & menu was made by doug, this is not a copy of any script and it made by me only", TextColor3 = theme.text, Font = Enum.Font.GothamMedium, TextSize = 13, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center, Parent = banner, ZIndex = 6 })

    -- ===== Global UI Toggle Key + reopen hint =====
    local uiToggleKey: Enum.KeyCode = cfg.ToggleKey or Enum.KeyCode.RightShift

    local hint = create("Frame", { Name = "ReopenHint", Visible = false, BackgroundColor3 = theme.panel2, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5,0), Position = UDim2.new(0.5,0,0,6), ZIndex = 300, Parent = gui })
    makeRounded(hint, 8); local hintStroke = create("UIStroke", { Parent = hint, Color = theme.accent, Transparency = 0.2 })
    local hintPad = create("UIPadding", { Parent = hint, PaddingTop = UDim.new(0,6), PaddingBottom = UDim.new(0,6), PaddingLeft = UDim.new(0,10), PaddingRight = UDim.new(0,10) })
    local hintText = create("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1,0,1,0), Text = "", TextColor3 = theme.text, Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center, Parent = hint, ZIndex = 301 })
    local function updateHintText()
        hintText.Text = "Press "..keycodeToString(uiToggleKey).." to reopen the menu."
        local sz = TextService:GetTextSize(hintText.Text, hintText.TextSize, hintText.Font, Vector2.new(1000,100))
        hint.Size = UDim2.fromOffset(math.clamp(sz.X + hintPad.PaddingLeft.Offset + hintPad.PaddingRight.Offset, 120, 420), math.max(28, sz.Y + hintPad.PaddingTop.Offset + hintPad.PaddingBottom.Offset))
    end
    updateHintText()
    _accent_subscribe(function(c) hintStroke.Color = c end)

    local function showHint()
        updateHintText(); hint.Visible = true
        hint.BackgroundTransparency = 1; hintText.TextTransparency = 1; hintStroke.Transparency = 1
        TweenService:Create(hint, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()
        TweenService:Create(hintText, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
        TweenService:Create(hintStroke, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 0.2}):Play()
    end
    local function hideHint()
        if not hint.Visible then return end
        TweenService:Create(hint, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
        TweenService:Create(hintText, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 1}):Play()
        TweenService:Create(hintStroke, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 1}):Play()
        task.delay(0.13, function() hint.Visible = false end)
    end

    local toggleConn = UISg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == uiToggleKey then
            root.Visible = not root.Visible
        end
    end)

    -- Touch-only "Open Menu" button under the hint
    local touchOpenBtn = create("TextButton", {
        Name = "TouchOpen",
        Visible = false,
        BackgroundColor3 = theme.buttonBase,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "Open Menu",
        TextColor3 = theme.text,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        Size = UDim2.fromOffset(160, 30),
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 40),
        ZIndex = 301,
        Parent = gui,
    })
    makeRounded(touchOpenBtn, 8)
    create("UIStroke", { Parent = touchOpenBtn, Color = theme.stroke, Transparency = 0.15 })
    local function placeTouchOpenUnderHint()
        if not (hint.Visible and touchOpenBtn.Visible) then return end
        local hx, hy = hint.AbsolutePosition.X, hint.AbsolutePosition.Y
        local hw, hh = hint.AbsoluteSize.X, hint.AbsoluteSize.Y
        local centerX = hx + hw/2
        touchOpenBtn.Position = UDim2.fromOffset(math.floor(centerX + 0.5), math.floor(hy + hh + 8 + 0.5))
    end
    touchOpenBtn.MouseButton1Click:Connect(function()
        root.Visible = true
    end)
    local function refreshTouchOpen()
        local showTouch = UISg.TouchEnabled and (not root.Visible)
        touchOpenBtn.Visible = showTouch
        if showTouch then placeTouchOpenUnderHint() end
    end

    root:GetPropertyChangedSignal("Visible"):Connect(function()
        if root.Visible then hideHint() else showHint() end
        refreshTouchOpen()
    end)

    UISg.InputChanged:Connect(function(input)
        if hint.Visible and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            placeTouchOpenUnderHint()
        end
    end)
    task.defer(refreshTouchOpen)

    -- Dragging (title + banner) — supports mouse and touch
    do
        local dragging = false
        local dragStart = Vector2.new()
        local startPos = root.Position

        local function beginDrag(input)
            dragging = true
            dragStart = input.Position
            startPos = root.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end

        local function attachDrag(handle: GuiObject)
            handle.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    beginDrag(input)
                end
            end)
        end

        attachDrag(titleBar)
        attachDrag(banner)

        UISg.InputChanged:Connect(function(input)
            if not dragging then return end
            if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
                return
            end
            local delta = input.Position - dragStart
            root.Position = UDim2.new(
                startPos.X.Scale, math.floor(startPos.X.Offset + delta.X + 0.5),
                startPos.Y.Scale, math.floor(startPos.Y.Offset + delta.Y + 0.5)
            )
        end)

        miniBtn.MouseButton1Click:Connect(function()
            root.Visible = not root.Visible
        end)
        closeBtn.MouseButton1Click:Connect(function()
            if toggleConn then toggleConn:Disconnect() end
            gui:Destroy()
        end)
    end

    local tabsBar = create("Frame", { Size = UDim2.new(0,160,1,-titleBarH), Position = UDim2.new(0,0,0,titleBarH), BackgroundColor3 = theme.panel, BorderSizePixel = 0, Parent = root })
    makeRounded(tabsBar, 16)
    create("UIListLayout", { Parent = tabsBar, FillDirection = Enum.FillDirection.Vertical, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,8) })
    create("UIPadding", { Parent = tabsBar, PaddingTop = UDim.new(0,10), PaddingLeft = UDim.new(0,10), PaddingRight = UDim.new(0,10) })

    -- >>>> SCROLLABLE BODY <<<<
    local bodyScroll = create("ScrollingFrame", {
        Size = UDim2.new(1,-160,1,-titleBarH),
        Position = UDim2.new(0,160,0,titleBarH),
        BackgroundColor3 = theme.panel,
        BorderSizePixel = 0,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ScrollBarThickness = 6,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.fromOffset(0,0),
        Parent = root
    })
    makeRounded(bodyScroll, 16)

    -- inner container that holds all tab pages (unchanged API)
    local body = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1,1),
        Parent = bodyScroll
    })

    -- TOOLTIP (GLOBAL)
    local tooltip = create("Frame", { Visible=false, BackgroundColor3 = theme.panel2, BorderSizePixel = 0, ZIndex = 200, Parent = gui })
    makeRounded(tooltip, 6); create("UIStroke", { Parent = tooltip, Color = theme.stroke, Transparency = 0.2 })
    local tipPad = create("UIPadding", { Parent = tooltip, PaddingTop = UDim.new(0,6), PaddingBottom = UDim.new(0,6), PaddingLeft = UDim.new(0,8), PaddingRight = UDim.new(0,8) })
    local tipText = create("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1,0,1,0), TextColor3 = theme.text, Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center, TextWrapped = false, Parent = tooltip })

    local hoverToken = 0
    local function showTooltip(str: string)
        tipText.Text = str
        local m = UISg:GetMouseLocation()
        local bounds = TextService:GetTextSize(str, tipText.TextSize, tipText.Font, Vector2.new(1000, 100))
        local w = bounds.X + (tipPad.PaddingLeft.Offset + tipPad.PaddingRight.Offset)
        local h = bounds.Y + (tipPad.PaddingTop.Offset + tipPad.PaddingBottom.Offset)
        tooltip.Size = UDim2.fromOffset(math.clamp(w, 50, 380), math.max(24, h))
        local off = Vector2.new(14, 18)
        local screen = gui.AbsoluteSize
        local x = math.clamp(m.X + off.X, 0, screen.X - tooltip.AbsoluteSize.X)
        local y = math.clamp(m.Y + off.Y, 0, screen.Y - tooltip.AbsoluteSize.Y)
        tooltip.Position = UDim2.fromOffset(x, y)
        tooltip.Visible = true
    end
    local function hideTooltip() tooltip.Visible = false end
    UISg.InputChanged:Connect(function(input)
        if tooltip.Visible and input.UserInputType==Enum.UserInputType.MouseMovement then
            local m = UISg:GetMouseLocation()
            local off = Vector2.new(14, 18)
            local screen = gui.AbsoluteSize
            local x = math.clamp(m.X + off.X, 0, screen.X - tooltip.AbsoluteSize.X)
            local y = math.clamp(m.Y + off.Y, 0, screen.Y - tooltip.AbsoluteSize.Y)
            tooltip.Position = UDim2.fromOffset(x, y)
        end
    end)
    local function attachTooltip(target: GuiObject, text: string)
        if not text or text == "" then return end
        local myToken = 0
        target.MouseEnter:Connect(function()
            hoverToken += 1; myToken = hoverToken
            task.delay(0.25, function()
                if myToken == hoverToken and target:IsDescendantOf(gui) then showTooltip(text) end
            end)
        end)
        target.MouseLeave:Connect(function()
            hoverToken += 1; hideTooltip()
        end)
    end

    -- NOTIFICATIONS DOCK
    local NotifDock = create("Frame", { Name = "NotificationsDock", AnchorPoint = Vector2.new(1,0), BackgroundTransparency = 1, Size = UDim2.new(0, dockCfg.width or 260, 0, 0), Parent = gui, ZIndex = 50 })
    create("UIListLayout", { Parent = NotifDock, Padding = UDim.new(0,6), FillDirection = Enum.FillDirection.Vertical, SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Right, VerticalAlignment = Enum.VerticalAlignment.Top })
    local function snap(n) return math.floor(n + 0.5) end
    local function updateDock()
        local screen = gui.AbsoluteSize
        local rx, ry = root.AbsolutePosition.X, root.AbsolutePosition.Y
        local rw, rh = root.AbsoluteSize.X, root.AbsoluteSize.Y
        local gap, offsetY, mode = (dockCfg.gap or 12), (dockCfg.offsetY or 8), (dockCfg.mode or "window-left")
        local px, py
        if mode=="top-left" then
            px,py = math.clamp(8+(dockCfg.width or 260),0,screen.X), math.clamp(8+offsetY,0,screen.Y)
        elseif mode=="top-right" then
            px,py = math.clamp(screen.X-8,0,screen.X), math.clamp(8+offsetY,0,screen.Y)
        elseif mode=="window-right" then
            px,py = snap(rx + rw + gap), snap(ry + ((dockCfg.align=="content") and (titleBarH+gap+offsetY) or offsetY))
        else -- window-left
            px,py = snap(rx-gap), snap(ry + ((dockCfg.align=="content") and (titleBarH+gap+offsetY) or offsetY))
        end
        NotifDock.Position = UDim2.fromOffset(px,py)
        NotifDock.Size = UDim2.fromOffset(dockCfg.width or 260, (mode:find("top") and (screen.Y - py - 8) or (rh - ((dockCfg.align=="content") and (titleBarH + gap*2) or 0))))
    end
    RunService.RenderStepped:Connect(updateDock); task.defer(updateDock)

    -- ========= Tabs API =========
    function EclipseUI:_makeControlRow(parent: Instance, height: number, fullWidth: any)
        -- detect section padding so we can “bleed” past it
        local padLeft, padRight = 0, 0
        for _, ch in ipairs(parent:GetChildren()) do
            if ch:IsA("UIPadding") then
                padLeft  = ch.PaddingLeft.Offset
                padRight = ch.PaddingRight.Offset
                break
            end
        end

        local holder = Instance.new("Frame")
        holder.Size = UDim2.new(1, 0, 0, height)
        holder.BackgroundTransparency = 1
        holder.Parent = parent

        -- modes: false/nil = normal, true/"edge" = flush to section border
        local mode = (fullWidth == true or fullWidth == "edge") and "edge" or "normal"
        local bleedL = 0
        local bleedR = 0
        if mode == "edge" then
            bleedL = padLeft
            bleedR = padRight
        end

        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, bleedL + bleedR, 1, 0)
        row.Position = UDim2.new(0, -bleedL, 0, 0)
        row.BackgroundColor3 = theme.buttonBase
        row.BorderSizePixel = 0
        row.Parent = holder

        local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 8); corner.Parent = row
        local stroke = Instance.new("UIStroke"); stroke.Color = theme.stroke; stroke.Transparency = 0.2; stroke.Parent = row

        local pad = Instance.new("UIPadding")
        pad.PaddingLeft  = UDim.new(0, 12)
        pad.PaddingRight = UDim.new(0, 12)
        pad.Parent = row

        return holder, row
    end

    function EclipseUI:AddTab(name: string)
        name = tostring(name)
        local tabBtn = create("TextButton", { Size = UDim2.new(1,0,0,34), BackgroundColor3 = theme.buttonBase, BorderSizePixel = 0, Text = name, TextColor3 = theme.subtext, Font = Enum.Font.GothamBold, TextSize = 14, Parent = tabsBar })
        makeRounded(tabBtn,8); create("UIStroke", { Parent = tabBtn, Color=theme.stroke, Transparency=0.2 })
        tabBtn.MouseEnter:Connect(function() tabBtn.TextColor3 = theme.text end)
        tabBtn.MouseLeave:Connect(function() tabBtn.TextColor3 = theme.subtext end)

        local tabPage = create("Frame", { Size = UDim2.fromScale(1,1), BackgroundTransparency = 1, Visible = false, Parent = body })
        local columns = {
            Left  = create("Frame", { Size = UDim2.new(0.5,-12,1,-16), Position = UDim2.new(0,12,0,8), BackgroundTransparency = 1, Parent = tabPage }),
            Right = create("Frame", { Size = UDim2.new(0.5,-12,1,-16), Position = UDim2.new(0.5,0,0,8), BackgroundTransparency = 1, Parent = tabPage }),
        }
        for _,col in pairs(columns) do
            create("UIListLayout", { Parent = col, FillDirection = Enum.FillDirection.Vertical, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,10) })
        end

        local function AddSection(which: string, title: string)
            local parent = columns[which]
            local group = create("Frame", { BackgroundColor3 = theme.panel2, BorderSizePixel = 0, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1,0,0,0), Parent = parent })
            makeRounded(group,12); create("UIStroke", { Parent = group, Color = theme.panel, Transparency = 0.25 })
            create("UIListLayout", { Parent = group, FillDirection = Enum.FillDirection.Vertical, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,8) })
            create("UIPadding", { Parent = group, PaddingTop = UDim.new(0,10), PaddingLeft = UDim.new(0,10), PaddingRight = UDim.new(0,10), PaddingBottom = UDim.new(0,10) })
            create("TextLabel", { BackgroundTransparency = 1, Text = title, TextColor3 = theme.text, Font = Enum.Font.GothamBold, TextSize = 14, Size = UDim2.new(1,0,0,16), Parent = group })

            local section = { Container = group, Column = which }

            function section:AddLabel(text)
                return create("TextLabel", { BackgroundTransparency = 1, Text = tostring(text), TextColor3 = theme.subtext, Font = Enum.Font.Gotham, TextSize = 14, Size = UDim2.new(1,0,0,16), TextWrapped = true, Parent = group })
            end
            function section:AddDivider() return create("Frame", { BackgroundColor3 = theme.panel, BorderSizePixel = 0, Size = UDim2.new(1,0,0,1), Parent = group }) end

            -- BUTTON
            function section:AddButton(cfg)
                cfg = cfg or {}
                local holder, row = EclipseUI:_makeControlRow(group, 34, cfg.fullWidth)
                local btn = create("TextButton", { BackgroundTransparency = 1, Size = UDim2.fromScale(1,1), Text = tostring(cfg.text or "Button"), Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = theme.text, Parent = row })
                btn.AutoButtonColor = false
                attachTooltip(btn, cfg.tooltip)
                btn.MouseButton1Click:Connect(function() if typeof(cfg.callback)=="function" then task.spawn(cfg.callback) end end)
                return btn
            end

            -- TOGGLE
            function section:AddToggle(cfg)
                cfg = cfg or {}
                local state = cfg.default or false
                local holder, row = EclipseUI:_makeControlRow(group, 34, cfg.fullWidth)
                local lbl = create("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1,-56,1,0), Text = tostring(cfg.text or "Toggle"), TextColor3 = theme.text, Font = Enum.Font.Gotham, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, Parent = row })
                local knob = create("TextButton", { Size = UDim2.fromOffset(46,22), AnchorPoint = Vector2.new(1,0.5), Position = UDim2.new(1,-6,0.5,0), BackgroundColor3 = state and theme.accent or theme.panel, BorderSizePixel = 0, Text = "", Parent = row })
                makeRounded(knob, 11)
                local circle = create("Frame", { Size = UDim2.fromOffset(18,18), AnchorPoint = Vector2.new(0.5,0.5), Position = state and UDim2.new(1,-11,0.5,0) or UDim2.new(0,11,0.5,0), BackgroundColor3 = theme.bg, BorderSizePixel = 0, Parent = knob })
                makeRounded(circle, 9)
                attachTooltip(row, cfg.tooltip)
                local function set(v: boolean, silent: boolean)
                    state = v and true or false
                    knob.BackgroundColor3 = state and theme.accent or theme.panel
                    circle.Position = state and UDim2.new(1,-11,0.5,0) or UDim2.new(0,11,0.5,0)
                    if not silent and typeof(cfg.callback)=="function" then task.spawn(cfg.callback, state) end
                end
                if state then set(true, true) end
                knob.MouseButton1Click:Connect(function() set(not state) end)
                lbl.InputBegan:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 then set(not state) end end)
                _accent_subscribe(function(c) if state then knob.BackgroundColor3 = c end end)
                return { Set=function(_,v) set(v) end, Get=function() return state end }
            end

            -- SLIDER
            function section:AddSlider(cfg)
                cfg = cfg or {}
                local min = tonumber(cfg.min) or 0; local max = tonumber(cfg.max) or 100; local step = tonumber(cfg.step) or 1
                local val = math.clamp(tonumber(cfg.default) or min, min, max)
                local rounding = tonumber(cfg.rounding) or 0
                local suffix = tostring(cfg.suffix or "")
                local holder, row = EclipseUI:_makeControlRow(group, 44, cfg.fullWidth)
                local top = create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1,0,0,18), Parent = row })
                create("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1,-110,1,0), Text = tostring(cfg.text or "Slider"), TextColor3 = theme.text, Font = Enum.Font.Gotham, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, Parent = top })
                local valLbl = create("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(0,100,1,0), Position = UDim2.new(1,-100,0,0), Text = "", TextColor3 = theme.subtext, Font = Enum.Font.Gotham, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Right, Parent = top })
                local bar = create("Frame", { Size = UDim2.new(1,0,0,10), Position = UDim2.new(0,0,0,26), BackgroundColor3 = theme.panel, BorderSizePixel = 0, Parent = row })
                makeRounded(bar, 6)
                local fill = create("Frame", { Size = UDim2.new(0,0,1,0), BackgroundColor3 = theme.accent, BorderSizePixel = 0, Parent = bar })
                makeRounded(fill, 6)
                attachTooltip(row, cfg.tooltip)
                _accent_subscribe(function(c) fill.BackgroundColor3 = c end)
                local dragging = false
                local function set(v: number, silent: boolean)
                    v = math.clamp(v, min, max); v = math.floor(v/step+0.5)*step; val = v
                    local a = (val - min)/math.max(0.0001,(max - min)); fill.Size = UDim2.new(a,0,1,0)
                    local t = tostring((rounding>0) and (math.floor(v*10^rounding+0.5)/(10^rounding)) or v); if suffix~="" then t = t.." "..suffix end; valLbl.Text = t
                    if not silent and typeof(cfg.callback)=="function" then task.spawn(cfg.callback, val) end
                end
                set(val, true)
                local function updateFromX(x)
                    local rel = math.clamp((x - bar.AbsolutePosition.X)/math.max(1,bar.AbsoluteSize.X),0,1)
                    set(min + (max-min)*rel)
                end
                local function isPointer(input)
                    return input.UserInputType == Enum.UserInputType.MouseButton1
                        or input.UserInputType == Enum.UserInputType.Touch
                end
                local function isPointerMove(input)
                    return input.UserInputType == Enum.UserInputType.MouseMovement
                        or input.UserInputType == Enum.UserInputType.Touch
                end

                bar.InputBegan:Connect(function(input)
                    if isPointer(input) then
                        dragging = true
                        updateFromX(input.Position.X)
                        -- end drag when this pointer ends
                        input.Changed:Connect(function()
                            if input.UserInputState == Enum.UserInputState.End then
                                dragging = false
                            end
                        end)
                    end
                end)

                UISg.InputChanged:Connect(function(input)
                    if dragging and isPointerMove(input) then
                        updateFromX(input.Position.X)
                    end
                end)

                UISg.InputEnded:Connect(function(input)
                    if isPointer(input) then
                        dragging = false
                    end
                end)
                return { Set=function(_,v) set(tonumber(v) or val) end, Get=function() return val end }
            end

            -- KEYBIND
            function section:AddKeybind(cfg)
                cfg = cfg or {}
                local holder, row = EclipseUI:_makeControlRow(group, 34, cfg.fullWidth)
                create("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1,-120,1,0), Text = tostring(cfg.text or "UI Toggle Key"), TextColor3 = theme.text, Font = Enum.Font.Gotham, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, Parent = row })
                local btn = create("TextButton", { Size = UDim2.new(0,120,0,26), AnchorPoint = Vector2.new(1,0.5), Position = UDim2.new(1,-6,0.5,0), BackgroundColor3 = theme.buttonBase, BorderSizePixel = 0, Text = keycodeToString(cfg.default or Enum.KeyCode.RightShift), TextColor3 = theme.text, Font = Enum.Font.GothamBold, TextSize = 14, Parent = row })
                makeRounded(btn, 8); create("UIStroke", { Parent = btn, Color=theme.stroke, Transparency=0.2 })
                attachTooltip(row, cfg.tooltip)
                local waiting=false
                btn.MouseButton1Click:Connect(function()
                    if waiting then return end; waiting=true; btn.Text="Press a key..."
                    local conn; conn = UISg.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            waiting=false; btn.Text = keycodeToString(input.KeyCode); if conn then conn:Disconnect() end
                            if typeof(cfg.callback)=="function" then task.spawn(cfg.callback, input.KeyCode) end
                        end
                    end)
                end)
                return { Set=function(_,kc) btn.Text = keycodeToString(kc) end }
            end

            -- INPUT (compact)
            function section:AddInput(cfg)
                cfg = cfg or {}
                local holder, row = EclipseUI:_makeControlRow(group, 36, cfg.fullWidth)
                local label = create("TextLabel", {
                    BackgroundTransparency = 1, Size = UDim2.new(1,-180,1,0),
                    Text = tostring(cfg.text or "Input"), TextColor3 = theme.text, Font = Enum.Font.Gotham, TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left, Parent = row
                })
                local box = create("TextBox", {
                    Size = UDim2.new(0,170,1,-10), AnchorPoint = Vector2.new(1,0.5), Position = UDim2.new(1,-8,0.5,0),
                    BackgroundColor3 = theme.buttonBase, BorderSizePixel = 0,
                    Text = tostring(cfg.default or ""), PlaceholderText = tostring(cfg.placeholder or ""),
                    TextColor3 = theme.text, PlaceholderColor3 = theme.subtext, ClearTextOnFocus = (cfg.clearOnFocus == true),
                    Font = Enum.Font.Gotham, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, ClipsDescendants = true, Parent = row
                })
                makeRounded(box, 8); create("UIStroke", { Parent = box, Color=theme.stroke, Transparency=0.2 })
                local pad = Instance.new("UIPadding"); pad.PaddingLeft = UDim.new(0,6); pad.PaddingRight = UDim.new(0,2); pad.Parent = box
                local function relayout()
                    local totalW = row.AbsoluteSize.X
                    local minLabel = 100; local marginR = 8
                    local boxW = math.min(170, totalW - minLabel - 20)
                    box.Size = UDim2.new(0, boxW, 1, -10)
                    label.Size = UDim2.new(1, -(boxW + 12 + marginR), 1, 0)
                end
                row:GetPropertyChangedSignal("AbsoluteSize"):Connect(relayout); task.defer(relayout)
                local function commit() if typeof(cfg.callback)=="function" then task.spawn(cfg.callback, box.Text) end end
                box.FocusLost:Connect(function(enter) if enter or not UISg:GetFocusedTextBox() then commit() end end)
                if box.ReturnPressedFromOnScreenKeyboard then box.ReturnPressedFromOnScreenKeyboard:Connect(commit) end
                return { Set=function(_,txt) box.Text=tostring(txt or "") end, Get=function() return box.Text end, Instance=box }
            end

            -- DROPDOWN
            function section:AddDropdown(cfg)
                cfg = cfg or {}
                local options = table.clone(cfg.options or {"A","B","C"})
                local value = tostring(cfg.default or options[1] or "")
                local useUnicode = (cfg.unicode == true)
                local arrowClosed, arrowOpen = (useUnicode and " ▾" or " v"), (useUnicode and " ▴" or " ^")
                local itemH, collapsedH, maxVisible = 26, 34, 6
                local requestedValueWidth = tonumber(cfg.valueWidth) or 150

                local holder = create("Frame", { Size = UDim2.new(1,0,0,collapsedH), BackgroundTransparency = 1, Parent = group, ZIndex = 20 })
                local bleed = (cfg.fullWidth and 10 or 0)
                local header = create("TextButton", { Size = UDim2.new(1, bleed*2, 0, collapsedH), Position = UDim2.new(0, -bleed, 0, 0), BackgroundColor3 = theme.buttonBase, BorderSizePixel = 0, Text = "", Parent = holder, ZIndex = 21 })
                makeRounded(header, 8); create("UIStroke", { Parent = header, Color=theme.stroke, Transparency=0.2 })
                create("UIPadding", { Parent = header, PaddingLeft = UDim.new(0,12), PaddingRight = UDim.new(0,12) })

                local lbl  = create("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1,-(requestedValueWidth+12),1,0), Text = tostring(cfg.text or "Dropdown"), TextColor3 = theme.text, Font = Enum.Font.Gotham, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.None, Parent = header, ZIndex = 22 })
                local valLbl = create("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(0,requestedValueWidth,1,0), Position = UDim2.new(1,-requestedValueWidth,0,0), Text = (value ~= "" and (value..arrowClosed) or ("Select"..arrowClosed)), TextColor3 = theme.text, Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd, Parent = header, ZIndex = 22 })

                local function layout()
                    local w = math.max(0, header.AbsoluteSize.X)
                    local maxValueWidth = math.floor(w * 0.55)
                    local minValueWidth = 90
                    local minLabelWidth = 140
                    local vw = math.clamp(requestedValueWidth, minValueWidth, maxValueWidth)
                    if cfg.autoValueWidth then
                        local bs = TextService:GetTextSize(valLbl.Text, valLbl.TextSize, valLbl.Font, Vector2.new(10000, 100))
                        vw = math.clamp(bs.X + 4, minValueWidth, maxValueWidth)
                    end
                    vw = math.min(vw, math.max(minValueWidth, w - (minLabelWidth + 12)))
                    valLbl.Size = UDim2.new(0, vw, 1, 0)
                    valLbl.Position = UDim2.new(1, -vw, 0, 0)
                    lbl.Size = UDim2.new(1, -(vw + 12), 1, 0)
                end
                header:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
                valLbl:GetPropertyChangedSignal("Text"):Connect(function() if cfg.autoValueWidth then layout() end end)
                task.defer(layout)

                local listFrame = create("Frame", { Size = UDim2.new(1, bleed*2, 0, 0), Position = UDim2.new(0, -bleed, 0, collapsedH+4), BackgroundColor3 = theme.panel2, BorderSizePixel = 0, Parent = holder, ClipsDescendants = true, ZIndex = 25 })
                makeRounded(listFrame, 8); create("UIStroke", { Parent = listFrame, Color = theme.stroke, Transparency = 0.2 })
                local scroll = create("ScrollingFrame", { Active = true, BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, ScrollingDirection = Enum.ScrollingDirection.Y, CanvasSize = UDim2.fromOffset(0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y, Size = UDim2.new(1,0,1,0), Parent = listFrame, ZIndex = 26 })
                create("UIListLayout", { Parent = scroll, FillDirection = Enum.FillDirection.Vertical, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,4) })
                create("UIPadding", { Parent = scroll, PaddingTop = UDim.new(0,4), PaddingBottom = UDim.new(0,4), PaddingLeft = UDim.new(0,4), PaddingRight = UDim.new(0,4) })

                local open = false
                local optionButtons: {TextButton} = {}

                local function close()
                    tweenSizeSafe(listFrame, UDim2.new(1, bleed*2, 0, 0)); tweenSizeSafe(holder, UDim2.new(1,0,0,collapsedH)); valLbl.Text = value .. arrowClosed; open = false
                end
                local function openNow()
                    local count = #optionButtons
                    local visible = math.min(count, maxVisible)
                    local h = visible * itemH + 8
                    tweenSizeSafe(listFrame, UDim2.new(1, bleed*2, 0, h)); tweenSizeSafe(holder, UDim2.new(1,0,0,collapsedH + h + 4)); valLbl.Text = value .. arrowOpen; open = true
                end

                local function rebuildOptions()
                    for _,c in ipairs(scroll:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
                    table.clear(optionButtons)
                    for _,opt in ipairs(options) do
                        local it = create("TextButton", { Size = UDim2.new(1,0,0,itemH-2), BackgroundColor3 = theme.buttonBase, BorderSizePixel = 0, Text = tostring(opt), TextColor3 = theme.text, Font = Enum.Font.Gotham, TextSize = 14, Parent = scroll, ZIndex = 27 })
                        makeRounded(it, 6); create("UIStroke", { Parent = it, Color=theme.stroke, Transparency=0.2 })
                        it.MouseButton1Down:Connect(function()
                            value = tostring(opt); valLbl.Text = value .. (open and arrowOpen or arrowClosed); close(); if typeof(cfg.callback)=="function" then task.spawn(cfg.callback, value) end
                        end)
                        table.insert(optionButtons, it)
                    end
                end
                rebuildOptions()

                header.MouseButton1Click:Connect(function() if open then close() else openNow() end end)

                return { Set=function(_, v) value=tostring(v); valLbl.Text=value..(open and arrowOpen or arrowClosed); layout(); if typeof(cfg.callback)=="function" then task.spawn(cfg.callback,value) end end,
                         Get=function() return value end,
                         SetOptions=function(_, newOptions) options=table.clone(newOptions or options); rebuildOptions(); if open then openNow() end end }
            end -- dropdown

            return section
        end

        local tab = {
            Page = tabPage, Columns = columns,
            AddLeftSection = function(_,t) return AddSection("Left",t) end,
            AddRightSection = function(_,t) return AddSection("Right",t) end,
            AddSection = function(_,t) return AddSection("Left",t) end,
        }
        tabBtn.MouseButton1Click:Connect(function()
            for _,other in pairs(body:GetChildren()) do if other:IsA("Frame") then other.Visible = false end end
            tabPage.Visible = true
            bodyScroll.CanvasPosition = Vector2.new(0,0) -- reset scroll when switching tabs
            for _,b in pairs(tabsBar:GetChildren()) do if b:IsA("TextButton") then b.TextColor3 = theme.subtext end end
            tabBtn.TextColor3 = theme.text
        end)
        if #body:GetChildren() == 1 then task.defer(function() tabBtn.MouseButton1Click:Fire() end) end
        return tab
    end

    -- Public window methods
    local window = setmetatable({ Instance=gui, Frame=root, TabsBar=tabsBar, Body=body, Theme=theme, _dockCfg=dockCfg }, { __index = EclipseUI })

    function window:Notify(text: string, seconds: number)
        local card = create("Frame", { BackgroundColor3 = theme.panel2, BorderSizePixel = 0, Size = UDim2.new(0, dockCfg.width or 260, 0, 34), Parent = NotifDock, ZIndex = 50 })
        makeRounded(card,10); create("UIStroke", { Parent = card, Color = theme.accent, Thickness = 1, Transparency = 0.25 })
        create("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1,1), Text = tostring(text), TextColor3 = theme.text, Font = Enum.Font.Gotham, TextSize = 14, Parent = card, ZIndex = 51 })
        task.delay(seconds or 3, function() if card then card:Destroy() end end)
    end

    function window:SetNotifyDock(opts) for k,v in pairs(opts or {}) do (self._dockCfg :: any)[k] = v end end
    function window:GetNotifyDock() return self._dockCfg end

    function window:SetAccentColor(c: Color3)
        theme.accent = c; _accent_publish(c)
        for _,d in ipairs(gui:GetDescendants()) do if d:IsA("UIStroke") and d.Parent and d.Parent.Name=="ReopenHint" then d.Color = c end end
    end
    function window:GetAccentColor() return theme.accent end

    -- ========= SETTINGS TAB =========
    local Settings = window:AddTab("Settings")
    local General = Settings:AddLeftSection("General")
    local Perf = Settings:AddLeftSection("Performance")
    local Noti = Settings:AddRightSection("Notifications")
    local ThemeSec = Settings:AddRightSection("Appearance")

    General:AddKeybind({
        text = "UI Toggle Key",
        default = uiToggleKey,
        fullWidth = true,
        tooltip = "Key used to show/hide the UI",
        callback = function(kc) uiToggleKey = kc; updateHintText() end
    })

    Perf:AddSlider({
        text = "FPS Cap",
        min = 10, max = 240, step = 5, default = 60, rounding = 0, suffix = "fps",
        fullWidth = true,
        tooltip = "Clamp client FPS (requires executor with FPS API)",
        callback = function(v) local ok = applyFpsCap(v); if not ok then window:Notify("⚠️ No supported FPS cap API found.", 3) end end
    })

    local mode2label = { ["top-right"]="Top Right", ["top-left"]="Top Left", ["window-left"]="Left of Window", ["window-right"]="Right of Window" }
    local label2mode = { ["Top Right"]="top-right", ["Top Left"]="top-left", ["Left of Window"]="window-left", ["Right of Window"]="window-right" }
    Noti:AddDropdown({
        text = "Dock position",
        options = {"Top Right","Top Left","Left of Window","Right of Window"},
        default = mode2label[dockCfg.mode or "window-left"],
        fullWidth = true,
        autoValueWidth = true,
        tooltip = "Where notifications appear",
        callback = function(val) window:SetNotifyDock({ mode = label2mode[val] or "window-left" }) end
    })

    Noti:AddSlider({
        text = "Vertical offset",
        min = -40, max = 60, step = 1, default = dockCfg.offsetY or 8, rounding = 0, suffix = "px",
        fullWidth = true,
        tooltip = "Shift notifications up/down",
        callback = function(v) window:SetNotifyDock({ offsetY = v }) end
    })

    local palette = {
        Color3.fromRGB(120,90,255), Color3.fromRGB(0,170,255), Color3.fromRGB(255,120,60),
        Color3.fromRGB(70,220,120), Color3.fromRGB(255,75,110), Color3.fromRGB(255,200,80),
        Color3.fromRGB(90,210,255), Color3.fromRGB(180,120,255), Color3.fromRGB(255,140,190),
        Color3.fromRGB(120,200,140), Color3.fromRGB(255,100,80), Color3.fromRGB(100,120,255),
    }

    local gridHolder = create("Frame", { BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1,0,0,0), Parent = ThemeSec.Container })
    local gridPad = create("UIPadding", { Parent = gridHolder, PaddingTop = UDim.new(0,4), PaddingBottom = UDim.new(0,4), PaddingLeft = UDim.new(0,4), PaddingRight = UDim.new(0,4) })
    local grid = create("UIGridLayout", { Parent = gridHolder, CellPadding = UDim2.new(0,6,0,6), CellSize = UDim2.new(0,28,0,28), SortOrder = Enum.SortOrder.LayoutOrder })
    grid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        gridHolder.Size = UDim2.new(1,0,0, grid.AbsoluteContentSize.Y + gridPad.PaddingTop.Offset + gridPad.PaddingBottom.Offset)
    end)

    for _,c in ipairs(palette) do
        local sw = create("TextButton", { Size = UDim2.fromOffset(28,28), BackgroundColor3 = c, BorderSizePixel = 0, Text = "", Parent = gridHolder })
        makeRounded(sw, 6); create("UIStroke", { Parent = sw, Color = theme.stroke, Thickness = 1, Transparency = 0.2 })
        attachTooltip(sw, "Set accent color")
        sw.MouseButton1Click:Connect(function() window:SetAccentColor(c); window:Notify("Accent color updated", 2) end)
    end

    do
        local info = create("TextLabel", { BackgroundTransparency = 1, Text = "Accent applies to toggles, sliders and notifications.", TextColor3 = theme.subtext, Font = Enum.Font.Gotham, TextSize = 13, TextWrapped = true, Size = UDim2.new(1,-8,0,0), AutomaticSize = Enum.AutomaticSize.Y, Parent = ThemeSec.Container })
        create("UIPadding", { Parent = info, PaddingLeft = UDim.new(0,4) })
    end

    return window
end

return setmetatable({}, EclipseUI)
