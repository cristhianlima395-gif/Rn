-- Quest Follower | combate manual
-- - Seleciona a missão de acordo com o nível do jogador
-- - Recomeça a missão quando a anterior termina
-- - Não possui auto-click nem envia ataques
-- - Kill Big Moon procura Big Moon/Big Mom e usa Cake Queen como alternativa
-- - Aumenta localmente a hitbox do alvo e restaura as propriedades ao parar/trocar

local SharedEnvironment = _G
if type(getgenv) == "function" then
    local ok, env = pcall(getgenv)
    if ok and type(env) == "table" then
        SharedEnvironment = env
    end
end

if type(SharedEnvironment.__MeleeMasteryCleanup) == "function" then
    pcall(SharedEnvironment.__MeleeMasteryCleanup)
end
SharedEnvironment.__MeleeMasterySession = (tonumber(SharedEnvironment.__MeleeMasterySession) or 0) + 1
local SessionId = SharedEnvironment.__MeleeMasterySession
local function IsCurrentSession()
    return SharedEnvironment.__MeleeMasterySession == SessionId
end

repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui", 10)
if not PlayerGui then error("PlayerGui nao carregou; execute depois que o personagem terminar de entrar") end
local Enemies = workspace:FindFirstChild("Enemies")

local oldGui
local guiParent
if type(gethui) == "function" then
    local ok, result = pcall(gethui)
    if ok then guiParent = result end
end
guiParent = guiParent or PlayerGui
oldGui = guiParent:FindFirstChild("MeleeMasteryOnlyUI")
if oldGui then oldGui:Destroy() end

local Configs = {
    [2753915549] = {
        PlaceId = 2753915549,
        SeaName = "Sea 1",
        SpawnPoints = {
            CFrame.new(5985, 70, 4790),
            CFrame.new(5472, 70, 4887)
        }
    },
    [4442272183] = {
        PlaceId = 4442272183,
        SeaName = "Sea 2",
        SpawnPoints = {
            CFrame.new(-3339, 290, -10412),
            CFrame.new(-3518, 290, -10419),
            CFrame.new(-3536, 290, -10607),
            CFrame.new(-3345, 280, -10667)
        }
    },
    [7449423635] = {
        PlaceId = 7449423635,
        SeaName = "Sea 3",
        SpawnPoints = {
            CFrame.new(-16634, 85, 1106),
            CFrame.new(-16735, 60, 1075),
            CFrame.new(-16888, 35, 1011)
        }
    }
}

local function DetectConfig()
    local placeId = tonumber(game.PlaceId)
    if placeId and Configs[placeId] then
        return Configs[placeId], "PlaceId " .. tostring(placeId)
    end

    local map = workspace:FindFirstChild("Map")
    local cues = {
        [7449423635] = {"TikiOutpost", "Tiki Outpost", "PortTown", "Port Town", "HydraIsland", "FloatingTurtle", "GreatTree", "HauntedCastle"},
        [4442272183] = {"KingdomOfRose", "Kingdom of Rose", "GreenZone", "Green Zone", "CursedShip", "ForgottenIsland", "SnowMountain"},
        [2753915549] = {"FountainCity", "Fountain City", "Jungle", "PirateVillage", "Pirate Village", "MarineStarter", "PirateStarter", "UnderwaterCity"}
    }
    if map then
        for _, place in ipairs({7449423635, 4442272183, 2753915549}) do
            for _, cue in ipairs(cues[place]) do
                if map:FindFirstChild(cue, true) then
                    return Configs[place], "map"
                end
            end
        end
    end

    return nil, "PlaceId " .. tostring(game.PlaceId) .. " nao reconhecido"
end
local Config, DetectInfo = DetectConfig()

