if game.PlaceId ~= 97598239454123 then
    return
end

if _G.SerenityHubGag2Loaded then
    return
end

_G.SerenityHubGag2Loaded = true

local player = game.Players.LocalPlayer
if not player then return end

repeat task.wait() until game:IsLoaded()
local character = player.Character or player.CharacterAdded:Wait()

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local MainWindow = WindUI:CreateWindow({
    Title = "Serenity Hub",
    Icon = "moon-star",
    Author = "by mistlemistt",
    Folder = "Serenity_GrowAGarden2",
    Background = "rbxassetid://110050114906960",

    Size = UDim2.fromOffset(620, 375),
    MinSize = Vector2.new(600, 350),
    MaxSize = Vector2.new(850, 560),
    Transparent = true,
    Theme = "Dark",
    Resizable = false,
    SideBarWidth = 175,
    BackgroundImageTransparency = 1,
    HideSearchBar = true,
    ScrollBarEnabled = false,

    User = {
        Enabled = true,
        Anonymous = false,

        Name = player.DisplayName,
        Avatar = game.Players:GetUserThumbnailAsync(
            player.UserId,
            Enum.ThumbnailType.HeadShot,
            Enum.ThumbnailSize.Size100x100
        ),

        Callback = function()
        end,
    },
})

local perfTag = MainWindow:Tag({
    Title = "FPS: 0 | Ping: 0 ms",
    Color = Color3.fromHex("#ED638A"),
    Radius = 9,
})

MainWindow:Tag({
    Title = "v" .. game.PlaceVersion,
    Radius = 9,
    Color = Color3.fromHex("#6A5ACD")
})

MainWindow:EditOpenButton({
    Title = "Serenity",
    Icon = "moon-star",
    CornerRadius = UDim.new(0, 13),
    StrokeThickness = 2,
    Color = ColorSequence.new(
        Color3.fromHex("FF0F7B"),
        Color3.fromHex("F89B29")
    ),
    OnlyMobile = false,
    Enabled = true,
    Draggable = true,
})

local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

task.spawn(function()
    while task.wait(1) do
        local fps = math.floor(1 / RunService.RenderStepped:Wait())

        local pingStat = Stats.Network.ServerStatsItem["Data Ping"]
        local ping = pingStat and math.floor(pingStat:GetValue()) or 0

        local desc = string.format("FPS: %d | Ping: %d ms", fps, ping)
        perfTag:SetTitle(desc)
    end
end)

local config = {
    antiAFK = false,
    autoReconnect = false,
    fpsBoost = false,
    autoOpenInfiniteYield = false,
    autoOpenSpeedHubX = false
}

local HttpService = game:GetService("HttpService")

local configFolder = "Serenity_GrowaGarden2"
local configFile = configFolder .. "/GrowaGarden2Config.json"

local function saveConfig()
    if not isfolder(configFolder) then
        makefolder(configFolder)
    end
    writefile(configFile, HttpService:JSONEncode(config))
end

local function loadConfig()
    if isfile(configFile) then
        config = HttpService:JSONDecode(readfile(configFile))
    end
end

loadConfig()

local Tab = MainWindow:Tab({
    Title = "Script",
    Icon = "scroll",
    Locked = false,
})

Tab:Select()

local antiAFKState = config.antiAFK
local antiAfkLoop = nil

local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local VirtualUser = game:GetService("VirtualUser")

local function disableIdledConnections()
    for _, v in pairs(getconnections(localPlayer.Idled)) do
        v:Disable()
    end
end

local function startAntiAfkLoop()
    if antiAfkLoop then return end
    antiAfkLoop = task.spawn(function()
        while antiAFKState do
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
            task.wait(60)
        end
        antiAfkLoop = nil
    end)
end

local antiAFKToggle = Tab:Toggle({
    Title = "Anti AFK",
    Desc = "Prevents idle kicks and keeps your session active.",
    Box = true,
    Default = config.antiAFK,
    Callback = function(state)
        antiAFKState = state

        if state then
            disableIdledConnections()
            startAntiAfkLoop()
        end

        config.antiAFK = state
        saveConfig()
    end
})

antiAFKToggle:Set(config.antiAFK)

if config.antiAFK then
    disableIdledConnections()
    startAntiAfkLoop()
end

local autoReconnectState = config.autoReconnect

local function startReconnectLoop()
    task.spawn(function()
        local ts = game:GetService("TeleportService")

        repeat task.wait() until game.CoreGui:FindFirstChild("RobloxPromptGui")
        local po = game.CoreGui.RobloxPromptGui:FindFirstChild("promptOverlay")

        if po then
            po.ChildAdded:Connect(function(a)
                if autoReconnectState and a.Name == "ErrorPrompt" then
                    while autoReconnectState do
                        ts:Teleport(game.PlaceId)
                        task.wait(2)
                    end
                end
            end)
        end
    end)
end

local autoReconnectToggle = Tab:Toggle({
    Title = "Auto Reconnect",
    Desc = "Automatically reconnects you if you get disconnected from the game.",
    Box = true,
    Default = config.autoReconnect,
    Callback = function(state)
        autoReconnectState = state

        if state then
            startReconnectLoop()
        end

        config.autoReconnect = state
        saveConfig()
    end
})

