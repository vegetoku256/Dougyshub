-- ===== MOBILE / LOW-END FIX =====
-- Put this once at the very top, before anything else
local player = game:GetService('Players').LocalPlayer
local isMobile = game:GetService('UserInputService').TouchEnabled

-- Wait until the game is actually loaded
if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- Auto-clean old connections if user re-executes
if getgenv()._hubConnections then
    for _, c in ipairs(getgenv()._hubConnections) do
        pcall(function()
            c:Disconnect()
        end)
    end
end
getgenv()._hubConnections = {}
-- ===== END FIX =====

-- =========================
-- Anti-AFK (drop-in, UI-less)
-- Place this at the VERY TOP of Main Hub.lua
-- =========================
do
    if not getgenv()._antiAFK_active then
        getgenv()._antiAFK_active = true

        local Players = game:GetService("Players")
        local VirtualUser = game:GetService("VirtualUser")
        local player = Players.LocalPlayer

        -- Fire whenever Roblox detects idling
        player.Idled:Connect(function()
            task.wait(math.random(1,3)) -- small jitter to look human
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new(0,0)) -- right-click tap
            end)
        end)

        -- Redundant keepalive (helps in games that don't trigger Idled reliably)
        task.spawn(function()
            while getgenv()._antiAFK_active do
                task.wait(60) -- every 60s; raise/lower if you want
                pcall(function()
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton2(Vector2.new(0,0))
                end)
            end
        end)
    end
end



-- future tycoon script

if game.PlaceId == 235521386 then

    --call library

    local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

    --main window

local Window = Rayfield:CreateWindow({
   Name = "Dive into water script",
   Icon = 0, -- Icon in Topbar. Can use Lucide Icons (string) or Roblox Image (number). 0 to use no icon (default).
   LoadingTitle = "loadin",
   LoadingSubtitle = "by Doug",
   ShowText = "hide", -- for mobile users to unhide rayfield, change if you'd like
   Theme = "DarkBlue", -- Check https://docs.sirius.menu/rayfield/configuration/themes

   ToggleUIKeybind = "K", -- The keybind to toggle the UI visibility (string like "K" or Enum.KeyCode)

   DisableRayfieldPrompts = true,
   DisableBuildWarnings = false, -- Prevents Rayfield from warning when the script has a version mismatch with the interface

   ConfigurationSaving = {
      Enabled = true,
      FolderName = nil, -- Create a custom folder for your hub/game
      FileName = "Big Hub"
   },

   Discord = {
      Enabled = true, -- Prompt the user to join your Discord server if their executor supports it
      Invite = "https://discord.gg/dZvUNnvKgU", -- The Discord invite code, do not include discord.gg/. E.g. discord.gg/ ABCD would be ABCD
      RememberJoins = true -- Set this to false to make them join the discord every time they load it up
   },

   KeySystem = false, -- Set this to true to use our key system
   KeySettings = {
      Title = "Untitled",
      Subtitle = "Key System",
      Note = "No method of obtaining the key is provided", -- Use this to tell the user how to get a key
      FileName = "DougKey", -- It is recommended to use something unique as other scripts using Rayfield may overwrite your key file
      SaveKey = true, -- The user's key will be saved, but if you change the key, they will be unable to use your script
      GrabKeyFromSite = false, -- If this is true, set Key below to the RAW site you would like Rayfield to get the key from
      Key = {"Hello"}, -- List of keys that will be accepted by the system, can be RAW file links (pastebin, github etc) or simple strings ("hello","key22")
   },
   
})

    --local var
    local autoclick = false
    local autoclick2 = false

    --farm
    local Tab = Window:CreateTab(" 👨‍🌾 Farm")

    local Toggle = Tab:CreateToggle({   
        Name = "Autoclick",
        CurrentValue = false,
        Flag = "autoclickFTycoon",
        Callback = function(state)
        autoclick = state
        while autoclick do
            local args = {
                "click",
                workspace:WaitForChild("TycoonManagement"):WaitForChild("Tycoons"):WaitForChild("Bright orange"):WaitForChild("PurchasedObjects"):WaitForChild("Mine"):WaitForChild("Button"):WaitForChild("ClickDetector")
            }
            game:GetService("ReplicatedStorage"):WaitForChild("MasterKey"):FireServer(unpack(args))
            task.wait(0.1)            
        end
        end
    })

    local Toggle = Tab:CreateToggle({   
        Name = "autoclick2",
        CurrentValue = false,
        Flag = "autoclick2FTycoon",
        Callback = function(state)
        autoclick2 = state
        while autoclick2 do
            local args = {
                "click",
                workspace:WaitForChild("TycoonManagement"):WaitForChild("Tycoons"):WaitForChild("Bright orange"):WaitForChild("PurchasedObjects"):WaitForChild("SMine"):WaitForChild("Button"):WaitForChild("ClickDetector")
            }
            game:GetService("ReplicatedStorage"):WaitForChild("MasterKey"):FireServer(unpack(args))
            task.wait(0.1)            
        end
        end
    })



    local Input = Tab:CreateInput({
        Name = "WalkSpeed",
        CurrentValue = "",
        PlaceholderText = "Input Placeholder",
        RemoveTextAfterFocusLost = false,
        Flag = "Input1",
        Callback = function(Text)
            game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = tonumber(Text)
        end,
    })

    local Button = Tab:CreateButton({
        Name = "LAG (to make the parts freeze in the sell box",
        Callback = function() 
            local duration = 0.5 -- secondes de lag

            -- Affichage d'un message tip top
            warn("🔥 Lag volontaire pendant " .. duration .. " secondes (rip FPS)")

            -- Boucle qui surcharge le thread
            local startTime = tick()
            while tick() - startTime < duration do
                -- Calculs inutiles juste pour faire chauffer le CPU
                for i = 1, 1e6 do
                    local a = math.sqrt(i * math.random())
                end
            end

            warn("✅ Lag terminé, c'était bien tip top 💥")

        end
    })

















-- Dive Into Water Script

elseif game.PlaceId == 81593728625228 then
    local currentversion = "test"

    --call library

    local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()


    --main window

local Window = Rayfield:CreateWindow({
   Name = "Dive into water script",
   Icon = 0, -- Icon in Topbar. Can use Lucide Icons (string) or Roblox Image (number). 0 to use no icon (default).
   LoadingTitle = "loadin",
   LoadingSubtitle = "by Doug",
   ShowText = "hide", -- for mobile users to unhide rayfield, change if you'd like
   Theme = "DarkBlue", -- Check https://docs.sirius.menu/rayfield/configuration/themes

   ToggleUIKeybind = "K", -- The keybind to toggle the UI visibility (string like "K" or Enum.KeyCode)

   DisableRayfieldPrompts = true,
   DisableBuildWarnings = false, -- Prevents Rayfield from warning when the script has a version mismatch with the interface

   ConfigurationSaving = {
      Enabled = true,
      FolderName = nil, -- Create a custom folder for your hub/game
      FileName = "Big Hub"
   },

   Discord = {
      Enabled = true, -- Prompt the user to join your Discord server if their executor supports it
      Invite = "https://discord.gg/dZvUNnvKgU", -- The Discord invite code, do not include discord.gg/. E.g. discord.gg/ ABCD would be ABCD
      RememberJoins = true -- Set this to false to make them join the discord every time they load it up
   },

   KeySystem = false, -- Set this to true to use our key system
   KeySettings = {
      Title = "Untitled",
      Subtitle = "Key System",
      Note = "No method of obtaining the key is provided", -- Use this to tell the user how to get a key
      FileName = "DougKey", -- It is recommended to use something unique as other scripts using Rayfield may overwrite your key file
      SaveKey = true, -- The user's key will be saved, but if you change the key, they will be unable to use your script
      GrabKeyFromSite = false, -- If this is true, set Key below to the RAW site you would like Rayfield to get the key from
      Key = {"Hello"}, -- List of keys that will be accepted by the system, can be RAW file links (pastebin, github etc) or simple strings ("hello","key22")
   },
   
})


--local var
local zone = nil
local ZoneIndexMap = {
    ["Happy Creeks"] = 1,
    ["Icy Tremors"] = 2,
    ["Heavenly Descend"] = 3,
    ["Candy Land"] = 4,
    ["Deep Space"] = 5,
    ["Pixel Casle"] = 6,
    ["Pixel Desert"] = 7,
}

local ZoneCoordinates = {
[1] = Vector3.new(819.508484, -29188.8105, 1752.26794),
[2] = Vector3.new(-2355.83423, -29085.8164, 1642.10632),
[3] = Vector3.new(-4829.3501, -29503.8164, 1001.10632),
[4] = Vector3.new(-4829.3501, -27455.8164, -199.893677),
[5] = Vector3.new(-1971.3501, -22524.5605, 6143.10645),
[6] = Vector3.new(-2653.3501, -15883.5605, 28593.1055),
[7] = Vector3.new(-9524.35059, -29878.3613, 3039.70532),
}



--farm
local Tab = Window:CreateTab(" 👨‍🌾 Farm")

local Dropdown = Tab:CreateDropdown({
Name = "Zones",
Options = {"Happy Creeks","Icy Tremors","Heavenly Descend","Candy Land","Deep Space","Pixel Casle","Pixel Desert"},
CurrentOption = {"Happy Creeks"},
MultipleOptions = false,
Flag = "DiveGameDropDownZone",
Callback = function(Options)
    local selected = Options[1]
    zone = ZoneIndexMap[selected]

    if zone then
        print("L'utilisateur a choisi l'option : " .. selected .. " (index = " .. zone .. ")")
    else
         warn("Option inconnue : " .. tostring(selected))
    end
end,
})



local isTpEnabled = false -- permet de garder l'état à jour

local Toggle = Tab:CreateToggle({   
    Name = "👑 Tp to win 👑",
    CurrentValue = false,
    Flag = "tptowinDiveGame",
    Callback = function(Value)
        isTpEnabled = Value

        if Value then
            task.spawn(function()
                local player = game.Players.LocalPlayer

                while isTpEnabled do
                    local character = player.Character or player.CharacterAdded:Wait()
                    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
                    
                    if humanoidRootPart and ZoneCoordinates[zone] then
                        humanoidRootPart.CFrame = CFrame.new(ZoneCoordinates[zone])
                        print("👑 Tp vers zone " .. tostring(zone) .. " effectué !")
                    else
                        warn("Zone ou HumanoidRootPart introuvable.")
                    end
                    task.wait(15) -- délai entre chaque TP
                end
            end)
        end
    end
})

    






local Tab = Window:CreateTab(" 🥚 eggs")

local oeuf = nil

-- Correspondance entre le nom visible et l'index numérique
local eggIndexMap = {
    ["200"] = 1,
    ["20k"] = 2,
    ["2M"] = 3,
    ["400M"] = 4,
    ["150B"] = 5,
    ["18T"] = 6,
    ["800T"] = 7,
    ["175Qa"] = 8,
    ["30Qi"] = 9,
    ["4.5sp"] = 10,
    ["12Sx"] = 11,
    ["80Oc"] = 12,
    ["4No"] = 13,
    ["1Dc"] = 14,
    ["5Ud"] = 15,
    ["12Dd"] = 16,
    ["5Td"] = 17,
    ["10QaD"] = 18,

}

local Dropdown = Tab:CreateDropdown({
    Name = "eggs",
    Options = {"Default","200","20k","2M","400M","150B","18T","800T","175Qa","30Qi","4.5sp","12Sx","80Oc","4No","1Dc","5Ud","12Dd","5Td","10QaD"},
    CurrentOption = {"Default"},
    MultipleOptions = false,
    Flag = "DiveGameDropDownEgg",
    Callback = function(Options)
        local selected = Options[1]
        oeuf = eggIndexMap[selected]

        if oeuf then
            print("L'utilisateur a choisi l'option : " .. selected .. " (index = " .. oeuf .. ")")
        else
            warn("Option inconnue : " .. tostring(selected))
        end
    end,
})


local Button = Tab:CreateButton({
   Name = "Open selected egg",
   Callback = function()
        -- Generated with Sigma Spy Github: https://github.com/depthso/Sigma-Spy
            -- Services
        local ReplicatedStorage = game:GetService("ReplicatedStorage")

        -- Remote
        local EggHatch = ReplicatedStorage.Events.EggHatch -- RemoteFunction 

        -- Variables
        local Mango1 = workspace.EggShop[oeuf] -- Instance

        EggHatch:InvokeServer(
            Mango1,
            1
        )  
   end,
})

local Tab = Window:CreateTab(" 💎 OP")


local Label = Tab:CreateLabel("You must press ALL the buttons in order from 1-4 to correctly get the money and not bug the game", 4562954607, Color3.fromRGB(255, 255, 255), false) -- Title, Icon, Color, IgnoreTheme




local Button = Tab:CreateButton({
    Name = "1", --dive into water
        Callback = function() 
            -- Generated with Sigma Spy Github: https://github.com/depthso/Sigma-Spy
            -- Services
            local ReplicatedStorage = game:GetService("ReplicatedStorage")

            -- Remote
            local Swimming = ReplicatedStorage.Events.Swimming -- RemoteEvent 

            Swimming:FireServer(
                true
            )

        end
})

local Button = Tab:CreateButton({
Name = "2", --Stop diving into water
    Callback = function() 
    -- Services
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

     -- Remote
    local ProcessReturn = ReplicatedStorage.Events.ProcessReturn -- RemoteFunction 

     ProcessReturn:InvokeServer(
        true,
        10000000000000000000000000000000000000000000000000 --100 qintillion
    )


end
})

local Button = Tab:CreateButton({
    Name = "3", --Stop swimming | remove the swimming state
        Callback = function() 
            -- Generated with Sigma Spy Github: https://github.com/depthso/Sigma-Spy
            -- Services
            local ReplicatedStorage = game:GetService("ReplicatedStorage")

            -- Remote
            local Swimming = ReplicatedStorage.Events.Swimming -- RemoteEvent 

            Swimming:FireServer(
                false
            )

        end
})

local Button = Tab:CreateButton({
    Name = "4", --Teleport to the spawn and land on the ground
        Callback = function() 
            -- Services
            local ReplicatedStorage = game:GetService("ReplicatedStorage")

            -- Remote
            local Landing = ReplicatedStorage.Events.Landing -- RemoteEvent 

            Landing:FireServer()

            task.wait(1)
            

            local player2 = game.Players.LocalPlayer
        
           local function teleportPlayer2()
                local character2 = player2.Character or player2.CharacterAdded:Wait()
                local humanoidRootPart2 = character2:FindFirstChild("HumanoidRootPart")
                
                if humanoidRootPart2 then
                    local destination2 = Vector3.new(911.5, -200000.8, 1744.5)
                    humanoidRootPart2.CFrame = CFrame.new(destination2)
                else
                    warn("HumanoidRootPart non trouvé.")
                end
            end

            teleportPlayer2()
        end

    })



local Tab = Window:CreateTab(" ❓ Info")

Tab:CreateLabel("This is a script made by Doug, it is not a copy of any other script, it is made by me and me only", 4562954607, Color3.fromRGB(255, 255, 255), false) -- Title, Icon, Color, IgnoreTheme

local Button = Tab:CreateButton({
   Name = "Join the discord server to get more scripts and updates (click to copy link)",
   Callback = function()
       local link = "https://discord.gg/dZvUNnvKgU"

       -- Copie dans le presse-papiers
       pcall(function()
           setclipboard(link)
       end)

       -- Affiche une notification sympa
        Rayfield:Notify({
            Title = "Notification",
            Content = "The link to the discord server has been copied to your clipboard successfully!",
            Duration = 6.5,
        Image = 4483362458,
        })

       print("Lien Discord copié dans le presse-papiers !")
   end,
})


local Slider = Tab:CreateSlider({
    Name = "🎮 FPS Cap",
    Range = {5, 360}, 
    Increment = 10,
    Suffix = "FPS",
    CurrentValue = 60,
    Flag = "FpsCapSliderss",
    Callback = function(Value)
            setfpscap(Value)

    end,
})




-- Jump Rope Script

elseif game.PlaceId == 123741668193208 then

    --call library

    local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()


    --main window

local Window = Rayfield:CreateWindow({
   Name = "jump rope script",
   Icon = 0, -- Icon in Topbar. Can use Lucide Icons (string) or Roblox Image (number). 0 to use no icon (default).
   LoadingTitle = "loadin",
   LoadingSubtitle = "by Doug",
   ShowText = "hide", -- for mobile users to unhide rayfield, change if you'd like
   Theme = "DarkBlue", -- Check https://docs.sirius.menu/rayfield/configuration/themes

   ToggleUIKeybind = "K", -- The keybind to toggle the UI visibility (string like "K" or Enum.KeyCode)

   DisableRayfieldPrompts = true,
   DisableBuildWarnings = false, -- Prevents Rayfield from warning when the script has a version mismatch with the interface

   ConfigurationSaving = {
      Enabled = true,
      FolderName = nil, -- Create a custom folder for your hub/game
      FileName = "Big Hub"
   },

   Discord = {
      Enabled = true, -- Prompt the user to join your Discord server if their executor supports it
      Invite = "https://discord.gg/dZvUNnvKgU", -- The Discord invite code, do not include discord.gg/. E.g. discord.gg/ ABCD would be ABCD
      RememberJoins = true -- Set this to false to make them join the discord every time they load it up
   },

   KeySystem = false, -- Set this to true to use our key system
   KeySettings = {
      Title = "Untitled",
      Subtitle = "Key System",
      Note = "No method of obtaining the key is provided", -- Use this to tell the user how to get a key
      FileName = "DougKey", -- It is recommended to use something unique as other scripts using Rayfield may overwrite your key file
      SaveKey = true, -- The user's key will be saved, but if you change the key, they will be unable to use your script
      GrabKeyFromSite = false, -- If this is true, set Key below to the RAW site you would like Rayfield to get the key from
      Key = {"Hello"}, -- List of keys that will be accepted by the system, can be RAW file links (pastebin, github etc) or simple strings ("hello","key22")
   },
   
})


local Tab = Window:CreateTab(" 👨‍🌾 Farm")

local iswinenabled = false


local Toggle = Tab:CreateToggle({
   Name = "Instant win",
   CurrentValue = false,
   Flag = "autocashsquidgame", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(Value)

    iswinenabled = Value

    if Value then
        while iswinenabled do
            
            game:GetService("ReplicatedStorage").RestartRemotes.Loader:FireServer(false)
            task.wait(3)
        end
    end
end
})

local isinfinitecashenabled = false

local Toggle = Tab:CreateToggle({
   Name = "Infinite cash (100k every 0.1s)",
   CurrentValue = false,
   Flag = "autocollectsquidgamee", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(Value)

    isinfinitecashenabled = Value

    if Value then
        while isinfinitecashenabled do
            
            game:GetService("ReplicatedStorage").Spin_Remotes.QuintoPremio:FireServer(game:GetService("Players").LocalPlayer)
            task.wait(0.1)
        end
    end
end
})

local Tab = Window:CreateTab(" 😎 Gives")

local Button = Tab:CreateButton({
   Name = "Give supercoil",
   Callback = function()
       -- Generated with Sigma Spy Github: https://github.com/depthso/Sigma-Spy
                -- Services
        local ReplicatedStorage = game:GetService("ReplicatedStorage")

        -- Remote
        local PurchaseShop = ReplicatedStorage.Gamepasses_Remotes.PurchaseShop -- RemoteEvent 

        PurchaseShop:FireServer(
            0,
            "SuperCoil"
        )

   end,
})

local Button = Tab:CreateButton({
   Name = "Give Dragon carpet",
    Callback = function()
        -- Generated with Sigma Spy Github: https://github.com/depthso/Sigma-Spy
        -- Services
        local ReplicatedStorage = game:GetService("ReplicatedStorage")

        -- Remote
        local PurchaseShop = ReplicatedStorage.Gamepasses_Remotes.PurchaseShop -- RemoteEvent 

        PurchaseShop:FireServer(
            0,
            "DragonCarpet"
        )
    end,
})

local Button = Tab:CreateButton({
   Name = "Give Quantum slap (OP)",
    Callback = function()
        -- Generated with Sigma Spy Github: https://github.com/depthso/Sigma-Spy
        -- Services
        local ReplicatedStorage = game:GetService('ReplicatedStorage')

        -- Remote
        local GiveReward = ReplicatedStorage.CratesUtilities.Remotes.GiveReward -- RemoteEvent

        GiveReward:FireServer('Quantum')
    end,
})

local Button = Tab:CreateButton({
   Name = "Give galactic gun (OP)",
    Callback = function()
        -- Generated with Sigma Spy Github: https://github.com/depthso/Sigma-Spy
        -- Services
        local ReplicatedStorage = game:GetService('ReplicatedStorage')

        -- Remote
        local GiveReward = ReplicatedStorage.CratesUtilities.Remotes.GiveReward -- RemoteEvent

        GiveReward:FireServer('Gun')
    end,
})

local Button = Tab:CreateButton({
   Name = "Give space carpet (OP)",
    Callback = function()
        -- Generated with Sigma Spy Github: https://github.com/depthso/Sigma-Spy
        -- Services
        local ReplicatedStorage = game:GetService('ReplicatedStorage')

        -- Remote
        local GiveReward = ReplicatedStorage.CratesUtilities.Remotes.GiveReward -- RemoteEvent

        GiveReward:FireServer('Space')
    end,
})

local Button = Tab:CreateButton({
   Name = "Give Frontman",
    Callback = function()
        -- Generated with Sigma Spy Github: https://github.com/depthso/Sigma-Spy
        -- Services
        local ReplicatedStorage = game:GetService("ReplicatedStorage")

        -- Remote
        local PurchaseShop = ReplicatedStorage.Gamepasses_Remotes.PurchaseShop -- RemoteEvent 

        PurchaseShop:FireServer(
            0,
            "Frontman"
        )
    end,
})



local Tab = Window:CreateTab(" 🔴🟢 Rope")

Tab:CreateLabel("The max speed rope might not work if people are at the end of the stage modifing the speed.", 4562954607, Color3.fromRGB(255, 255, 255), false) -- Title, Icon, Color, IgnoreTheme

local Bouton = Tab:CreateButton({
   Name = "max speed rope",
   Callback = function()
        -- Generated with Sigma Spy Github: https://github.com/depthso/Sigma-Spy
        -- Services
        local ReplicatedStorage = game:GetService("ReplicatedStorage")

        -- Remote
        local red = ReplicatedStorage.Frontman_Remotes.red -- RemoteEvent 

        red:FireServer()
   end,
})

local Button = Tab:CreateButton({
   Name = "Stop rope",
   Callback = function()
        -- Generated with Sigma Spy Github: https://github.com/depthso/Sigma-Spy
        -- Services
        local ReplicatedStorage = game:GetService("ReplicatedStorage")

        -- Remote
        local green = ReplicatedStorage.Frontman_Remotes.green -- RemoteEvent 

        green:FireServer()
    end,
})


local Tab = Window:CreateTab(" ❓ Info")

Tab:CreateLabel("This is a script made by Doug, it is not a copy of any other script, it is made by me and me only.", 4562954607, Color3.fromRGB(255, 255, 255), false) -- Title, Icon, Color, IgnoreTheme

local Button = Tab:CreateButton({
   Name = "Join the discord server to get more scripts and updates (click to copy link)",
   Callback = function()
       local link = "https://discord.gg/dZvUNnvKgU"

       -- Copie dans le presse-papiers
       pcall(function()
           setclipboard(link)
       end)

       -- Affiche une notification sympa
        Rayfield:Notify({
            Title = "Notification",
            Content = "The link to the discord server has been copied to your clipboard successfully!",
            Duration = 6.5,
        Image = 4483362458,
        })

       print("Lien Discord copié dans le presse-papiers !")
    end,
})


local Slider = Tab:CreateSlider({
    Name = "FPS Cap",
    Range = {5, 360}, -- Tu peux adapter le max si tu veux (240, 1000, etc.)
    Increment = 10,
    Suffix = "FPS",
    CurrentValue = 60,
    Flag = "FpsCapSlider",
    Callback = function(Value)
            setfpscap(Value)
    end,
})


end


--Every Second You Get +1 WalkSpeed

if game.PlaceId == 12742233841 then

    --call library

    local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()


    --main window

local Window = Rayfield:CreateWindow({
   Name = "Speed every second script",
   Icon = 0, -- Icon in Topbar. Can use Lucide Icons (string) or Roblox Image (number). 0 to use no icon (default).
   LoadingTitle = "loadin",
   LoadingSubtitle = "by Doug",
   ShowText = "hide", -- for mobile users to unhide rayfield, change if you'd like
   Theme = "DarkBlue", -- Check https://docs.sirius.menu/rayfield/configuration/themes

   ToggleUIKeybind = "K", -- The keybind to toggle the UI visibility (string like "K" or Enum.KeyCode)

   DisableRayfieldPrompts = true,
   DisableBuildWarnings = false, -- Prevents Rayfield from warning when the script has a version mismatch with the interface

   ConfigurationSaving = {
      Enabled = true,
      FolderName = nil, -- Create a custom folder for your hub/game
      FileName = "Big Hub"
   },

   Discord = {
      Enabled = true, -- Prompt the user to join your Discord server if their executor supports it
      Invite = "https://discord.gg/dZvUNnvKgU", -- The Discord invite code, do not include discord.gg/. E.g. discord.gg/ ABCD would be ABCD
      RememberJoins = true -- Set this to false to make them join the discord every time they load it up
   },

   KeySystem = false, -- Set this to true to use our key system
   KeySettings = {
      Title = "Untitled",
      Subtitle = "Key System",
      Note = "No method of obtaining the key is provided", -- Use this to tell the user how to get a key
      FileName = "DougKey", -- It is recommended to use something unique as other scripts using Rayfield may overwrite your key file
      SaveKey = true, -- The user's key will be saved, but if you change the key, they will be unable to use your script
      GrabKeyFromSite = false, -- If this is true, set Key below to the RAW site you would like Rayfield to get the key from
      Key = {"Hello"}, -- List of keys that will be accepted by the system, can be RAW file links (pastebin, github etc) or simple strings ("hello","key22")
   },
   
})



local Tab = Window:CreateTab(" 👨‍🌾 Farm")

--local var
local autorebirth = false
local autowin = false

-- Variable pour stocker le nom de la zone sélectionnée
local selectedZoneName = nil

-- Dropdown

Tab:CreateLabel("In order for the win to work you need to have the required win for the zone", 4562954607, Color3.fromRGB(255, 255, 255), false) -- Title, Icon, Color, IgnoreTheme
Tab:CreateLabel("Moon (10wins), Lava (20wins), Ice (30wins), Flower (50wins), Snow (100wins), Dark (250wins), Void (500wins)", 4562954607, Color3.fromRGB(255, 255, 255), false) -- Title, Icon, Color, IgnoreTheme
Tab:CreateLabel("Desert (100wins),Steampunk (1000wins),Forest (2000wins),Heaven (3000wins),Candy (6000wins),Hell (10000wins)", 4562954607, Color3.fromRGB(255, 255, 255), false) -- Title, Icon, Color, IgnoreTheme

local Dropdown = Tab:CreateDropdown({
    Name = "Zones",
    Options = {"Earth","Moon","Lava","Ice","Flower","Snow","Dark","Void","Desert","Steampunk","Forest","Heaven","Candy","Hell"},
    CurrentOption = "Choose a zone",
    MultipleOptions = false,
    Flag = "ZonePlusOneSpeedPerSecondGame",
    Callback = function(selected)
        if typeof(selected) == "table" and typeof(selected[1]) == "string" then
            selectedZoneName = selected[1]
            print("✅ L'utilisateur a choisi la zone : " .. selectedZoneName)
        else
            warn("❌ Callback invalide. Type : " .. typeof(selected))
        end
    end,
})


-- Bouton qui déclenche le firetouchinterest()



local Button = Tab:CreateToggle({
    Name = "Auto Win",
    CurrentValue = false,
    Flag = "onesecondplusgameautowin",
    Callback = function(Value)
    autowin = Value
        while autowin do
            if not selectedZoneName then
                warn("❌ Aucune zone sélectionnée !")
                return
            end

            local part = game.Workspace.Wins:FindFirstChild(selectedZoneName)
            if not part then
                warn("❌ Impossible de trouver la partie : " .. selectedZoneName)
                return
            end

            local player = game.Players.LocalPlayer
            local character = player and player.Character
            if not character then
                warn("❌ Personnage non trouvé !")
                return
            end

            local hrp = character:FindFirstChildWhichIsA("BasePart")
            if not hrp then
                warn("❌ BasePart (HRP) non trouvé !")
                return
            end

            -- Action tip top !
            firetouchinterest(part, hrp, 0)
            task.wait()
            firetouchinterest(part, hrp, 1)

            print("🔥 Touch simulé avec la zone : " .. selectedZoneName)
            task.wait(4) -- Attendre 0.5 secondes avant de faire la prochaine action
        end
    end,
})


local Toggle = Tab:CreateToggle({   
    Name = "Auto rebirth",
    CurrentValue = false,
    Flag = "onesecondplusgame",
    Callback = function(Value)
        autorebirth = Value

        while autorebirth do
            -- Generated with Sigma Spy Github: https://github.com/depthso/Sigma-Spy
            -- Services
            local ReplicatedStorage = game:GetService("ReplicatedStorage")

            -- Remote
            local RebirthEvent = ReplicatedStorage.RebirthEvent -- RemoteEvent 

            RebirthEvent:FireServer()
            task.wait(0.5) -- Attendre 1 seconde avant de faire la prochaine action
        end
    end
})

local Tab = Window:CreateTab(" ❓ Info")

Tab:CreateLabel("This is a script made by Doug, it is not a copy of any other script, it is made by me and me only.", 4562954607, Color3.fromRGB(255, 255, 255), false) -- Title, Icon, Color, IgnoreTheme

local Button = Tab:CreateButton({
   Name = "Join the discord server to get more scripts and updates (click to copy link)",
   Callback = function()
       local link = "https://discord.gg/dZvUNnvKgU"

       -- Copie dans le presse-papiers
       pcall(function()
           setclipboard(link)
       end)

       -- Affiche une notification sympa
        Rayfield:Notify({
            Title = "Notification",
            Content = "The link to the discord server has been copied to your clipboard successfully!",
            Duration = 6.5,
        Image = 4483362458,
        })

       print("Lien Discord copié dans le presse-papiers !")
    end,
})


local Slider = Tab:CreateSlider({
    Name = "FPS Cap",
    Range = {5, 360}, -- Tu peux adapter le max si tu veux (240, 1000, etc.)
    Increment = 10,
    Suffix = "FPS",
    CurrentValue = 60,
    Flag = "FpsCapSlider",
    Callback = function(Value)
            setfpscap(Value)
    end,
})
end



if game.PlaceId == 137925884276740 then
    -- EclipseUI port of your linoria.lua (Build a Plane) — by Doug
-- Requires EclipseUI.lua (v9.0+ with AddInput) to be loadstring'd below

if game.PlaceId ~= 137925884276740 then return end

-- === Load EclipseUI ===
local Eclipse = loadstring(game:HttpGet(
  "https://raw.githubusercontent.com/vegetoku256/Dougyshub/refs/heads/main/EclipseUI.lua"
))()

-- === Safe globals / connections ===
getgenv()._hubConnections = (type(getgenv()._hubConnections) == 'table') and getgenv()._hubConnections or {}
local function safeInsert(t, v) if type(t) == 'table' and v ~= nil then table.insert(t, v) end end

-- Services
local Players     = game:GetService("Players")
local RS          = game:GetService("ReplicatedStorage")
local RunService  = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Player      = Players.LocalPlayer

-- Shop data
local shopItems = {
  "block_1","wing_1","fuel_1","propeller_1","seat_1",
  "block_reinforced","half_block","fuel_2","tail_1","wing_2",
  "block_metal","fuel_3","propeller_2","balloon","tail_2",
  "wing_3","landing_gear","fuel_refined",
  "boost_1","missile_1","propeller_4","boost_2","shield"
}
local shopDisplay = {
  "Block","Wing","Fuel can","Propeller","Seat",
  "Reinforced Block","Half Block","Better Fuel","Tail","Better Wing",
  "Metal Block","Barrel Fuel","Better Propeller","Ballon Deployer","Better Tail",
  "Delta Wing","Landing Gears","Refined Fuel",
  "Rocket Booster","Missile","Helicopter Propeller","Plasma Booster","Energy Shield"
}

-- Remotes
local BuyBlock = RS.Remotes.ShopEvents.BuyBlock
local Launch   = RS.Remotes.LaunchEvents.Launch
local ReturnEv = RS.Remotes.LaunchEvents.Return

-- === Window ===
local ui = Eclipse:CreateWindow({
  Title = "Build a Plane • Doug",
  ToggleKey = Enum.KeyCode.RightShift, -- also changeable in Settings tab of the lib
  Size = UDim2.fromOffset(760, 480),
  NotifyDock = { mode = "window-right", align = "title", offsetY = 0, gap = 12, width = 280 }
})

-- Tabs
local Farm      = ui:AddTab("Farm")
local EclipseT  = ui:AddTab("Event currency")
local Shop      = ui:AddTab("Shop")
local AutoBuy   = ui:AddTab("Buy")
local Info      = ui:AddTab("Info")

-- Helper: wrapped paragraph label
local function AddWrappedText(section, text, approxCharsPerLine)
  approxCharsPerLine = approxCharsPerLine or 46
  local line = ""
  for word in tostring(text):gmatch("%S+") do
    if #line + #word + 1 > approxCharsPerLine then
      section:AddLabel(line)
      line = word
    else
      line = (line == "" and word) or (line .. " " .. word)
    end
  end
  if #line > 0 then section:AddLabel(line) end
end

--=== Build a Plane : Auto Aurora Collect ================================

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Remote (sera nil si le jeu n'a pas cet objet)
local AuroraCollect = ReplicatedStorage:FindFirstChild("Remotes")
    and ReplicatedStorage.Remotes:FindFirstChild("UIEvents")
    and ReplicatedStorage.Remotes.UIEvents:FindFirstChild("AuroraCollect")

-- Espace global partagé (même style que tes autres workers)
getgenv()._hubFlags      = getgenv()._hubFlags      or {}
getgenv()._hubTasks      = getgenv()._hubTasks      or {}
getgenv()._hubConnections= getgenv()._hubConnections or {} -- si tu l'utilises déjà pour le cleanup

-- Flag de contrôle
getgenv()._hubFlags.AutoAuroraCollect = getgenv()._hubFlags.AutoAuroraCollect or false

-- Fonction: lance la boucle si pas déjà en cours
local function startAuroraCollector()
    if getgenv()._hubTasks.AuroraCollector then return end
    if not AuroraCollect or not AuroraCollect.FireServer then
        warn("[AuroraCollector] Remote introuvable: ReplicatedStorage.Remotes.UIEvents.AuroraCollect")
        return
    end

    getgenv()._hubTasks.AuroraCollector = task.spawn(function()
        -- intervalle par défaut (ajoute un léger jitter pour éviter les patterns)
        local baseDelay = 2.0

        while getgenv()._hubFlags.AutoAuroraCollect do
            -- FireServer sécurisé
            pcall(function()
                AuroraCollect:FireServer()
            end)

            -- petit jitter pour faire “humain” et éviter le throttle serveur
            local jitter = (math.random(5, 20) / 100) -- 0.05 à 0.20s
            task.wait(baseDelay + jitter)
        end

        -- fin de boucle -> clear la ref
        getgenv()._hubTasks.AuroraCollector = nil
    end)
end

-- Fonction: stop propre
local function stopAuroraCollector()
    getgenv()._hubFlags.AutoAuroraCollect = false
    -- la boucle s'arrête d'elle-même et remettra _hubTasks.AuroraCollector à nil
end

-- Si tu as déjà un BindToClose global, ça suffit. Si tu veux être extra-safe:
if game and game.BindToClose then
    -- (Déjà dans ton projet, tu as un cleanup global. Ici rien à ajouter)
end

-- Expose pour l’UI (pour pouvoir l’appeler depuis le toggle)
getgenv()._hub_AuroraCollector = {
    start = startAuroraCollector,
    stop  = stopAuroraCollector
}
--=======================================================================


-- =========================
-- TAB: FARM
-- =========================
local G_FarmL = Farm:AddLeftSection("Auto Launch & TP")
local G_FarmR = Farm:AddRightSection("Presets")
local G_FarmM = Farm:AddRightSection("test")

local autoTpActive = false
local autoTpDistance, tpSpeed, tpStep = 50000, 50000, 0.001

G_FarmL:AddSlider({
  id="TpDistance", text="Teleport Distance", min=1000, max=105000, default=autoTpDistance, rounding=0, suffix=" studs",
  fullWidth=true,
  callback=function(v) autoTpDistance = v end
})
G_FarmL:AddSlider({
  id="TpSpeed", text="TP Speed", min=1000, max=200000, default=tpSpeed, rounding=0, suffix=" studs/s",
  fullWidth=true,
  callback=function(v) tpSpeed = v end
})
G_FarmL:AddSlider({
  id = "TpStep",
  text = "TP Step Interval",
  min = 0.0001, max = 0.05,
  default = tpStep,
  rounding = 4, suffix = " s",
  step = 0.0001,            -- ✅ add this line
  fullWidth = true,
  callback = function(v) tpStep = v end
})


G_FarmL:AddToggle({
  id="AutoTpToggle", text="Auto launch + TP", default=false,
  tooltip="Launches then teleports your plane to the chosen distance.",
  fullWidth=true,
  callback=function(active)
    autoTpActive = active
    if active then
      task.spawn(function()
        while autoTpActive do
          local C = Player.Character or Player.CharacterAdded:Wait()
          local R = C:WaitForChild("HumanoidRootPart")
          local safeHeight, minHeight = 600, 500
          local startX = R.Position.X
          local targetX = startX + autoTpDistance

          Launch:FireServer(); task.wait(0.25)
          R.CFrame = CFrame.new(startX, R.Position.Y + safeHeight, R.Position.Z)

          while autoTpActive do
            local cur = R.Position
            local left = targetX - cur.X
            if math.abs(left) <= 5 then break end
            local dir = Vector3.new((left > 0) and 1 or -1, 0, 0)
            local move = tpSpeed * tpStep
            if cur.Y < minHeight then
              R.CFrame = CFrame.new(cur.X, cur.Y + safeHeight, cur.Z)
            else
              R.CFrame = R.CFrame + dir * move
            end
            task.wait(tpStep)
          end

          ReturnEv:FireServer()
          task.wait(2)
        end
      end)
    end
  end
})

local teleporting = false
local function presetRunner(speed, step, timeout, targetX)
  return function(active)
    teleporting = active
    if active then
      task.spawn(function()
        while teleporting do
          local C = Player.Character or Player.CharacterAdded:Wait()
          local R = C:WaitForChild("HumanoidRootPart")
          local safeHeight, minHeight = 600, 500

          Launch:FireServer(); task.wait(0.25)
          local startPos = R.Position
          local targetPos = Vector3.new(targetX, startPos.Y, startPos.Z)
          R.CFrame = CFrame.new(startPos.X, startPos.Y + safeHeight, startPos.Z)

          local t0 = os.clock()
          while os.clock() - t0 < timeout and teleporting do
            local cur = R.Position
            local dist = (targetPos - cur).Magnitude
            local movePer = speed * step
            if dist <= movePer then R.CFrame = CFrame.new(targetPos) break end
            if cur.Y < minHeight then
              R.CFrame = CFrame.new(cur.X, cur.Y + safeHeight, cur.Z)
            else
              R.CFrame = R.CFrame + ((targetPos - cur).Unit * movePer)
            end
            task.wait(step)
          end

          ReturnEv:FireServer()
          R.CFrame = CFrame.new(startPos)
          task.wait(2)
        end
      end)
    else
      ReturnEv:FireServer()
    end
  end
end

G_FarmR:AddToggle({
  id="PresetFast", text="Fast farm", default=false,
  tooltip="~1.6k per 10s (FPS dependent; ~120 FPS is ideal).",
  fullWidth=true,
  callback=presetRunner(50000, 0.001, 9.5, 49950)
})
G_FarmR:AddToggle({
  id="PresetSlow", text="Slow farm", default=false,
  tooltip="~1k per 10s (more stable for low-end PCs).",
  fullWidth=true,
  callback=presetRunner(5000, 0.01, 8, 49960)
})

-- =========================
-- TAB: ECLIPSE
-- =========================
local G_EclipseL = EclipseT:AddLeftSection("Overlay (WIP)")
local G_EclipseR = EclipseT:AddRightSection("Aurora")


-- === Build a Plane • Auto Aurora (fast) — clone du “Auto Eclipse dust (fast)” ===
do
  local RS         = game:GetService("ReplicatedStorage")
  local RunService = game:GetService("RunService")

  -- Remote Aurora
  local AuroraCollect = RS:FindFirstChild("Remotes")
      and RS.Remotes:FindFirstChild("UIEvents")
      and RS.Remotes.UIEvents:FindFirstChild("AuroraCollect")

  -- Action unitaire (équiv. de spawnAndKillOnce mais pour Aurora)
  local function auroraOnce()
    if AuroraCollect and AuroraCollect.FireServer then
      pcall(function() AuroraCollect:FireServer() end)
    end
  end

  -- Même toggle factory que “Auto Eclipse dust (fast)”
  local function makeBurstToggle(section, id, text, WORKERS, INNER_BURST, FRAME_BURST)
    local running, runId, connections = false, 0, {}
    local function disconnectAll()
      for i, c in ipairs(connections) do if c and c.Disconnect then c:Disconnect() end connections[i] = nil end
    end
    section:AddToggle({
      id = id, text = text, default = false, fullWidth = true,
      callback = function(state)
        if state then
          runId += 1; local myRun = runId; running = true
          -- threads workers
          for w = 1, WORKERS do
            task.spawn(function()
              while running and runId == myRun do
                for j = 1, INNER_BURST do
                  if not running or runId ~= myRun then break end
                  auroraOnce()
                end
                if running and runId == myRun then task.wait() end
              end
            end)
          end
          -- burst par frame
          if FRAME_BURST > 0 then
            local c; c = RunService.RenderStepped:Connect(function()
              if not running or runId ~= myRun then if c then c:Disconnect() end return end
              for i = 1, FRAME_BURST do
                if not running or runId ~= myRun then break end
                auroraOnce()
              end
            end)
            table.insert(connections, c)
          end
        else
          running = false; runId += 1; disconnectAll()
        end
      end
    })
  end

  -- ➜ mêmes paramètres que “Auto Eclipse dust (fast)”: 16, 8, 60
  makeBurstToggle(G_EclipseR, "AuroraFast", "Auto Aurora (fast)", 16, 8, 60)
end

-- === Build a Plane • Auto Aurora (slow) ===
do
    local RS = game:GetService("ReplicatedStorage")
    local AuroraCollect = RS:FindFirstChild("Remotes")
        and RS.Remotes:FindFirstChild("UIEvents")
        and RS.Remotes.UIEvents:FindFirstChild("AuroraCollect")

    local running = false

    G_EclipseR:AddToggle({
        id = "AuroraSlow",
        text = "Auto Aurora (slow)",
        default = false,
        fullWidth = true,
        tooltip = "Collect one aurora every 0.1s for a low CPU usage.",
        callback = function(state)
            running = state
            if state then
                task.spawn(function()
                    while running do
                        if AuroraCollect and AuroraCollect.FireServer then
                            pcall(function() AuroraCollect:FireServer() end)
                        end
                        task.wait(0.1)
                    end
                end)
            end
        end
    })
end


do
  local blackScreenGui, updateConnection
  local toggleHandle -- EclipseUI toggle handle (has :Set)

  local function destroyOverlay()
    if blackScreenGui then blackScreenGui:Destroy(); blackScreenGui = nil end
    if updateConnection then updateConnection:Disconnect(); updateConnection = nil end
  end

  toggleHandle = G_EclipseL:AddToggle({
    id="BlackScreen", text="Black Screen", default=false,
    tooltip="Full screen overlay showing Cash & Bloodcoins.",
    fullWidth=true,
    callback=function(state)
      if state then
        blackScreenGui = Instance.new("ScreenGui")
        blackScreenGui.Name = "BlackScreenGui"
        blackScreenGui.IgnoreGuiInset = true
        blackScreenGui.ResetOnSpawn = false
        blackScreenGui.Parent = game.CoreGui

        local blackFrame = Instance.new("Frame")
        blackFrame.Size = UDim2.new(1,0,1,0)
        blackFrame.BackgroundColor3 = Color3.new(0,0,0)
        blackFrame.BorderSizePixel = 0
        blackFrame.ZIndex = 9999
        blackFrame.Parent = blackScreenGui

        local cashLabel = Instance.new("TextLabel")
        cashLabel.Size = UDim2.new(1,0,0,50)
        cashLabel.Position = UDim2.new(0,0,0.45,-25)
        cashLabel.BackgroundTransparency = 1
        cashLabel.TextColor3 = Color3.new(0,1,0)
        cashLabel.Font = Enum.Font.GothamBold
        cashLabel.TextScaled = true
        cashLabel.ZIndex = 10000
        cashLabel.Parent = blackScreenGui

        local bloodLabel = Instance.new("TextLabel")
        bloodLabel.Size = UDim2.new(1,0,0,50)
        bloodLabel.Position = UDim2.new(0,0,0.5,25)
        bloodLabel.BackgroundTransparency = 1
        bloodLabel.TextColor3 = Color3.new(1,0,0)
        bloodLabel.Font = Enum.Font.GothamBold
        bloodLabel.TextScaled = true
        bloodLabel.ZIndex = 10000
        bloodLabel.Parent = blackScreenGui

        local closeBtn = Instance.new("TextButton")
        closeBtn.Name = "CloseOverlay"
        closeBtn.AnchorPoint = Vector2.new(0.5,0)
        closeBtn.Position = UDim2.new(0.5,0,0.62,0)
        closeBtn.Size = UDim2.new(0,220,0,38)
        closeBtn.BackgroundColor3 = Color3.fromRGB(35,35,35)
        closeBtn.BorderSizePixel = 0
        closeBtn.AutoButtonColor = true
        closeBtn.Text = "Close overlay"
        closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
        closeBtn.Font = Enum.Font.GothamBold
        closeBtn.TextSize = 18
        closeBtn.ZIndex = 10001
        closeBtn.Parent = blackScreenGui

        closeBtn.MouseButton1Click:Connect(function()
          destroyOverlay()
          if toggleHandle and toggleHandle.Set then toggleHandle:Set(false) end
        end)

        updateConnection = RunService.RenderStepped:Connect(function()
          local cash, blood = "?", "?"
          local ls = Player:FindFirstChild("leaderstats")
          if ls and ls:FindFirstChild("Cash") then cash = ls.Cash.Value end
          local imp = Player:FindFirstChild("Important")
          if imp and imp:FindFirstChild("RedMoons") then blood = imp.RedMoons.Value end
          cashLabel.Text  = "💰 Cash: " .. tostring(cash)
          bloodLabel.Text = "🩸 Bloodcoins: " .. tostring(blood)
        end)
      else
        destroyOverlay()
      end
    end
  })
end






-- -- Evil Eye farming
-- local EventsRoot   = RS:WaitForChild("Remotes"):WaitForChild("EventEvents")
-- local spawnEvilEye = EventsRoot:FindFirstChild("SpawnEvilEye")
-- local killEvilEye  = EventsRoot:FindFirstChild("KillEvilEye")
-- local isSpawnRF    = spawnEvilEye and spawnEvilEye:IsA("RemoteFunction")
-- local isKillRF     = killEvilEye  and killEvilEye:IsA("RemoteFunction")

-- local function spawnAndKillOnce()
--   if not (spawnEvilEye and killEvilEye) then return end
--   if isSpawnRF then
--     local ok, token = pcall(function() return spawnEvilEye:InvokeServer() end)
--     if ok then
--       if isKillRF then pcall(function() killEvilEye:InvokeServer(token) end)
--       else pcall(function() killEvilEye:FireServer(token) end) end
--     else
--       if isKillRF then pcall(function() killEvilEye:InvokeServer() end)
--       else pcall(function() killEvilEye:FireServer() end) end
--     end
--   else
--     spawnEvilEye:FireServer(); killEvilEye:FireServer()
--   end
-- end

-- local function makeEclipseToggle(section, id, text, WORKERS, INNER_BURST, FRAME_BURST)
--   local running, runId, connections = false, 0, {}
--   local function disconnectAll()
--     for i, c in ipairs(connections) do if c and c.Disconnect then c:Disconnect() end connections[i] = nil end
--   end
--   section:AddToggle({
--     id = id, text = text, default = false, fullWidth=true,
--     callback = function(state)
--       if state then
--         runId += 1; local myRun = runId; running = true
--         for w=1, WORKERS do
--           task.spawn(function()
--             while running and runId == myRun do
--               for j=1, INNER_BURST do if not running or runId ~= myRun then break end spawnAndKillOnce() end
--               if running and runId == myRun then task.wait() end
--             end
--           end)
--         end
--         if FRAME_BURST > 0 then
--           local c; c = RunService.RenderStepped:Connect(function()
--             if not running or runId ~= myRun then if c then c:Disconnect() end return end
--             for i=1, FRAME_BURST do if not running or runId ~= myRun then break end spawnAndKillOnce() end
--           end)
--           table.insert(connections, c)
--         end
--       else
--         running = false; runId += 1; disconnectAll()
--       end
--     end
--   })
-- end

-- makeEclipseToggle(G_EclipseR, "EclipseFast", "Auto Eclipse dust (fast)", 16, 8, 60)
-- makeEclipseToggle(G_EclipseR, "EclipseSlow", "Eclipse dust (slow)",      1,  1, 4)



G_EclipseR:AddDivider()

-- Auto Spin (ported from linoria.lua)
do
  local RS = game:GetService("ReplicatedStorage")
  local RunService = game:GetService("RunService")
  local SpinRoot = RS:WaitForChild("Remotes"):WaitForChild("SpinEvents")
  local PurchaseSpin = SpinRoot:FindFirstChild("PurchaseSpin")
  local PerformSpin  = SpinRoot:FindFirstChild("PerformSpin")
  local isPurchaseRF = PurchaseSpin and PurchaseSpin:IsA("RemoteFunction")
  local isPerformRF  = PerformSpin  and PerformSpin:IsA("RemoteFunction")

  local function spinOnce()
    if not (PurchaseSpin and PerformSpin) then return end
    if isPurchaseRF then
      local ok, token = pcall(function() return PurchaseSpin:InvokeServer() end)
      if ok then
        if isPerformRF then pcall(function() PerformSpin:InvokeServer(token) end)
        else pcall(function() PerformSpin:FireServer(token) end) end
      else
        if isPerformRF then pcall(function() PerformSpin:InvokeServer() end)
        else pcall(function() PerformSpin:FireServer() end) end
      end
    else
      PurchaseSpin:FireServer(); PerformSpin:FireServer()
    end
  end

  local running, runId, frameConn
  G_EclipseR:AddToggle({
    id = "AutoSpin",
    text = "Auto spin",
    default = false,
    fullWidth = true,
    callback = function(active)
      if active then
        runId = (runId or 0) + 1
        local my = runId
        running = true
        -- burst per frame
        frameConn = RunService.RenderStepped:Connect(function()
          if not running or runId ~= my then if frameConn then frameConn:Disconnect() end return end
          for i = 1, 30 do  -- frame burst
            if not running or runId ~= my then break end
            spinOnce()
          end
        end)
      else
        running = false
        runId = (runId or 0) + 1
        if frameConn then frameConn:Disconnect(); frameConn = nil end
      end
    end
  })
end

G_EclipseR:AddDivider()
G_EclipseR:AddButton({ text="Open Crafts", fullWidth=true, callback=function()
  local pg = Player.PlayerGui
  local ui2 = pg:FindFirstChild("Main") and pg.Main:FindFirstChild("Crafting")
  if ui2 then ui2.Visible = true ui2.Active = true end
end })
G_EclipseR:AddButton({ text="Close Crafts", fullWidth=true, callback=function()
  local pg = Player.PlayerGui
  local ui2 = pg:FindFirstChild("Main") and pg.Main:FindFirstChild("Crafting")
  if ui2 then ui2.Visible = false ui2.Active = false end
end })


-- =========================
-- TAB: SHOP
-- =========================
local G_ShopL = Shop:AddLeftSection("Webhook Stock")
local G_ShopR = Shop:AddRightSection("Shop UI")

local webhookURL = nil
local importantFolder = Player:WaitForChild("Important", 10)
local stockFolder     = importantFolder and importantFolder:WaitForChild("StockAvailable", 10)
local requestFunction = (syn and syn.request) or (http and http.request) or (http_request) or (request)

local function sendStockEmbed()
  if not requestFunction then ui:Notify("No HTTP support in your executor.", 3); return end
  if not webhookURL or webhookURL == "" then ui:Notify("Set a webhook URL first.", 3); return end
  if not stockFolder then ui:Notify("Stock folder not found.", 3); return end

  local fields = {}
  for i,id in ipairs(shopItems) do
    local val = 0
    local inst = stockFolder:FindFirstChild(id)
    if inst and inst:IsA("ValueBase") then val = inst.Value end
    table.insert(fields, { name = shopDisplay[i] or id, value = tostring(val), inline = true })
  end

  local payload = HttpService:JSONEncode({
    embeds = {{
      title = "**Current Shop Stock**",
      description = "Use AutoBuy toggles to purchase automatically.",
      color = 0x00ff99,
      fields = fields,
      footer = { text = "Doug's hub Stock Tracker" },
      timestamp = DateTime.now():ToIsoDate()
    }}
  })
  requestFunction({ Url = webhookURL, Method = "POST", Headers = {["Content-Type"]="application/json"}, Body = payload })
  ui:Notify("Stock sent to webhook!", 3)
end

G_ShopL:AddInput({
  text = "Webhook URL",
  placeholder = "https://discord.com/api/webhooks/...",
  fullWidth = true,
  callback = function(text) webhookURL = text end
})
G_ShopL:AddButton({ text="Send current stock", fullWidth=true, callback=sendStockEmbed })
do
  local autoSend = false
  G_ShopL:AddToggle({
    id="AutoSendStock", text="Auto send (2.5 min)", default=false, fullWidth=true,
    callback=function(active)
      autoSend = active
      if active then
        task.spawn(function()
          while autoSend do sendStockEmbed(); task.wait(150) end
        end)
      end
    end
  })
end

G_ShopR:AddButton({ text="Open shop", fullWidth=true, callback=function()
  local ui2 = Player.PlayerGui:WaitForChild("Main"):WaitForChild("BlockShop"); ui2.Visible = true
end })
G_ShopR:AddButton({ text="Close shop", fullWidth=true, callback=function()
  local ui2 = Player.PlayerGui:WaitForChild("Main"):WaitForChild("BlockShop"); ui2.Visible = false
end })
G_ShopR:AddDivider()
G_ShopR:AddButton({ text="Open tools shop", fullWidth=true, callback=function()
  local ts = Player.PlayerGui:WaitForChild("Main"):WaitForChild("ToolShop"); ts.Visible = true
end })
G_ShopR:AddButton({ text="Close tools shop", fullWidth=true, callback=function()
  local ts = Player.PlayerGui:WaitForChild("Main"):WaitForChild("ToolShop"); ts.Visible = false
end })

-- =========================
-- TAB: AUTOBUY
-- =========================
local G_BuyLeft  = AutoBuy:AddLeftSection("Items")
local G_BuyRight = AutoBuy:AddRightSection("Bulk")

local buyingStates = {}
local handles = {}

for _, id in ipairs(shopItems) do buyingStates[id] = false end

local function safeSetToggle(handle, state)
  if type(handle) == "table" and handle.Set then handle:Set(state) end
end

G_BuyRight:AddButton({ text="🧹 Clear All", fullWidth=true, callback=function()
  for id, h in pairs(handles) do buyingStates[id] = false; safeSetToggle(h, false) end
  ui:Notify("All auto-buy toggles cleared.", 3)
end })

G_BuyRight:AddButton({ text="Auto Buy All", fullWidth=true, callback=function()
  for id, h in pairs(handles) do buyingStates[id] = true; safeSetToggle(h, true) end
  ui:Notify("All auto-buys set to ON.", 3)
end })

for i, id in ipairs(shopItems) do
  local label = ("Auto-buy: %s"):format(shopDisplay[i] or id)
  handles[id] = G_BuyLeft:AddToggle({
    id = "BUY_"..id, text = label, default = false, fullWidth=true,
    callback = function(active)
      buyingStates[id] = active
      if active then
        task.spawn(function()
          while buyingStates[id] do
            BuyBlock:FireServer(id)
            task.wait(0.5)
          end
        end)
      end
    end
  })
end

-- =========================
-- TAB: INFO
-- =========================
local G_Info = Info:AddLeftSection("About")
AddWrappedText(G_Info, "Script made by Doug. This is not a copy of any other script | created by me only.", 36)
G_Info:AddButton({
  text="Copy Discord invite", fullWidth=true,
  callback=function()
    local link = "https://discord.gg/dZvUNnvKgU"
    pcall(function() setclipboard(link) end)
    ui:Notify("Discord link copied to clipboard.", 4)
  end
})


-- cleanup
local conns = getgenv()._hubConnections or {}
if ui and ui.Instance then
  ui.Instance.Destroying:Connect(function()
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
  end)
end


ui:Notify("EclipseUI version loaded for Build a Plane ✈️", 4)

end



--steal to be rich script
if game.PlaceId == 121807678075780 then

    --call library

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

    --main window

local Window = Rayfield:CreateWindow({
   Name = "Steal to be rich script",
   Icon = 0, -- Icon in Topbar. Can use Lucide Icons (string) or Roblox Image (number). 0 to use no icon (default).
   LoadingTitle = "loadin",
   LoadingSubtitle = "by Doug",
   ShowText = "hide", -- for mobile users to unhide rayfield, change if you'd like
   Theme = "DarkBlue", -- Check https://docs.sirius.menu/rayfield/configuration/themes

   ToggleUIKeybind = "K", -- The keybind to toggle the UI visibility (string like "K" or Enum.KeyCode)

   DisableRayfieldPrompts = true,
   DisableBuildWarnings = false, -- Prevents Rayfield from warning when the script has a version mismatch with the interface

   ConfigurationSaving = {
      Enabled = true,
      FolderName = nil, -- Create a custom folder for your hub/game
      FileName = "Big Hub"
   },

   Discord = {
      Enabled = true, -- Prompt the user to join your Discord server if their executor supports it
      Invite = "https://discord.gg/dZvUNnvKgU", -- The Discord invite code, do not include discord.gg/. E.g. discord.gg/ ABCD would be ABCD
      RememberJoins = true -- Set this to false to make them join the discord every time they load it up
   },

   KeySystem = false, -- Set this to true to use our key system
   KeySettings = {
      Title = "Untitled",
      Subtitle = "Key System",
      Note = "No method of obtaining the key is provided", -- Use this to tell the user how to get a key
      FileName = "DougKey", -- It is recommended to use something unique as other scripts using Rayfield may overwrite your key file
      SaveKey = true, -- The user's key will be saved, but if you change the key, they will be unable to use your script
      GrabKeyFromSite = false, -- If this is true, set Key below to the RAW site you would like Rayfield to get the key from
      Key = {"Hello"}, -- List of keys that will be accepted by the system, can be RAW file links (pastebin, github etc) or simple strings ("hello","key22")
   },
   
})

local autoclose = false
local autocollectvault = false
local autocollectsales = false



local Tab = Window:CreateTab(" 😎 Main")

local farm = Tab:CreateSection("Auto")

local Toggle = Tab:CreateToggle({
   Name = "Auto collect vault cash",
   CurrentValue = false,
   Flag = "autoclosevault",
   Callback = function(Value)
        autoclose = Value
        while autoclose do
            local ReplicatedStorage = game:GetService("ReplicatedStorage")

            -- Remote
            local Collect = ReplicatedStorage.Network.Plot.Collect -- RemoteFunction 

            Collect:InvokeServer(
                "Vault"
            )
        end
    end
})


local Toggle = Tab:CreateToggle({
   Name = "Auto collect sales cash",
   CurrentValue = false,
   Flag = "autocollectsales",
   Callback = function(Value)
        autocollectsales = Value
        while autocollectsales do
            local ReplicatedStorage = game:GetService("ReplicatedStorage")

            -- Remote
            local Collect = ReplicatedStorage.Network.Plot.Collect -- RemoteFunction 

            Collect:InvokeServer(
                "Sales"
            )
        end
    end
})

local Toggle = Tab:CreateToggle({
   Name = "Auto close doors",
   CurrentValue = false,
   Flag = "autoclosedoor",
   Callback = function(Value)
        autocollectvault = Value
        while autocollectvault do
            local ReplicatedStorage = game:GetService("ReplicatedStorage")

            -- Remote
            local Lock = ReplicatedStorage.Network.Plot.Lock -- RemoteEvent 

            Lock:FireServer()
            
            task.wait(0.5) -- Attendre 0.5 secondes avant de faire la prochaine action
        end
    end
})










local Tab = Window:CreateTab(" ❓ Info")

Tab:CreateLabel("This is a script made by Doug, it is not a copy of any other script, it is made by me and me only.", 4562954607, Color3.fromRGB(255, 255, 255), false) -- Title, Icon, Color, IgnoreTheme

local Button = Tab:CreateButton({
   Name = "Join the discord server to get more scripts and updates (click to copy link)",
   Callback = function()
       local link = "https://discord.gg/dZvUNnvKgU"

       -- Copie dans le presse-papiers
       pcall(function()
           setclipboard(link)
       end)

       -- Affiche une notification sympa
        Rayfield:Notify({
            Title = "Notification",
            Content = "The link to the discord server has been copied to your clipboard successfully!",
            Duration = 6.5,
        Image = 4483362458,
        })

       print("Lien Discord copié dans le presse-papiers !")
    end,
})


local Slider = Tab:CreateSlider({
    Name = "FPS Cap",
    Range = {5, 360}, -- Tu peux adapter le max si tu veux (240, 1000, etc.)
    Increment = 10,
    Suffix = "FPS",
    CurrentValue = 60,
    Flag = "FpsCapSlider",
    Callback = function(Value)
            setfpscap(Value)
    end,
})


end


--Break your bones script

if game.PlaceId == 123821081589134 then

--========================================================
--  Bone Breaker Helper • EclipseUI (EN)
--  Tabs: farm (Cage/Fling), Gates, Upgrades (+ Ragdoll + Roll Material)
--========================================================

-- Services
local Players             = game:GetService("Players")
local RunService          = game:GetService("RunService")
local Workspace           = game:GetService("Workspace")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local CoreGui             = game:GetService("CoreGui")

local player = Players.LocalPlayer

-- Load EclipseUI from your repo
local ECLIPSE_URL = "https://raw.githubusercontent.com/vegetoku256/Dougyshub/refs/heads/main/EclipseUI.lua"
local ok, Eclipse = pcall(function() return loadstring(game:HttpGet(ECLIPSE_URL))() end)
if not ok or type(Eclipse) ~= "table" or type(Eclipse.CreateWindow) ~= "function" then
    error("[Bone Breaker Helper] Failed to load EclipseUI.", 0)
end

-- Window
local Window = Eclipse:CreateWindow({
    Title = "Break your Bones • Dougy's Hub",
    ToggleKey = Enum.KeyCode.RightShift,
    Size = UDim2.fromOffset(740, 480),
})

-- Tabs & Sections
local Farm      = Window:AddTab("farm")
local CageS     = Farm:AddLeftSection("Cage")
local FlingS    = Farm:AddRightSection("Fling")
local GatesT    = Window:AddTab("Gates")
local GatesS    = GatesT:AddLeftSection("World")
local UpgTab    = Window:AddTab("Upgrades")
local UpgLeft   = UpgTab:AddLeftSection("Bone Upgrades")
local UpgRight  = UpgTab:AddRightSection("Other")

--========================
-- Helpers
--========================
local function getHRP()
    local char = player.Character or player.CharacterAdded:Wait()
    return char:WaitForChild("HumanoidRootPart"), char:WaitForChild("Humanoid"), char
end

-- Robust remote finder (Folder "Remotes" or anywhere under ReplicatedStorage)
local function findRemote(name)
    local rs = ReplicatedStorage
    local folder = rs:FindFirstChild("Remotes") or rs
    local r = folder:FindFirstChild(name)
    if r and r:IsA("RemoteEvent") then return r end
    for _, d in ipairs(rs:GetDescendants()) do
        if d.Name == name and d:IsA("RemoteEvent") then
            return d
        end
    end
    return nil
end

local function getUpgradeRemote()  return findRemote("PurchaseBoneUpgrade")   end
local function getRagdollRemote()  return findRemote("PurchaseNextRagdoll")   end
local function getRefineRemote()   return findRemote("RefineRagdoll")         end

local function AddWrappedText(section, text, approxCharsPerLine)
  approxCharsPerLine = approxCharsPerLine or 46
  local line = ""
  for word in tostring(text):gmatch("%S+") do
    if #line + #word + 1 > approxCharsPerLine then
      section:AddLabel(line)
      line = word
    else
      line = (line == "" and word) or (line .. " " .. word)
    end
  end
  if #line > 0 then section:AddLabel(line) end
end

--========================
-- Loop manager (for toggles that repeat)
--========================
getgenv()._bbhLoops = getgenv()._bbhLoops or {}
local loops = getgenv()._bbhLoops
local FIRE_INTERVAL = 0.35

local function stopLoop(key)
    local rec = loops[key]
    if rec then
        rec.enabled = false
        loops[key] = nil
    end
end

local function startLoop(key, label, fn)
    stopLoop(key) -- clear any old loop
    local rec = { enabled = true }
    loops[key] = rec
    task.spawn(function()
        Window:Notify(label .. " ON", 2)
        while rec.enabled do
            local okFn, err = pcall(fn)
            if not okFn then warn("[BBH loop "..key.."] "..tostring(err)) end
            task.wait(FIRE_INTERVAL)
        end
        Window:Notify(label .. " OFF", 2)
    end)
end

--========================
-- Cage (closed box around the player)
--========================
local cageFolder, cageConn
local cageFrozen = false
local cageCfg = { sizeX = 8, sizeY = 8, sizeZ = 8, thick = 1, color = Color3.fromRGB(60,60,60) }

local function destroyCage()
    if cageConn then cageConn:Disconnect() cageConn = nil end
    if cageFolder then cageFolder:Destroy() cageFolder = nil end
end

local function makeWall(name, size, cframe)
    local p = Instance.new("Part")
    p.Name = name
    p.Anchored = true
    p.CanCollide = true
    p.Material = Enum.Material.SmoothPlastic
    p.Color = cageCfg.color
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Size = size
    p.CFrame = cframe
    p.Parent = cageFolder
    return p
end

local function buildCage()
    destroyCage()
    local hrp = getHRP()
    cageFolder = Instance.new("Folder")
    cageFolder.Name = "Doug_Cage"
    cageFolder.Parent = Workspace

    local sX, sY, sZ = cageCfg.sizeX, cageCfg.sizeY, cageCfg.sizeZ
    local t = cageCfg.thick
    local pos = hrp.Position
    local halfX, halfY, halfZ = sX*0.5, sY*0.5, sZ*0.5

    -- Floor / Roof
    makeWall("Floor", Vector3.new(sX, t,  sZ), CFrame.new(pos + Vector3.new(0, -halfY, 0)))
    makeWall("Roof",  Vector3.new(sX, t,  sZ), CFrame.new(pos + Vector3.new(0,  halfY, 0)))
    -- Walls
    makeWall("Wall+X", Vector3.new(t,  sY, sZ), CFrame.new(pos + Vector3.new( halfX, 0, 0)))
    makeWall("Wall-X", Vector3.new(t,  sY, sZ), CFrame.new(pos + Vector3.new(-halfX, 0, 0)))
    makeWall("Wall+Z", Vector3.new(sX, sY, t ), CFrame.new(pos + Vector3.new(0, 0,  halfZ)))
    makeWall("Wall-Z", Vector3.new(sX, sY, t ), CFrame.new(pos + Vector3.new(0, 0, -halfZ)))

    -- Follow HRP unless frozen
    cageConn = RunService.Heartbeat:Connect(function()
        if not cageFolder or not cageFolder.Parent or cageFrozen then return end
        local hrp2 = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not hrp2 then return end
        local p2 = hrp2.Position
        for _, part in ipairs(cageFolder:GetChildren()) do
            if part.Name == "Floor" then
                part.CFrame = CFrame.new(p2 + Vector3.new(0, -halfY, 0))
            elseif part.Name == "Roof" then
                part.CFrame = CFrame.new(p2 + Vector3.new(0,  halfY, 0))
            elseif part.Name == "Wall+X" then
                part.CFrame = CFrame.new(p2 + Vector3.new( halfX, 0, 0))
            elseif part.Name == "Wall-X" then
                part.CFrame = CFrame.new(p2 + Vector3.new(-halfX, 0, 0))
            elseif part.Name == "Wall+Z" then
                part.CFrame = CFrame.new(p2 + Vector3.new(0, 0,  halfZ))
            elseif part.Name == "Wall-Z" then
                part.CFrame = CFrame.new(p2 + Vector3.new(0, 0, -halfZ))
            end
        end
    end)
end

-- Cage UI
local CageToggleRef
CageToggleRef = CageS:AddToggle({
    text = "📦 Cage",
    default = false, fullWidth = true,
    tooltip = "Creates a closed box around you that follows you.",
    callback = function(state)
        if state then
            buildCage()
            Window:Notify("Cage ON", 2)
        else
            destroyCage()
            Window:Notify("Cage OFF", 2)
        end
    end
})

CageS:AddToggle({
    text = "🧊 Freeze cage",
    default = false, fullWidth = true,
    tooltip = "Stops following: the cage stays still.",
    callback = function(state)
        cageFrozen = state and true or false
        Window:Notify(cageFrozen and "Cage frozen" or "Cage unfrozen", 2)
    end
})

CageS:AddSlider({
    text = "Width (X)", min = 4, max = 30, step = 1, default = cageCfg.sizeX, suffix = " studs",
    fullWidth = true, tooltip = "Horizontal size X of the cage",
    callback = function(v) cageCfg.sizeX = v; if CageToggleRef and CageToggleRef.Get() then buildCage() end end
})
CageS:AddSlider({
    text = "Height (Y)", min = 4, max = 30, step = 1, default = cageCfg.sizeY, suffix = " studs",
    fullWidth = true, tooltip = "Vertical size of the cage",
    callback = function(v) cageCfg.sizeY = v; if CageToggleRef and CageToggleRef.Get() then buildCage() end end
})
CageS:AddSlider({
    text = "Depth (Z)", min = 4, max = 30, step = 1, default = cageCfg.sizeZ, suffix = " studs",
    fullWidth = true, tooltip = "Horizontal size Z of the cage",
    callback = function(v) cageCfg.sizeZ = v; if CageToggleRef and CageToggleRef.Get() then buildCage() end end
})
CageS:AddSlider({
    text = "Wall thickness", min = 1, max = 6, step = 1, default = cageCfg.thick, suffix = " studs",
    fullWidth = true, tooltip = "Wall thickness of the cage",
    callback = function(v) cageCfg.thick = v; if CageToggleRef and CageToggleRef.Get() then buildCage() end end
})

--========================
-- Fling (random impulses & spin)
--========================
local flingConn
local flingCfg = { force = 140, spin = 80 }

local function stopFling()
    if flingConn then flingConn:Disconnect() flingConn = nil end
end

local function startFling()
    stopFling()
    flingConn = RunService.Heartbeat:Connect(function()
        local c = player.Character
        if not c then return end
        local hum = c:FindFirstChild("Humanoid")
        local hrp = c:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp or hum.Health <= 0 then return end

        local rand = Vector3.new((math.random()-0.5)*2, (math.random()-0.35)*2, (math.random()-0.5)*2)
        if rand.Magnitude > 0 then rand = rand.Unit end

        local lin = rand * flingCfg.force
        local ang = Vector3.new(
            (math.random()-0.5) * flingCfg.spin,
            (math.random()-0.5) * flingCfg.spin,
            (math.random()-0.5) * flingCfg.spin
        )

        pcall(function()
            hrp.AssemblyLinearVelocity  = hrp.AssemblyLinearVelocity  + lin
            hrp.AssemblyAngularVelocity = hrp.AssemblyAngularVelocity + ang
        end)
    end)
end

FlingS:AddToggle({
    text = "🌀 Fling",
    default = false, fullWidth = true,
    tooltip = "Continuously launches and spins you (best inside the cage).",
    callback = function(state)
        if state then
            startFling(); Window:Notify("Fling ON", 2)
        else
            stopFling();  Window:Notify("Fling OFF", 2)
        end
    end
})

FlingS:AddSlider({
    text = "Fling Force", min = 20, max = 400, step = 5, default = flingCfg.force, suffix = " u/s",
    fullWidth = true, tooltip = "Intensity of linear impulses",
    callback = function(v) flingCfg.force = v end
})
FlingS:AddSlider({
    text = "Spin Speed", min = 20, max = 300, step = 5, default = flingCfg.spin, suffix = " °/s",
    fullWidth = true, tooltip = "Intensity of rotations",
    callback = function(v) flingCfg.spin = v end
})

FlingS:AddDivider()

AddWrappedText(FlingS, "The game automaticly stop the run after 1-2 minutes, using it overnight isn't gonna work.", 30)
--========================
-- Gates
--========================
GatesS:AddButton({
    text = "Destroy every gates",
    fullWidth = true,
    tooltip = "Deletes Workspace.Gates if it exists.",
    callback = function()
        local g = Workspace:FindFirstChild("Gates")
        if g then
            g:Destroy()
            Window:Notify("Workspace.Gates destroyed.", 3)
        else
            Window:Notify("Workspace.Gates not found.", 3)
        end
    end
})

--========================
-- Upgrades (Remotes)
--========================
local function makeUpgradeToggle(section, label, keyNameOnRemote, loopKey)
    section:AddToggle({
        text = label,
        default = false,
        fullWidth = true,
        tooltip = "Auto-purchase upgrade: " .. keyNameOnRemote,
        callback = function(state)
            if state then
                startLoop(loopKey, label, function()
                    local r = getUpgradeRemote()
                    if r and r:IsA("RemoteEvent") then
                        r:FireServer(keyNameOnRemote)
                    end
                end)
            else
                stopLoop(loopKey)
            end
        end
    })
end

makeUpgradeToggle(UpgLeft, "Head",     "Head",  "upg:Head")
makeUpgradeToggle(UpgLeft, "Rib cage", "Torso", "upg:Torso") -- game expects "Torso"
makeUpgradeToggle(UpgLeft, "Arm",      "Arm",   "upg:Arm")
makeUpgradeToggle(UpgLeft, "Leg",      "Leg",   "upg:Leg")

-- Right-side: Buy Next Ragdoll (loop)
UpgRight:AddButton({
    text = "Buy Next Ragdoll",
    fullWidth = true,
    tooltip = "Auto-purchase the next ragdoll.",
    callback = function(state)
        local r = getRagdollRemote()
        if r and r:IsA("RemoteEvent") then
            r:FireServer()
            Window:Notify("Bought next ragdoll.", 2)
        end
    end
})

-- Right-side: Roll Material (single fire button)
UpgRight:AddButton({
    text = "Roll Material",
    fullWidth = true,
    tooltip = "Roll/refine your ragdoll's material once.",
    callback = function()
        local r = getRefineRemote()
        if r and r:IsA("RemoteEvent") then
            pcall(function() r:FireServer() end)
            Window:Notify("Rolled material.", 2)
        else
            Window:Notify("RefineRagdoll remote not found.", 3)
        end
    end
})

AddWrappedText(UpgLeft, "If you press the button and nothing happen, this is because you don't have enough money.Duh.", 25)

--========================
-- Cleanups
--========================
local function cleanup()
    -- stop fling
    if flingConn then flingConn:Disconnect() flingConn = nil end
    -- stop all loops
    for k in pairs(loops) do stopLoop(k) end
    -- destroy cage
    destroyCage()
end

pcall(function()
    CoreGui.ChildRemoved:Connect(function(ch)
        if ch.Name == "EclipseUI" then cleanup() end
    end)
end)

Window:Notify("UI loaded for break your bones", 4)


end