-- Missões de NPC por faixa de nível. As entradas usam os identificadores usuais
-- de StartQuest do Blox Fruits; os alvos continuam sendo derrotados manualmente.
local QuestRoutes = {
    [2753915549] = {
        {Min=1, Max=9, Quest="BanditQuest", Stage=1, Targets={"Bandit"}},
        {Min=10, Max=14, Quest="JungleQuest", Stage=1, Targets={"Monkey"}},
        {Min=15, Max=29, Quest="JungleQuest", Stage=2, Targets={"Gorilla"}},
        {Min=30, Max=39, Quest="BuggyQuest1", Stage=1, Targets={"Pirate"}},
        {Min=40, Max=59, Quest="BuggyQuest1", Stage=2, Targets={"Brute"}},
        {Min=60, Max=74, Quest="DesertQuest", Stage=1, Targets={"Desert Bandit"}},
        {Min=75, Max=89, Quest="DesertQuest", Stage=2, Targets={"Desert Officer"}},
        {Min=90, Max=99, Quest="SnowQuest", Stage=1, Targets={"Snow Bandit"}},
        {Min=100, Max=119, Quest="SnowQuest", Stage=2, Targets={"Snowman"}},
        {Min=120, Max=149, Quest="MarineQuest2", Stage=1, Targets={"Chief Petty Officer"}},
        {Min=150, Max=174, Quest="SkyQuest", Stage=1, Targets={"Sky Bandit"}},
        {Min=175, Max=189, Quest="SkyQuest", Stage=2, Targets={"Dark Master"}},
        {Min=190, Max=209, Quest="PrisonerQuest", Stage=1, Targets={"Prisoner"}},
        {Min=210, Max=249, Quest="PrisonerQuest", Stage=2, Targets={"Dangerous Prisoner"}},
        {Min=250, Max=274, Quest="ColosseumQuest", Stage=1, Targets={"Toga Warrior"}},
        {Min=275, Max=299, Quest="ColosseumQuest", Stage=2, Targets={"Gladiator"}},
        {Min=300, Max=324, Quest="MagmaQuest", Stage=1, Targets={"Military Soldier"}},
        {Min=325, Max=374, Quest="MagmaQuest", Stage=2, Targets={"Military Spy"}},
        {Min=375, Max=399, Quest="FishmanQuest", Stage=1, Targets={"Fishman Warrior"}},
        {Min=400, Max=449, Quest="FishmanQuest", Stage=2, Targets={"Fishman Commando"}},
        {Min=450, Max=474, Quest="SkyExp1Quest", Stage=1, Targets={"God's Guard"}},
        {Min=475, Max=524, Quest="SkyExp1Quest", Stage=2, Targets={"Shanda"}},
        {Min=525, Max=549, Quest="SkyExp2Quest", Stage=1, Targets={"Royal Squad"}},
        {Min=550, Max=624, Quest="SkyExp2Quest", Stage=2, Targets={"Royal Soldier"}},
        {Min=625, Max=649, Quest="FountainQuest", Stage=1, Targets={"Galley Pirate"}},
        {Min=650, Max=699, Quest="FountainQuest", Stage=2, Targets={"Galley Captain"}}
    },
    [4442272183] = {
        {Min=700, Max=724, Quest="Area1Quest", Stage=1, Targets={"Raider"}},
        {Min=725, Max=774, Quest="Area1Quest", Stage=2, Targets={"Mercenary"}},
        {Min=775, Max=799, Quest="Area2Quest", Stage=1, Targets={"Swan Pirate"}},
        {Min=800, Max=874, Quest="Area2Quest", Stage=2, Targets={"Factory Staff"}},
        {Min=875, Max=899, Quest="MarineQuest3", Stage=1, Targets={"Marine Lieutenant"}},
        {Min=900, Max=949, Quest="MarineQuest3", Stage=2, Targets={"Marine Captain"}},
        {Min=950, Max=974, Quest="ZombieQuest", Stage=1, Targets={"Zombie"}},
        {Min=975, Max=999, Quest="ZombieQuest", Stage=2, Targets={"Vampire"}},
        {Min=1000, Max=1049, Quest="SnowMountainQuest", Stage=1, Targets={"Snow Trooper"}},
        {Min=1050, Max=1099, Quest="SnowMountainQuest", Stage=2, Targets={"Winter Warrior"}},
        {Min=1100, Max=1124, Quest="IceSideQuest", Stage=1, Targets={"Lab Subordinate"}},
        {Min=1125, Max=1174, Quest="IceSideQuest", Stage=2, Targets={"Horned Warrior"}},
        {Min=1175, Max=1199, Quest="FireSideQuest", Stage=1, Targets={"Magma Ninja"}},
        {Min=1200, Max=1249, Quest="FireSideQuest", Stage=2, Targets={"Lava Pirate"}},
        {Min=1250, Max=1274, Quest="ShipQuest1", Stage=1, Targets={"Ship Deckhand"}},
        {Min=1275, Max=1299, Quest="ShipQuest1", Stage=2, Targets={"Ship Engineer"}},
        {Min=1300, Max=1324, Quest="ShipQuest2", Stage=1, Targets={"Ship Steward"}},
        {Min=1325, Max=1349, Quest="ShipQuest2", Stage=2, Targets={"Ship Officer"}},
        {Min=1350, Max=1374, Quest="FrostQuest", Stage=1, Targets={"Arctic Warrior"}},
        {Min=1375, Max=1424, Quest="FrostQuest", Stage=2, Targets={"Snow Lurker"}},
        {Min=1425, Max=1449, Quest="ForgottenQuest", Stage=1, Targets={"Sea Soldier"}},
        {Min=1450, Max=1499, Quest="ForgottenQuest", Stage=2, Targets={"Water Fighter"}}
    },
    [7449423635] = {
        {Min=1500, Max=1524, Quest="PiratePortQuest", Stage=1, Targets={"Pirate Millionaire"}},
        {Min=1525, Max=1574, Quest="PiratePortQuest", Stage=2, Targets={"Pistol Billionaire"}},
        {Min=1575, Max=1599, Quest="AmazonQuest", Stage=1, Targets={"Dragon Crew Warrior"}},
        {Min=1600, Max=1624, Quest="AmazonQuest", Stage=2, Targets={"Dragon Crew Archer"}},
        {Min=1625, Max=1649, Quest="AmazonQuest2", Stage=1, Targets={"Hydra Enforcer"}},
        {Min=1650, Max=1699, Quest="AmazonQuest2", Stage=2, Targets={"Venomous Assailant"}},
        {Min=1700, Max=1724, Quest="MarineTreeIsland", Stage=1, Targets={"Marine Commodore"}},
        {Min=1725, Max=1774, Quest="MarineTreeIsland", Stage=2, Targets={"Marine Rear Admiral"}},
        {Min=1775, Max=1799, Quest="DeepForestIsland3", Stage=1, Targets={"Fishman Raider"}},
        {Min=1800, Max=1824, Quest="DeepForestIsland3", Stage=2, Targets={"Fishman Captain"}},
        {Min=1825, Max=1849, Quest="DeepForestIsland2", Stage=1, Targets={"Forest Pirate"}},
        {Min=1850, Max=1899, Quest="DeepForestIsland2", Stage=2, Targets={"Mythological Pirate"}},
        {Min=1900, Max=1924, Quest="DeepForestIsland", Stage=1, Targets={"Jungle Pirate"}},
        {Min=1925, Max=1974, Quest="DeepForestIsland", Stage=2, Targets={"Musketeer Pirate"}},
        {Min=1975, Max=1999, Quest="HauntedQuest1", Stage=1, Targets={"Reborn Skeleton"}},
        {Min=2000, Max=2024, Quest="HauntedQuest1", Stage=2, Targets={"Living Zombie"}},
        {Min=2025, Max=2049, Quest="HauntedQuest2", Stage=1, Targets={"Demonic Soul"}},
        {Min=2050, Max=2074, Quest="HauntedQuest2", Stage=2, Targets={"Possessed Mummy"}},
        {Min=2075, Max=2099, Quest="NutsIslandQuest", Stage=1, Targets={"Peanut Scout"}},
        {Min=2100, Max=2124, Quest="NutsIslandQuest", Stage=2, Targets={"Peanut President"}},
        {Min=2125, Max=2149, Quest="IceCreamIslandQuest", Stage=1, Targets={"Ice Cream Chef"}},
        {Min=2150, Max=2199, Quest="IceCreamIslandQuest", Stage=2, Targets={"Ice Cream Commander"}},
        {Min=2200, Max=2224, Quest="CakeQuest1", Stage=1, Targets={"Cookie Crafter"}},
        {Min=2225, Max=2249, Quest="CakeQuest1", Stage=2, Targets={"Cake Guard"}},
        {Min=2250, Max=2274, Quest="CakeQuest2", Stage=1, Targets={"Baking Staff"}},
        {Min=2275, Max=2299, Quest="CakeQuest2", Stage=2, Targets={"Head Baker"}},
        {Min=2300, Max=2324, Quest="ChocQuest1", Stage=1, Targets={"Cocoa Warrior"}},
        {Min=2325, Max=2349, Quest="ChocQuest1", Stage=2, Targets={"Chocolate Bar Battler"}},
        {Min=2350, Max=2374, Quest="ChocQuest2", Stage=1, Targets={"Sweet Thief"}},
        {Min=2375, Max=2399, Quest="ChocQuest2", Stage=2, Targets={"Candy Rebel"}},
        {Min=2400, Max=2424, Quest="CandyQuest1", Stage=1, Targets={"Candy Pirate"}},
        {Min=2425, Max=2449, Quest="CandyQuest1", Stage=2, Targets={"Snow Demon"}},
        {Min=2450, Max=2474, Quest="TikiQuest1", Stage=1, Targets={"Isle Outlaw"}},
        {Min=2475, Max=2499, Quest="TikiQuest1", Stage=2, Targets={"Island Boy"}},
        {Min=2500, Max=2524, Quest="TikiQuest2", Stage=1, Targets={"Sun-kissed Warrior"}},
        {Min=2525, Max=2549, Quest="TikiQuest2", Stage=2, Targets={"Isle Champion"}},
        {Min=2550, Max=2574, Quest="TikiQuest3", Stage=1, Targets={"Serpent Hunter"}},
        {Min=2575, Max=2599, Quest="TikiQuest3", Stage=2, Targets={"Skull Slayer"}},
        {Min=2600, Max=2624, Quest="SubmergedQuest1", Stage=1, Targets={"Reef Bandit"}},
        {Min=2625, Max=2649, Quest="SubmergedQuest1", Stage=2, Targets={"Coral Pirate"}},
        {Min=2650, Max=2674, Quest="SubmergedQuest2", Stage=1, Targets={"Sea Chanter"}},
        {Min=2675, Max=2699, Quest="SubmergedQuest3", Stage=1, Targets={"High Disciple"}},
        {Min=2700, Max=99999, Quest="SubmergedQuest3", Stage=2, Targets={"Grand Devotee"}}
    }
}