autoReconnectToggle:Set(config.autoReconnect)

if config.autoReconnect then
    startReconnectLoop()
end

local fpsBoostConnections = {}
local gardens = workspace:WaitForChild("Gardens")

local function clearGardens()
    local gardens = workspace:FindFirstChild("Gardens")
    if not gardens then return end

    for _, obj in ipairs(gardens:GetDescendants()) do
        if obj:IsA("BasePart") then
            local mailbox = obj:FindFirstAncestor("GreyMailBox")
            if not mailbox then
                obj:Destroy()
            end
        end
    end
end

local function applyFPSBoost(state)
    if state then
        clearGardens()

        table.insert(fpsBoostConnections,
            gardens.DescendantAdded:Connect(function(obj)
                if obj:IsA("BasePart") then
                    if not obj:FindFirstAncestor("GreyMailBox") then
                        obj:Destroy()
                    end
                end
            end)
        )

        table.insert(fpsBoostConnections,
            Players.PlayerAdded:Connect(function()
                task.wait(1)
                clearGardens()
            end)
        )

    else
        for _, c in ipairs(fpsBoostConnections) do
            c:Disconnect()
        end
        table.clear(fpsBoostConnections)
    end
end

local fpsBoostToggle = Tab:Toggle({
    Title = "FPS Boost",
    Desc = "Improves performance by removing parts.\n(To fully restore visuals, rejoin the game after disabling.)",
    Box = true,
    Default = config.fpsBoost,
    Callback = function(state)
        applyFPSBoost(state)
        config.fpsBoost = state
        saveConfig()
    end
})

fpsBoostToggle:Set(config.fpsBoost)

if config.fpsBoost then
    applyFPSBoost(true)
end

local function openInfiniteYield()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
end

local infiniteYieldToggle = Tab:Toggle({
    Title = "Auto Open Infinite Yield",
    Desc = "Loads the Infinite Yield script.\nUse this only if Infinite Yield is not already in your autoexec folder.",
    Box = true,
    Default = config.autoOpenInfiniteYield,
    Callback = function(state)
        if state then
            openInfiniteYield()
        end
        config.autoOpenInfiniteYield = state
        saveConfig()
    end
})

infiniteYieldToggle:Set(config.autoOpenInfiniteYield)

if config.autoOpenInfiniteYield then
    openInfiniteYield()
end 

local function openSpeedHubX()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/AhmadV99/Speed-Hub-X/main/Speed%20Hub%20X.lua", true))()
end

local speedHubXToggle = Tab:Toggle({
    Title = "Auto Open Speed Hub X",
    Desc = "Loads the Speed Hub X script.\nUse this only if Speed Hub X is not already in your autoexec folder.",
    Box = true,
    Default = config.autoOpenSpeedHubX,
    Callback = function(state)
        if state then
            openSpeedHubX()
        end
        config.autoOpenSpeedHubX = state
        saveConfig()
    end
})

speedHubXToggle:Set(config.autoOpenSpeedHubX)

if config.autoOpenSpeedHubX then
    openSpeedHubX()
end

Tab:Button({
    Title = "Enable Walk Fling",
    Icon = "mouse-pointer-2",
    Callback = function()
        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local LocalPlayer = Players.LocalPlayer

        local function startWalkFling(char)
            local Root = char:WaitForChild("HumanoidRootPart")
            local Humanoid = char:WaitForChild("Humanoid")
            
            Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
            Humanoid.BreakJointsOnDeath = false
            
            game:GetService("RunService").Stepped:Connect(function()
                Humanoid.Health = math.huge
                Humanoid.MaxHealth = math.huge
            end)
            
            walkflinging = true
            Root.CanCollide = false
            Humanoid:ChangeState(11)
            
            task.spawn(function()
                while walkflinging and Root and Root.Parent do
                    RunService.Heartbeat:Wait()
                    local vel = Root.Velocity
                    Root.Velocity = vel * 99999999 + Vector3.new(0, 99999999, 0)
                    RunService.RenderStepped:Wait()
                    Root.Velocity = vel
                    RunService.Stepped:Wait()
                    Root.Velocity = vel + Vector3.new(0, 0.1, 0)
                end
            end)
        end

        if LocalPlayer.Character then
            startWalkFling(LocalPlayer.Character)
        end

        LocalPlayer.CharacterAdded:Connect(startWalkFling)

        WindUI:Notify({
            Title = "Script Settings",
            Content = "Enabled Walk Fling!",
            Icon = "bell",
            Duration = 3
        })
    end
})

Tab:Button({
    Title = "Rejoin Current Server",
    Icon = "refresh-cw",
    Box = true,
    Callback = function()

        local success, err = pcall(function()
            game:GetService("TeleportService"):Teleport(game.PlaceId, player)
        end)

        if success then
            WindUI:Notify({
                Title = "Script Settings",
                Content = "Rejoining current server...",
                Icon = "bell",
                Duration = 3
            })
        else
            WindUI:Notify({
                Title = "Script Settings",
                Content = "Failed to rejoin server: " .. tostring(err),
                Icon = "bell",
                Duration = 3
            })
        end
    end
})