local Enabled = false
local ActiveMode = nil -- "quest" ou "boss"
local ActiveTargetNames = {}
local CurrentQuestRoute = nil
local lastQuestAttempt = 0
local ExpandedHitboxRoot = nil
local OriginalHitbox = setmetatable({}, {__mode = "k"})
local RestoreTargetHitbox
local Height = 6
local LoopToken = 0
local spawnIndex = 1
local lastSpawnMove = 0
local MoveToken = 0
local FLIGHT_SPEED = 85
local NoclipEnabled = false
local OriginalCollision = setmetatable({}, {__mode = "k"})
local NoclipConnection = nil
local VelocityClampConnection = nil
local StopVelocityClamp
local SetNoclip
local StopHover
local StopFlight
local RecoverIfBelowWorld
local HoverMover
local FlightVelocity
local FlightRotation
local LastSafeCFrame = SharedEnvironment.__MeleeMasteryLastSafe
local CurrentTarget = nil

local function Make(className, properties, parent)
    local object = Instance.new(className)
    for key, value in pairs(properties or {}) do
        object[key] = value
    end
    object.Parent = parent
    return object
end

local GUI = Make("ScreenGui", {
    Name = "MeleeMasteryOnlyUI",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling
}, guiParent)

local Main = Make("Frame", {
    Name = "Main",
    Size = UDim2.fromOffset(286, 236),
    Position = UDim2.new(0.5, -143, 0.48, -102),
    BackgroundColor3 = Color3.fromRGB(20, 23, 31),
    BorderSizePixel = 0,
    Active = true
}, GUI)
Make("UICorner", {CornerRadius = UDim.new(0, 10)}, Main)
Make("UIStroke", {Color = Color3.fromRGB(75, 96, 130), Thickness = 1}, Main)
local cameraAtStart = workspace.CurrentCamera
local viewportAtStart = cameraAtStart and cameraAtStart.ViewportSize or Vector2.new(1280, 720)
local responsiveScale = math.clamp(math.min(viewportAtStart.X / 430, viewportAtStart.Y / 340), 0.55, 0.62)
Make("UIScale", {Scale = responsiveScale}, Main)

local FloatingButton = Make("TextButton", {
    Name = "FloatingToggle",
    Size = UDim2.fromOffset(48, 48),
    Position = UDim2.new(1, -64, 0.22, 0),
    BackgroundColor3 = Color3.fromRGB(20, 23, 31),
    BorderSizePixel = 0,
    Text = "MM",
    TextColor3 = Color3.fromRGB(115, 210, 255),
    TextSize = 26,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = true,
    ZIndex = 30,
    Active = true
}, GUI)
Make("UICorner", {CornerRadius = UDim.new(1, 0)}, FloatingButton)
Make("UIStroke", {Color = Color3.fromRGB(75, 170, 225), Thickness = 2}, FloatingButton)

local suppressFloatClick = false
FloatingButton.Activated:Connect(function()
    if suppressFloatClick then
        suppressFloatClick = false
        return
    end
    Main.Visible = not Main.Visible
    FloatingButton.Text = Main.Visible and "−" or "MM"
end)

do
    local floatDragging = false
    local floatStart, floatPosition
    FloatingButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            floatDragging = true
            floatStart = input.Position
            floatPosition = FloatingButton.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if floatDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - floatStart
            if delta.Magnitude > 7 then suppressFloatClick = true end
            FloatingButton.Position = UDim2.new(floatPosition.X.Scale, floatPosition.X.Offset + delta.X,
                floatPosition.Y.Scale, floatPosition.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            floatDragging = false
            if suppressFloatClick then
                task.delay(0.25, function() suppressFloatClick = false end)
            end
        end
    end)
end

local Header = Make("TextLabel", {
    Name = "Header",
    Size = UDim2.new(1, -18, 0, 32),
    Position = UDim2.fromOffset(12, 5),
    BackgroundTransparency = 1,
    Text = "QUEST FOLLOWER | MANUAL",
    TextColor3 = Color3.fromRGB(115, 210, 255),
    TextSize = 15,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left
}, Main)

local Status = Make("TextLabel", {
    Name = "Status",
    Size = UDim2.new(1, -24, 0, 22),
    Position = UDim2.fromOffset(12, 38),
    BackgroundTransparency = 1,
    Text = Config and (Config.SeaName .. " detectado | missão por nível pronta") or ("UI pronta | Selecione Sea | ID: " .. tostring(game.PlaceId)),
    TextColor3 = Config and Color3.fromRGB(170, 180, 195) or Color3.fromRGB(255, 170, 100),
    TextSize = 10,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left
}, Main)

local Toggle
local BossToggle
local SeaButtons = {}
local SeaButtonData = {
    {id = 2753915549, label = "SEA 1"},
    {id = 4442272183, label = "SEA 2"},
    {id = 7449423635, label = "SEA 3"}
}
for index, item in ipairs(SeaButtonData) do
    local button = Make("TextButton", {
        Name = item.label:gsub(" ", ""),
        Size = UDim2.new(1/3, -14, 0, 22),
        Position = UDim2.new((index - 1)/3, 12, 0, 60),
        BackgroundColor3 = Config == Configs[item.id] and Color3.fromRGB(26, 123, 91) or Color3.fromRGB(42, 48, 61),
        BorderSizePixel = 0,
        Text = item.label,
        TextColor3 = Color3.fromRGB(240, 244, 250),
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = true
    }, Main)
    Make("UICorner", {CornerRadius = UDim.new(0, 6)}, button)
    SeaButtons[item.id] = button
end

Toggle = Make("TextButton", {
    Name = "FarmToggle",
    Size = UDim2.new(1, -24, 0, 38),
    Position = UDim2.fromOffset(12, 87),
    BackgroundColor3 = Color3.fromRGB(42, 48, 61),
    BorderSizePixel = 0,
    Text = "Missão por nível: OFF",
    TextColor3 = Color3.fromRGB(240, 244, 250),
    TextSize = 12,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = true
}, Main)
Make("UICorner", {CornerRadius = UDim.new(0, 7)}, Toggle)

BossToggle = Make("TextButton", {
    Name = "KillBigMoonToggle",
    Size = UDim2.new(1, -24, 0, 22),
    Position = UDim2.fromOffset(12, 179),
    BackgroundColor3 = Color3.fromRGB(42, 48, 61),
    BorderSizePixel = 0,
    Text = "Kill Big Moon: OFF",
    TextColor3 = Color3.fromRGB(240, 244, 250),
    TextSize = 10,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = true
}, Main)
Make("UICorner", {CornerRadius = UDim.new(0, 6)}, BossToggle)
local function SetSelectedSea(placeId)
    if Enabled then
        Enabled = false
        ActiveMode = nil
        CurrentQuestRoute = nil
        ActiveTargetNames = {}
        LoopToken += 1
        MoveToken += 1
        CurrentTarget = nil
        if StopHover then StopHover() end
        if StopFlight then StopFlight() end
        if RestoreTargetHitbox then RestoreTargetHitbox() end
        SetNoclip(false)
        if StopVelocityClamp then StopVelocityClamp() end
        if RecoverIfBelowWorld then RecoverIfBelowWorld() end
        if Toggle then Toggle.Text = "Missão por nível: OFF"; Toggle.BackgroundColor3 = Color3.fromRGB(42, 48, 61) end
        if BossToggle then BossToggle.Text = "Kill Big Moon: OFF"; BossToggle.BackgroundColor3 = Color3.fromRGB(42, 48, 61) end
    end
    Config = Configs[placeId]
    for id, button in pairs(SeaButtons) do
        button.BackgroundColor3 = id == placeId and Color3.fromRGB(26, 123, 91) or Color3.fromRGB(42, 48, 61)
    end
    if Config then
        Status.Text = Config.SeaName .. " | missão selecionada pelo seu nível"
        Status.TextColor3 = Color3.fromRGB(170, 220, 190)
        Toggle.Text = "Missão por nível: OFF"
        Toggle.BackgroundColor3 = Color3.fromRGB(42, 48, 61)
    end
end

for placeId, button in pairs(SeaButtons) do
    button.Activated:Connect(function()
        SetSelectedSea(placeId)
    end)
end

local HeightText = Make("TextLabel", {
    Name = "HeightLabel",
    Size = UDim2.new(1, -24, 0, 20),
    Position = UDim2.fromOffset(12, 130),
    BackgroundTransparency = 1,
    Text = "Altura acima do NPC: " .. Height,
    TextColor3 = Color3.fromRGB(220, 226, 236),
    TextSize = 11,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left
}, Main)

local SliderBack = Make("Frame", {
    Name = "SliderBack",
    Size = UDim2.new(1, -24, 0, 10),
    Position = UDim2.fromOffset(12, 155),
    BackgroundColor3 = Color3.fromRGB(48, 56, 72),
    BorderSizePixel = 0
}, Main)
Make("UICorner", {CornerRadius = UDim.new(1, 0)}, SliderBack)
local SliderFill = Make("Frame", {
    Name = "SliderFill",
    Size = UDim2.new((Height - 4) / 6, 0, 1, 0),
    BackgroundColor3 = Color3.fromRGB(75, 184, 245),
    BorderSizePixel = 0
}, SliderBack)
Make("UICorner", {CornerRadius = UDim.new(1, 0)}, SliderFill)
local SliderButton = Make("TextButton", {
    Name = "SliderButton",
    Size = UDim2.new(1, 0, 0, 28),
    Position = UDim2.new(0, 0, 0.5, -14),
    BackgroundTransparency = 1,
    Text = "",
    AutoButtonColor = false
}, SliderBack)

local Footer = Make("TextLabel", {
    Name = "Footer",
    Size = UDim2.new(1, -24, 0, 17),
    Position = UDim2.fromOffset(12, 207),
    BackgroundTransparency = 1,
    Text = "v6.3 | colisão restaurada após viagem",
    TextColor3 = Color3.fromRGB(125, 137, 157),
    TextSize = 9,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left
}, Main)

do
    local dragging = false
    local dragStart, startPosition
    Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPosition = Main.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            Main.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X,
                startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

local function UpdateHeightFromX(screenX)
    local left = SliderBack.AbsolutePosition.X
    local width = math.max(SliderBack.AbsoluteSize.X, 1)
    local alpha = math.clamp((screenX - left) / width, 0, 1)
    Height = math.clamp(math.floor(4 + alpha * 6 + 0.5), 4, 10)
    SliderFill.Size = UDim2.new((Height - 4) / 6, 0, 1, 0)
    HeightText.Text = "Altura acima do NPC: " .. Height
end

local sliderDragging = false
SliderButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        sliderDragging = true
        UpdateHeightFromX(input.Position.X)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if sliderDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        UpdateHeightFromX(input.Position.X)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        sliderDragging = false
    end
end)

local function GetCharacterParts()
    local character = Player.Character
    if not character then return nil, nil, nil end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root or humanoid.Health <= 0 then return nil, nil, nil end

    if not NoclipEnabled and root.Position.Y > 5 then
        LastSafeCFrame = root.CFrame
        SharedEnvironment.__MeleeMasteryLastSafe = LastSafeCFrame
    end
    return character, humanoid, root
end

-- Noclip forçado continuamente (evita colisão com NPC)
SetNoclip = function(enabled)
    NoclipEnabled = enabled
    local character = Player.Character
    if not character then return end

    if enabled then
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                if OriginalCollision[part] == nil then
                    OriginalCollision[part] = part.CanCollide
                end
                part.CanCollide = false
            end
        end

        if NoclipConnection then
            pcall(function() NoclipConnection:Disconnect() end)
        end
        local lastNoclipScan = 0
        NoclipConnection = RunService.Heartbeat:Connect(function()
            if not NoclipEnabled or not IsCurrentSession() then return end
            if os.clock() - lastNoclipScan < 0.25 then return end
            lastNoclipScan = os.clock()
            local char = Player.Character
            if not char then return end
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end)
    else
        if NoclipConnection then
            pcall(function() NoclipConnection:Disconnect() end)
            NoclipConnection = nil
        end
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                local original = OriginalCollision[part]
                if original ~= nil then
                    part.CanCollide = original
                    OriginalCollision[part] = nil
                end
            end
        end
    end
end

-- Clamp de velocidade: impede valores extremos que costumam fechar o Delta
local function StartVelocityClamp()
    if VelocityClampConnection then
        pcall(function() VelocityClampConnection:Disconnect() end)
    end
    local lastClampCheck = 0
    VelocityClampConnection = RunService.Heartbeat:Connect(function()
        if not IsCurrentSession() then return end
        if os.clock() - lastClampCheck < 0.2 then return end
        lastClampCheck = os.clock()
        local _, _, root = GetCharacterParts()
        if not root then return end
        local vel = root.AssemblyLinearVelocity
        local maxSpeed = 180
        if vel.Magnitude > maxSpeed then
            root.AssemblyLinearVelocity = vel.Unit * maxSpeed
        end
        if vel.X ~= vel.X or vel.Y ~= vel.Y or vel.Z ~= vel.Z
            or math.abs(vel.X) == math.huge or math.abs(vel.Y) == math.huge
            or math.abs(vel.Z) == math.huge then
            root.AssemblyLinearVelocity = Vector3.zero
        end
    end)
end

StopVelocityClamp = function()
    if VelocityClampConnection then
        pcall(function() VelocityClampConnection:Disconnect() end)
        VelocityClampConnection = nil
    end
end

local function IsTargetName(name)
    return type(ActiveTargetNames) == "table" and table.find(ActiveTargetNames, name) ~= nil
end

local function GetTarget()
    local _, _, playerRoot = GetCharacterParts()
    if not playerRoot or not Config then return nil end

    Enemies = workspace:FindFirstChild("Enemies")
    if not Enemies then
        if Status then Status.Text = "Aguardando pasta Enemies do jogo..." end
        return nil
    end

    -- Mantém o alvo até morrer/desaparecer; depois escolhe o NPC da missão mais próximo.
    if CurrentTarget and CurrentTarget.Parent then
        local hum = CurrentTarget:FindFirstChildOfClass("Humanoid")
        local root = CurrentTarget:FindFirstChild("HumanoidRootPart") or CurrentTarget.PrimaryPart
        if hum and hum.Health > 0 and root and IsTargetName(CurrentTarget.Name) then
            return CurrentTarget
        end
    end

    local best, bestDistance = nil, math.huge
    for _, enemy in ipairs(Enemies:GetChildren()) do
        if IsTargetName(enemy.Name) then
            local humanoid = enemy:FindFirstChildOfClass("Humanoid")
            local root = enemy:FindFirstChild("HumanoidRootPart") or enemy.PrimaryPart
            if humanoid and humanoid.Health > 0 and root then
                local distance = (playerRoot.Position - root.Position).Magnitude
                if distance < bestDistance then
                    best, bestDistance = enemy, distance
                end
            end
        end
    end
    if best ~= CurrentTarget then
        if RestoreTargetHitbox then RestoreTargetHitbox() end
    end
    CurrentTarget = best
    return best
end

local function GetPlayerLevel()
    local data = Player:FindFirstChild("Data")
    local level = data and data:FindFirstChild("Level")
    if level and level:IsA("ValueBase") then
        return tonumber(level.Value)
    end
    local stats = Player:FindFirstChild("leaderstats")
    level = stats and stats:FindFirstChild("Level")
    if level and level:IsA("ValueBase") then
        return tonumber(level.Value)
    end
    return nil
end

local function GetQuestRoute(level)
    if not Config or not level then return nil end
    if Config.PlaceId == 2753915549 and level < 10 and Player.Team and string.find(string.lower(Player.Team.Name), "marine", 1, true) then
        return {Min=0, Max=9, Quest="MarineQuest", Stage=1, Targets={"Trainee"}}
    end
    local routes = QuestRoutes[Config.PlaceId]
    if not routes or #routes == 0 then return nil end
    for _, route in ipairs(routes) do
        if level >= route.Min and level <= route.Max then
            return route
        end
    end
    -- Se o jogador estiver acima do intervalo normal do mar selecionado,
    -- mantém a última missão desse mar em vez de escolher um NPC aleatório.
    if level < routes[1].Min then return routes[1] end
    return routes[#routes]
end

local function QuestPanelVisible()
    local main = PlayerGui and PlayerGui:FindFirstChild("Main")
    local quest = main and main:FindFirstChild("Quest")
    return quest ~= nil and quest.Visible == true
end

local function StartQuestIfNeeded(route, force)
    if not route then return end
    if not force and (QuestPanelVisible() or os.clock() - lastQuestAttempt < 2.8) then
        return
    end
    if force and os.clock() - lastQuestAttempt < 0.35 then return end
    lastQuestAttempt = os.clock()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local comm = remotes and remotes:FindFirstChild("CommF_")
    if not comm then
        if Status then Status.Text = "Não encontrei o remoto de missões; esperando..." end
        return
    end
    local ok, err = pcall(function()
        comm:InvokeServer("StartQuest", route.Quest, route.Stage)
    end)
    if not ok and Status then
        Status.Text = "Falha ao iniciar missão: " .. string.sub(tostring(err), 1, 75)
    end
end

RestoreTargetHitbox = function()
    local root = ExpandedHitboxRoot
    if root then
        local original = OriginalHitbox[root]
        if original then
            pcall(function()
                if root.Parent then
                    root.Size = original.Size
                    root.Transparency = original.Transparency
                    root.CanCollide = original.CanCollide
                end
            end)
            OriginalHitbox[root] = nil
        end
    end
    ExpandedHitboxRoot = nil
end

local function ExpandTargetHitbox(target)
    local root = target and (target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart)
    if not root or not root:IsA("BasePart") then
        if RestoreTargetHitbox then RestoreTargetHitbox() end
        return
    end
    if ExpandedHitboxRoot ~= root then
        if RestoreTargetHitbox then RestoreTargetHitbox() end
        OriginalHitbox[root] = {
            Size = root.Size,
            Transparency = root.Transparency,
            CanCollide = root.CanCollide
        }
        ExpandedHitboxRoot = root
    end
    -- Alteração local para facilitar o toque visual; o servidor ainda pode limitar o alcance real.
    pcall(function()
        root.Size = Vector3.new(28, 28, 28)
        root.Transparency = 0.78
        root.CanCollide = false
    end)
end
local function MoveSegment(destination, rotation, token)
    local _, _, root = GetCharacterParts()
    if not root then return false end

    if not FlightVelocity or FlightVelocity.Parent ~= root then
        if FlightVelocity then pcall(function() FlightVelocity:Destroy() end) end
        if FlightRotation then pcall(function() FlightRotation:Destroy() end) end

        FlightVelocity = Instance.new("BodyVelocity")
        FlightVelocity.Name = "MeleeMasteryFlightVelocity"
        FlightVelocity.MaxForce = Vector3.new(2.5e5, 2.5e5, 2.5e5)
        FlightVelocity.P = 10000
        FlightVelocity.Velocity = Vector3.zero
        FlightVelocity.Parent = root

        FlightRotation = Instance.new("BodyGyro")
        FlightRotation.Name = "MeleeMasteryFlightRotation"
        FlightRotation.MaxTorque = Vector3.new(2.5e5, 2.5e5, 2.5e5)
        FlightRotation.P = 5000
        FlightRotation.D = 500
        FlightRotation.CFrame = root.CFrame
        FlightRotation.Parent = root
    end

    local currentSpeed = 0
    while Enabled and token == MoveToken and IsCurrentSession() do
        local dt = RunService.Heartbeat:Wait()
        local _, _, currentRoot = GetCharacterParts()
        if not currentRoot then break end

        local delta = destination - currentRoot.Position
        local distance = delta.Magnitude
        if distance <= 4.5 then
            FlightVelocity.Velocity = Vector3.zero
            FlightRotation.CFrame = CFrame.new(currentRoot.Position) * rotation
            currentRoot.AssemblyLinearVelocity = Vector3.zero
            return true
        end

        currentSpeed = math.min(FLIGHT_SPEED, currentSpeed + 600 * dt)
        local brakingSpeed = math.sqrt(2 * 450 * distance)
        local actualSpeed = math.min(currentSpeed, math.max(35, brakingSpeed))
        FlightVelocity.Velocity = delta.Unit * actualSpeed
        FlightRotation.CFrame = CFrame.new(currentRoot.Position) * rotation
    end

    if FlightVelocity then pcall(function() FlightVelocity.Velocity = Vector3.zero end) end
    local _, _, currentRoot = GetCharacterParts()
    if currentRoot then currentRoot.AssemblyLinearVelocity = Vector3.zero end
    return false
end

StopFlight = function()
    if FlightVelocity then
        pcall(function() FlightVelocity:Destroy() end)
        FlightVelocity = nil
    end
    if FlightRotation then
        pcall(function() FlightRotation:Destroy() end)
        FlightRotation = nil
    end
    local _, _, root = GetCharacterParts()
    if root then
        pcall(function()
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end)
    end
end

StopHover = function()
    if HoverMover then
        pcall(function() HoverMover:Destroy() end)
        HoverMover = nil
    end
end

local function HoldAtPosition(position)
    local _, _, root = GetCharacterParts()
    if not root then return end

    if not HoverMover or HoverMover.Parent ~= root then
        StopHover()
        HoverMover = Instance.new("BodyPosition")
        HoverMover.Name = "MeleeMasteryHover"
        HoverMover.MaxForce = Vector3.new(2e5, 3.5e5, 2e5) -- Y um pouco mais forte
        HoverMover.P = 9000
        HoverMover.D = 2000
        HoverMover.Position = position
        HoverMover.Parent = root
    else
        HoverMover.Position = position
    end
end

RecoverIfBelowWorld = function()
    local _, humanoid, root = GetCharacterParts()
    if not root then return end

    local safeCFrame = LastSafeCFrame or (Config and Config.SpawnPoints and Config.SpawnPoints[1])
    if root.Position.Y < 3 and safeCFrame then
        SetNoclip(false)
        StopHover()
        StopFlight()
        root.CFrame = safeCFrame + Vector3.new(0, 8, 0)
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        if humanoid then
            pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end)
        end
    end
end

local function MoveTo(cf)
    local _, _, root = GetCharacterParts()
    if not root or not Enabled or not IsCurrentSession() then return false end
    if (root.Position - cf.Position).Magnitude <= 10 then
        SetNoclip(false)
        return true
    end

    StopHover()
    MoveToken += 1
    local token = MoveToken
    local destination = cf.Position
    local rotation = cf.Rotation

    SetNoclip(true)
    local cruiseY = math.max(root.Position.Y, destination.Y) + 40
    local liftPoint = Vector3.new(root.Position.X, cruiseY, root.Position.Z)
    local cruisePoint = Vector3.new(destination.X, cruiseY, destination.Z)

    local success = MoveSegment(liftPoint, rotation, token)
    if success then success = MoveSegment(cruisePoint, rotation, token) end
    if success then success = MoveSegment(destination, rotation, token) end

    StopFlight()
    -- Noclip é apenas de viagem. Restaurar colisões mesmo se o farm continuar ON.
    SetNoclip(false)

    if success then
        local _, _, finalRoot = GetCharacterParts()
        if finalRoot and (finalRoot.Position - destination).Magnitude <= 8 then
            finalRoot.AssemblyLinearVelocity = Vector3.zero
            finalRoot.AssemblyAngularVelocity = Vector3.zero
        end
    end
    return success
end


local function FarmLoop(token, mode)
    if not Config then
        Enabled = false
        ActiveMode = nil
        LoopToken += 1
        MoveToken += 1
        CurrentTarget = nil
        if RestoreTargetHitbox then RestoreTargetHitbox() end
        StopHover()
        StopFlight()
        SetNoclip(false)
        StopVelocityClamp()
        Toggle.Text = "Missão por nível: OFF"
        Toggle.BackgroundColor3 = Color3.fromRGB(42, 48, 61)
        BossToggle.Text = "Kill Big Moon: OFF"
        BossToggle.BackgroundColor3 = Color3.fromRGB(42, 48, 61)
        Status.Text = "Escolha SEA 1, SEA 2 ou SEA 3 acima"
        return
    end

    local route = mode == "quest" and GetQuestRoute(GetPlayerLevel()) or nil
    if mode == "quest" and not route then
        Status.Text = "Não consegui ler seu nível ou encontrar uma missão para este mar."
        Status.TextColor3 = Color3.fromRGB(255, 170, 100)
    elseif mode == "boss" then
        Status.Text = "Kill Big Moon | sem missão; ataque manual"
        Status.TextColor3 = Color3.fromRGB(255, 205, 130)
    else
        Status.Text = Config.SeaName .. " | missão por nível | ataque manual"
        Status.TextColor3 = Color3.fromRGB(170, 220, 190)
        if route then
            CurrentQuestRoute = route
            ActiveTargetNames = route.Targets
            StartQuestIfNeeded(route, true)
        end
    end

    while Enabled and token == LoopToken and IsCurrentSession() do
        task.wait(0.12)
        local ok, failure = pcall(function()
            local character, humanoid, root = GetCharacterParts()
            if not (character and humanoid and root) then
                Status.Text = "Aguardando personagem carregar..."
                Status.TextColor3 = Color3.fromRGB(255, 190, 100)
                return
            end

            if mode == "boss" then
                -- No Blox Fruits atual o alvo conhecido parecido com Big Mom é Cake Queen.
                ActiveTargetNames = {"Big Moon", "Big Mom", "Cake Queen"}
            else
                -- Só troca a missão/alvos quando a missão anterior já fechou.
                if not QuestPanelVisible() then
                    local level = GetPlayerLevel()
                    local wantedRoute = GetQuestRoute(level)
                    if wantedRoute then
                        route = wantedRoute
                        CurrentQuestRoute = wantedRoute
                        ActiveTargetNames = wantedRoute.Targets
                        StartQuestIfNeeded(wantedRoute)
                    else
                        ActiveTargetNames = {}
                    end
                elseif CurrentQuestRoute then
                    route = CurrentQuestRoute
                    ActiveTargetNames = route.Targets
                elseif route then
                    ActiveTargetNames = route.Targets
                end
            end

            local target = GetTarget()
            if target then
                local targetRoot = target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart
                if targetRoot then
                    ExpandTargetHitbox(target)
                    local desiredPosition = Vector3.new(
                        targetRoot.Position.X + 4.5,
                        targetRoot.Position.Y + Height,
                        targetRoot.Position.Z
                    )
                    local distanceToHover = (root.Position - desiredPosition).Magnitude
                    if distanceToHover > 14 then
                        StopHover()
                        MoveTo(CFrame.new(desiredPosition))
                    else
                        SetNoclip(false)
                        HoldAtPosition(desiredPosition)
                    end

                    local modeText = mode == "boss" and "Kill Big Moon" or (route and route.Quest or "missão por nível")
                    Status.Text = modeText .. " | alvo: " .. target.Name .. " | hitbox local ampliada | ataque manual"
                    Status.TextColor3 = mode == "boss" and Color3.fromRGB(255, 205, 130) or Color3.fromRGB(170, 220, 190)
                end
            else
                CurrentTarget = nil
                if RestoreTargetHitbox then RestoreTargetHitbox() end
                StopHover()
                if mode == "boss" then
                    Status.Text = "Kill Big Moon | esperando Big Moon/Big Mom/Cake Queen aparecer..."
                    Status.TextColor3 = Color3.fromRGB(255, 205, 130)
                elseif route then
                    Status.Text = "Missão " .. route.Quest .. " | esperando aparecer: " .. table.concat(route.Targets, ", ")
                    Status.TextColor3 = Color3.fromRGB(170, 220, 190)
                else
                    Status.Text = "Aguardando leitura do nível/missão..."
                    Status.TextColor3 = Color3.fromRGB(255, 190, 100)
                end
            end
        end)

        if not ok then
            Enabled = false
            ActiveMode = nil
            LoopToken += 1
            MoveToken += 1
            CurrentTarget = nil
            CurrentQuestRoute = nil
            ActiveTargetNames = {}
            if RestoreTargetHitbox then RestoreTargetHitbox() end
            StopHover()
            StopFlight()
            SetNoclip(false)
            StopVelocityClamp()
            Toggle.Text = "Missão por nível: OFF"
            Toggle.BackgroundColor3 = Color3.fromRGB(42, 48, 61)
            BossToggle.Text = "Kill Big Moon: OFF"
            BossToggle.BackgroundColor3 = Color3.fromRGB(42, 48, 61)
            Status.Text = "Erro no loop: " .. string.sub(tostring(failure), 1, 120)
            Status.TextColor3 = Color3.fromRGB(255, 130, 130)
            return
        end
    end
end
local function StopActiveFarm()
    Enabled = false
    ActiveMode = nil
    LoopToken += 1
    MoveToken += 1
    CurrentTarget = nil
    CurrentQuestRoute = nil
    ActiveTargetNames = {}
    StopHover()
    StopFlight()
    SetNoclip(false)
    StopVelocityClamp()
    if RestoreTargetHitbox then RestoreTargetHitbox() end
    RecoverIfBelowWorld()
    Toggle.Text = "Missão por nível: OFF"
    Toggle.BackgroundColor3 = Color3.fromRGB(42, 48, 61)
    BossToggle.Text = "Kill Big Moon: OFF"
    BossToggle.BackgroundColor3 = Color3.fromRGB(42, 48, 61)
    Status.Text = Config and (Config.SeaName .. " | pausado") or "Selecione um Sea"
    Status.TextColor3 = Color3.fromRGB(170, 180, 195)
end

local function StartActiveFarm(mode)
    if not Config then
        Status.Text = "Toque em SEA 1, SEA 2 ou SEA 3 acima"
        Status.TextColor3 = Color3.fromRGB(255, 170, 100)
        return
    end
    if Enabled then
        StopActiveFarm()
    end
    Enabled = true
    ActiveMode = mode
    LoopToken += 1
    local myToken = LoopToken
    CurrentTarget = nil
    CurrentQuestRoute = mode == "quest" and GetQuestRoute(GetPlayerLevel()) or nil
    ActiveTargetNames = CurrentQuestRoute and CurrentQuestRoute.Targets or {}
    if mode == "quest" then lastQuestAttempt = 0 end
    SetNoclip(false)
    StartVelocityClamp()
    StopHover()
    StopFlight()
    if RestoreTargetHitbox then RestoreTargetHitbox() end

    if mode == "quest" then
        Toggle.Text = "Missão por nível: ON"
        Toggle.BackgroundColor3 = Color3.fromRGB(26, 123, 91)
        BossToggle.Text = "Kill Big Moon: OFF"
        BossToggle.BackgroundColor3 = Color3.fromRGB(42, 48, 61)
        local level = GetPlayerLevel()
        Status.Text = "Missão por nível | level " .. tostring(level or "?") .. " | ataque manual"
    else
        Toggle.Text = "Missão por nível: OFF"
        Toggle.BackgroundColor3 = Color3.fromRGB(42, 48, 61)
        BossToggle.Text = "Kill Big Moon: ON"
        BossToggle.BackgroundColor3 = Color3.fromRGB(160, 93, 35)
        ActiveTargetNames = {"Big Moon", "Big Mom", "Cake Queen"}
        Status.Text = "Kill Big Moon | sem missão | ataque manual"
    end
    Status.TextColor3 = mode == "boss" and Color3.fromRGB(255, 205, 130) or Color3.fromRGB(170, 220, 190)
    task.spawn(FarmLoop, myToken, mode)
end

Toggle.Activated:Connect(function()
    if Enabled and ActiveMode == "quest" then
        StopActiveFarm()
    else
        StartActiveFarm("quest")
    end
end)

BossToggle.Activated:Connect(function()
    if Enabled and ActiveMode == "boss" then
        StopActiveFarm()
    else
        StartActiveFarm("boss")
    end
end)
local function SetupCharacter(character)
    task.wait(0.5)
    if not IsCurrentSession() then return end
    StopHover()
    StopFlight()
    SetNoclip(false)
    CurrentTarget = nil
    if RestoreTargetHitbox then RestoreTargetHitbox() end

    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") and OriginalCollision[part] ~= nil then
            part.CanCollide = OriginalCollision[part]
            OriginalCollision[part] = nil
        end
    end
    RecoverIfBelowWorld()

    if Enabled then
        SetNoclip(false)
        StartVelocityClamp()
        LoopToken += 1
        task.spawn(FarmLoop, LoopToken, ActiveMode)
    end
end

Player.CharacterAdded:Connect(SetupCharacter)

SharedEnvironment.__MeleeMasteryCleanup = function()
    Enabled = false
    LoopToken += 1
    MoveToken += 1
    CurrentTarget = nil
    CurrentQuestRoute = nil
    ActiveTargetNames = {}
    StopHover()
    StopFlight()
    SetNoclip(false)
    StopVelocityClamp()
    if RestoreTargetHitbox then RestoreTargetHitbox() end
    RecoverIfBelowWorld()
    if NoclipConnection then
        pcall(function() NoclipConnection:Disconnect() end)
        NoclipConnection = nil
    end
    if GUI and GUI.Parent then
        GUI:Destroy()
    end
end

print("[QuestFollower] missão por nível + Kill Big Moon carregado; ataques sempre manuais.")
