local DefaultCFG = {
    AutoStart            = true,
    AntiAFK              = true,
    MuteAudio            = true,
    FPSBoost             = true,
    FPSLock              = 60,
    Disable3D            = false,
    DeleteWorld        = false,
    ShowOverlay          = false,
    OverlayIcon          = "",
    SerenityLog          = false,
    ApiToken             = "",

    AutoRoll             = true,
    HideCutscene         = true,
    AutoEquipBest        = true,
    AutoSell             = true,
    AutoSellValue = "1sx",
    
    AutoRollHalloweenDice = true,
	AutoSellHalloweenDice = true,
	HalloweenDiceAutoSellUnits = {
	    ["Mummy Loffy"] = true,
	    ["Skeleton Sanjo"] = true,
	    ["Reaper Ichiga"] = true,
	    ["Frank Todoraki"] = true,
	    ["Ghoul Kanike"] = true,
	    ["Ghost Rengok"] = true,
	    ["Devil Sakune"] = true,
	    ["Bat Hinita"] = true,
	    ["Scarecrow Usop"] = true,
	    ["Candy Chopa"] = true,
	    ["Werecat Yoruchi"] = true,
	    ["Plague Levo"] = false,
	    ["Pumpkin Bakugi"] = false,
	    ["Ghost Nezuka"] = false,
	    ["Witch Erzo"] = false,
	    ["Witch Namee"] = false,
	    ["Vampire Gujo"] = false,
		["Phantom Goko"] = false
	},

    AutoUpgrade          = true,
    UpgradePriority      = "balance",
    AutoDice             = true,
    AutoRebirth          = true,

    AutoCollect          = true,
    AutoLevelUnit        = true,
    MaxUnitLevel         = 15,
    AutoQuest            = true,
    AutoTrickOrTreat = true,
    AutoTower            = true,
    TowerMode            = "smart",
    AutoReward           = true,
    AutoBoost            = true,
    AutoRedeemCode       = true,
    RedeemCode           = true,

    AutoGrade            = true,
    TargetGrade          = "A",
    GradeMinGemsReserve  = 0,

    AutoTrade            = false,
    TradeHost            = "",
    TradeMembers         = {},
    TradeCooldown        = 15,

    TradeGems            = true,
    TradeMinGems         = 100,
    TradeTraits          = true,
    TradeMinTraits       = 100,
    TradeTickets         = false,
    TradePotions         = false,
    TradeSpins           = false,

    TradeUnits           = false,
    TradeMinUnits        = 5,
    TradeMinUnitIncome   = "1e12",
    TradeMaxUnitIncome   = 0,
    TradeKeepSlotted     = true,
    TradeSendMode        = "keep_slotted",
}

local env = (getgenv and getgenv()) or _G
local externalConfig = env.KaitunConfig or env.CFG or {}
local CFG = {}
for k, v in pairs(DefaultCFG) do
    if externalConfig[k] ~= nil then
        CFG[k] = externalConfig[k]
    else
        CFG[k] = v
    end
end

if externalConfig.RedeemCode ~= nil then
    CFG.AutoRedeemCode = externalConfig.RedeemCode
    CFG.RedeemCode = externalConfig.RedeemCode
elseif externalConfig.AutoRedeemCode ~= nil then
    CFG.AutoRedeemCode = externalConfig.AutoRedeemCode
    CFG.RedeemCode = externalConfig.AutoRedeemCode
end

if not CFG.AutoStart then return end

do
    if env and env.XDFLEX_KAITUN_CLEANUP then
        pcall(env.XDFLEX_KAITUN_CLEANUP)
    end
    pcall(function()
        local function SafeDestroy(inst)
            pcall(function() if inst and inst.Parent then inst:Destroy() end end)
        end
        local cg = game:GetService("CoreGui")
        for _, v in ipairs(cg:GetChildren()) do
            if v.Name == "XDFLEX_Kaitun_Overlay" then SafeDestroy(v) end
        end
        if typeof(gethui) == "function" then
            local h = gethui()
            if h then
                for _, v in ipairs(h:GetChildren()) do
                    if v.Name == "XDFLEX_Kaitun_Overlay" then SafeDestroy(v) end
                end
            end
        end
        local lp = game:GetService("Players").LocalPlayer
        local pg = lp and lp:FindFirstChild("PlayerGui")
        if pg then
            for _, v in ipairs(pg:GetChildren()) do
                if v.Name == "XDFLEX_Kaitun_Overlay" then SafeDestroy(v) end
            end
        end
    end)
end

local activeCleanupHooks = {}

local Players           = game:GetService("Players")
local Workspace         = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local HttpService       = game:GetService("HttpService")
local VirtualUser       = game:GetService("VirtualUser")
local GuiService        = game:GetService("GuiService")
local TeleportService   = game:GetService("TeleportService")
local PathfindingService = game:GetService("PathfindingService")
local CollectionService = game:GetService("CollectionService")

local LocalPlayer = Players.LocalPlayer
local PlaceId     = game.PlaceId

local tradeSession = {
    active = false,
    phase = "None",
    partner = nil,
    ownReady = false,
    otherReady = false,
    ownAccepted = false,
    otherAccepted = false,
    offered = false,
    lastAction = 0,
    cooldownUntil = 0
}

local function GetSafeUIContainer()
    local container = nil
    if typeof(gethui) == "function" then
        pcall(function()
            local res = gethui()
            if typeof(res) == "Instance" then container = res end
        end)
    end
    if not container then
        pcall(function()
            local cg = game:GetService("CoreGui")
            if typeof(cg) == "Instance" then container = cg end
        end)
    end
    if not container then
        pcall(function()
            container = LocalPlayer:WaitForChild("PlayerGui", 5)
        end)
    end
    return container or (LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")) or game:GetService("CoreGui")
end

local function FormatNumber(n)
    n = tonumber(n) or 0
    if n >= 1e12 then
        return string.format("%.2fT", n / 1e12)
    elseif n >= 1e9 then
        return string.format("%.2fB", n / 1e9)
    elseif n >= 1e6 then
        return string.format("%.2fM", n / 1e6)
    elseif n >= 1e3 then
        return string.format("%.1fK", n / 1e3)
    else
        return tostring(math.floor(n))
    end
end

if CFG.MuteAudio then
    pcall(function()
        UserSettings().GameSettings.MasterVolume = 0
    end)
    local muteConn = RunService.Heartbeat:Connect(function()
        pcall(function()
            if UserSettings().GameSettings.MasterVolume > 0 then
                UserSettings().GameSettings.MasterVolume = 0
            end
        end)
    end)
    table.insert(activeCleanupHooks, function() muteConn:Disconnect() end)
end

if CFG.Disable3D then
    local overlay = Instance.new("ScreenGui")
    overlay.IgnoreGuiInset = true
    overlay.ResetOnSpawn = false
    overlay.DisplayOrder = -1
    overlay.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

    local black = Instance.new("Frame")
    black.Size = UDim2.fromScale(1, 1)
    black.BackgroundColor3 = Color3.new(0, 0, 0)
    black.BorderSizePixel = 0
    black.Parent = overlay

    pcall(function()
        RunService:Set3dRenderingEnabled(false)
    end)
end

if CFG.FPSLock and typeof(setfpscap) == "function" and CFG.FPSLock > 0 then
	pcall(function() setfpscap(CFG.FPSLock) end)
end

local function hideProductUI()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    local root = pg and pg:FindFirstChild("Root")
    local hud = root and root:FindFirstChild("HUD")
    local pd = hud and hud:FindFirstChild("ProductDisplay")
    if not pd then return end

    for _, name in ipairs({"JackpotRoll", "Gamepasses"}) do
        local g = pd:FindFirstChild(name)
        if g then g.Visible = false end
    end
end

if CFG.DeleteWorld then
    local map = workspace:FindFirstChild("Map")
    if map then map:Destroy() end

    local mapConn = workspace.ChildAdded:Connect(function(child)
        if child.Name == "Map" then child:Destroy() end
    end)
    table.insert(activeCleanupHooks, function() mapConn:Disconnect() end)

    local uiTask = task.spawn(function()
        while task.wait(1) do
            pcall(hideProductUI)
        end
    end)
    table.insert(activeCleanupHooks, function() pcall(task.cancel, uiTask) end)
end

if CFG.FPSBoost then
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        local Lighting = game:GetService("Lighting")
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        Lighting.Brightness = 1
        for _, v in ipairs(Lighting:GetChildren()) do
            if v:IsA("PostProcessEffect") or v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("BloomEffect") or v:IsA("DepthOfFieldEffect") then
                v.Enabled = false
            end
        end
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("BasePart") and not v:IsA("MeshPart") then
                v.Material = Enum.Material.SmoothPlastic
                v.CastShadow = false
            elseif v:IsA("Decal") or v:IsA("Texture") then
                v.Transparency = 1
            elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") then
                v.Enabled = false
            end
        end
        local fpsConn = Workspace.DescendantAdded:Connect(function(v)
            pcall(function()
                if v:IsA("BasePart") and not v:IsA("MeshPart") then
                    v.Material = Enum.Material.SmoothPlastic
                    v.CastShadow = false
                elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") then
                    v.Enabled = false
                end
            end)
        end)
        table.insert(activeCleanupHooks, function() fpsConn:Disconnect() end)
    end)
end

local DataController   = require(ReplicatedStorage.Framework.Features.Data.DataController)
local BuffController   = require(ReplicatedStorage.Framework.Features.Buffs.BuffController)
local UpgradesConfig   = require(ReplicatedStorage.Framework.Features.Upgrades.Upgrades)
local TreeStructure    = require(ReplicatedStorage.Framework.Features.Upgrades.TreeStructure)
local DiceConfig       = require(ReplicatedStorage.Framework.Features.Rolling.Dice)
local RebirthsConfig   = require(ReplicatedStorage.Framework.Features.Rebirth.Rebirths)
local TowersConfig     = require(ReplicatedStorage.Framework.Features.Towers.Towers)
local TowerController  = require(ReplicatedStorage.Framework.Features.Towers.TowerController)
local QuestConfig      = require(ReplicatedStorage.Framework.Features.Quests.QuestConfig)
local SellUtil         = require(ReplicatedStorage.Framework.Features.Selling.SellUtil)
local EntryRegistry    = require(ReplicatedStorage.Framework.Features.Inventory.EntryRegistry)
local UnitUtil         = require(ReplicatedStorage.Framework.Features.Inventory.Kinds.Unit.UnitUtil)
local BoostConfig      = require(ReplicatedStorage.Framework.Features.Inventory.Kinds.Boost.BoostConfig)
local TradeConfig      = require(ReplicatedStorage.Framework.Features.Trading.TradeConfig)
local GradesConfig     = require(ReplicatedStorage.Framework.Features.Grades.Grades)
local NumberFormatter = require(ReplicatedStorage.Packages.NumberFormatter)
local HalloweenQuests = require(ReplicatedStorage.Framework.Features.Halloween.HalloweenQuests)
local PumpkinDiceConfig = require(ReplicatedStorage.Framework.Features.Halloween.PumpkinDice)

local Network              = ReplicatedStorage.Network
local UpdateAutoSellRE  = Network.SellService.RE.UpdateAutoSell
local RollServiceRF        = Network.RollService.RF.RollDice
local RollServiceRE        = Network.RollService.RE.SetAutoRoll
local PlotCollectRE        = Network.PlotService.RE.CollectBalance
local PlotEquipBestRE      = Network.PlotService.RE.EquipBest
local LevelUpSlotRE        = Network.PlotService.RE.LevelUpSlot
local RebirthRE            = Network.RebirthService.RE.Rebirth
local BuyUpgradeRE         = Network.RE.BuyUpgrade
local BuyDiceRE            = Network.DiceShopService.RE.BuyDice
local EquipDiceRE          = Network.DiceShopService.RE.EquipDice
local SellInventoryRF      = Network.SellService.RF.SellInventory
local PlayTowerRF          = Network.Towers.RF.PlayTower
local CompleteTowerFloorRF = Network.Towers.RF.CompleteTowerFloor
local CancelTowerRF        = Network.Towers.RF.CancelTower
local EquipBestTowerRE     = Network.Towers.RE.EquipBestTowerTeam
local QuestClaimRE         = Network.QuestService.RE.Claim
local OfflineEarningsRE    = Network.OfflineEarningsService.RE.Claim
local DailyRewardRE        = Network.DailyRewardService.RE.Claim
local BoostServiceRE       = Network.BoostService.RE.Use
local RedeemCodeRE         = (Network:FindFirstChild("MonetizationService") and Network.MonetizationService:FindFirstChild("RE") and Network.MonetizationService.RE:FindFirstChild("RedeemCode")) or nil
local ClaimAllPath = Network.HalloweenService.RE.ClaimAllPath
local HalloweenQuestClaimRE = Network.HalloweenQuestService.RE.Claim
local HalloweenDiceAutoSellRE = Network.PumpkinDiceService.RE.SetAutoSell

local function SyncHalloweenDiceAutoSell(data)
    if not CFG.AutoSellHalloweenDice then
        return
    end

    local halloween = data and data.Halloween
    local current = halloween and halloween.DiceAutoSell

    if type(current) ~= "table" then
        return
    end

    for unitName, desired in pairs(
        CFG.HalloweenDiceAutoSellUnits or {}
    ) do
        desired = desired == true

        if current[unitName] ~= desired then
            HalloweenDiceAutoSellRE:FireServer(unitName, desired)
            task.wait(0.1)
        end
    end
end

local DEFAULT_REDEEM_CODES = {
	"Halloween",
	"50KCCU",
	"sorry4delay",
	"UPDATE7",
	"UPDATE6",
	"400KLIKES",
	"250KLIKES",
	"UPDATE5",
	"100KLIKES",
	"40KCCU",
	"30KCCU",
    "UPDATE4",
    "20KCCU",
    "10KCCU",
    "5KCCU",
    "1KCCU",
    "UPDATE3",
    "UPDATE2",
    "UPDATE1",
    "RELEASE",
}

local ClientComm                    = require(ReplicatedStorage.Packages.Network).ClientComm
local TradeComm                     = ClientComm.new(ReplicatedStorage.Network, false, "TradeService")
local TradeSignalRequestTrade       = TradeComm:GetSignal("RequestTrade")
local TradeSignalRespondToRequest   = TradeComm:GetSignal("RespondToRequest")
local TradeSignalChangeOffer        = TradeComm:GetSignal("ChangeOffer")
local TradeSignalAdvanceTrade       = TradeComm:GetSignal("AdvanceTrade")
local TradeSignalCancelTrade        = TradeComm:GetSignal("CancelTrade")
local TradeSignalEvent              = TradeComm:GetSignal("TradeEvent")

local GradeComm                     = ClientComm.new(ReplicatedStorage.Network, false, "GradeService")
local GradeSignalRoll               = GradeComm:GetSignal("Roll")

local QuestComm                     = ClientComm.new(ReplicatedStorage.Network, false, "QuestService")
local QuestSignalBuy                = QuestComm:GetSignal("Buy")

local HalloweenQuestComm = ClientComm.new(ReplicatedStorage.Network,bfalse, "HalloweenQuestService")
local HalloweenQuestClaim = HalloweenQuestComm:GetSignal("Claim")

local PumpkinDiceComm = ClientComm.new(Network, false, "PumpkinDiceService")
local PumpkinDiceRoll = PumpkinDiceComm:GetFunction("Roll")

local OverlayUI = {}
local StartTime = os.time()
local CurrentRunningTower = "None"
local CurrentTowerFloor = 0

if CFG.ShowOverlay then
    local okOverlay, errOverlay = pcall(function()
        local screen = Instance.new("ScreenGui")
        screen.Name = "XDFLEX_Kaitun_Overlay"
        screen.ResetOnSpawn = false
        screen.DisplayOrder = 999
        screen.IgnoreGuiInset = true -- true screen center (no 36px topbar offset)
        if CFG.Disable3D then
            screen.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
        else
            screen.Parent = GetSafeUIContainer()
        end

        local frame = Instance.new("Frame")
        frame.Name = "CenterFloatingHUD"
        frame.AnchorPoint = Vector2.new(0.5, 0.5)
        frame.Position = UDim2.new(0.5, 0, 0.5, 0)
        frame.Size = UDim2.new(0, 580, 0, 140) -- fits the 5 lines exactly so it centers
        frame.BackgroundTransparency = 1
        frame.BorderSizePixel = 0
        frame.Active = false
        frame.Draggable = false
        frame.Parent = screen

        local function CreateCenterText(name, text, size, color, yPos, isTitle)
            local lbl = Instance.new("TextLabel")
            lbl.Name = name
            lbl.Text = text
            lbl.Font = isTitle and Enum.Font.GothamBlack or Enum.Font.GothamBold
            lbl.TextSize = size
            lbl.TextColor3 = color
            lbl.TextXAlignment = Enum.TextXAlignment.Center
            lbl.Position = UDim2.new(0, 0, 0, yPos)
            lbl.Size = UDim2.new(1, 0, 0, size + 6)
            lbl.BackgroundTransparency = 1

            local stroke = Instance.new("UIStroke")
            stroke.Thickness = isTitle and 3.2 or 2.6
            stroke.Color = Color3.fromRGB(0, 0, 0)
            stroke.Parent = lbl

            lbl.Parent = frame
            return lbl
        end

        OverlayUI.TowerLabel       = CreateCenterText("Tower", "Tower : None : Floor 0", 20, Color3.fromRGB(255, 255, 255), 0, false)
        OverlayUI.RebirthDiceLabel = CreateCenterText("RebirthDice", "Rebirth : 0 • Dice : Basic", 19, Color3.fromRGB(255, 255, 255), 30, false)
        OverlayUI.StorageLabel     = CreateCenterText("Storage", "Storage : 0/100", 19, Color3.fromRGB(255, 255, 255), 59, false)
        OverlayUI.TokensLabel      = CreateCenterText("Tokens", "Gems : 0 • Trait : 0 • Ticket : 0", 19, Color3.fromRGB(255, 230, 120), 87, false)
        OverlayUI.RuntimeLabel     = CreateCenterText("Runtime", "Runtime : 00:00:00", 17, Color3.fromRGB(220, 220, 220), 116, false)

        table.insert(activeCleanupHooks, function()
            pcall(function() screen:Destroy() end)
        end)
    end)
    if not okOverlay then warn("[Kaitun] Overlay failed: " .. tostring(errOverlay)) end
end

local function GetStorageStats(data)
    local maxStorage = 100
    pcall(function() maxStorage = BuffController.GetBuff("Unit Storage") or 100 end)
    local unitCount = 0
    if data and data.Inventory then
        for _, item in pairs(data.Inventory) do
            local cfg = EntryRegistry.getEntryConfig(item.name)
            if cfg and cfg.kind == "Unit" then
                unitCount = unitCount + 1
            end
        end
    end
    return unitCount, maxStorage
end

local function CalculateTotalPlotIncome(data)
    local total = 0
    if data and data.Slots and data.Inventory then
        for _, slot in pairs(data.Slots) do
            local uid = slot.unitId
            if uid and data.Inventory[uid] then
                local u = data.Inventory[uid]
                local cfg = EntryRegistry.getEntryConfig(u.name)
                if cfg and cfg.income then
                    total = total + (cfg.income(u.attributes) or 0)
                end
            end
        end
    end
    return total
end

local function GetBackpackItemStats(data)
    local gems = 0
    local traits = 0
    local tickets = 0

    if data and data.Inventory then
        for _, entry in pairs(data.Inventory) do
            if entry and entry.name then
                local cfg = EntryRegistry.getEntryConfig(entry.name)
                if not cfg or cfg.kind ~= "Unit" then
                    local name = string.lower(entry.name)
                    local amt = entry.amount or entry.count or 1
                    if name == "gems" or string.find(name, "gem") then
                        gems = gems + amt
                    elseif name == "trait reroll" or string.find(name, "trait") then
                        traits = traits + amt
                    elseif name == "tickets" or name == "ticket" or string.find(name, "ticket") then
                        tickets = tickets + amt
                    end
                end
            end
        end
    end

    return gems, traits, tickets
end

local function GetGradeOrder(gradeName)
    if not gradeName then return 0 end
    local gStr = tostring(gradeName)
    if GradesConfig and GradesConfig[gStr] and GradesConfig[gStr].order then
        return GradesConfig[gStr].order
    end

    local gradeOrderMap = {
        ["D"] = 1, ["C"] = 2, ["B"] = 3, ["A"] = 4, ["A+"] = 5,
        ["S"] = 6, ["S+"] = 7, ["Z"] = 8, ["Z+"] = 9, ["神"] = 10, ["GOD"] = 10
    }
    return gradeOrderMap[string.upper(gStr)] or gradeOrderMap[gStr] or 0
end

local function ParseIncomeValue(val)
    if typeof(val) == "number" then
        return val
    end
    if typeof(val) == "string" then
        local cleaned = string.lower(string.gsub(val, "%s+", ""))
        local directNum = tonumber(cleaned)
        if directNum then
            return directNum
        end

        local numStr, unit = string.match(cleaned, "^([%d%.]+)(%a*)$")
        local num = tonumber(numStr)
        if not num then return 0 end

        local multipliers = {
            k  = 1e3,
            m  = 1e6,
            b  = 1e9,
            t  = 1e12,
            qa = 1e15,
            q  = 1e15,
            qi = 1e18,
            sx = 1e21,
            sp = 1e24,
            oc = 1e27,
            no = 1e30,
            dc = 1e33,
        }
        if unit and multipliers[unit] then
            return num * multipliers[unit]
        end
        return num
    end
    return 0
end

if CFG.HideCutscene then
    local hideConn = RunService.Heartbeat:Connect(function()
        pcall(function()
            local root = LocalPlayer.PlayerGui:FindFirstChild("Root")
            if root then
                local rollingFolder = root:FindFirstChild("Rolling")
                if rollingFolder then
                    local frame = rollingFolder:FindFirstChild("Frame")
                    local bg    = rollingFolder:FindFirstChild("DarkBackground")
                    if frame and frame.Visible then frame.Visible = false end
                    if bg    and bg.Visible    then bg.Visible    = false end
                end

                local onboarding = root:FindFirstChild("Onboarding")
                if onboarding then
                    for _, child in ipairs(onboarding:GetChildren()) do
                        if child:IsA("GuiObject") and child.Visible then
                            child.Visible = false
                        end
                    end
                end

                local notifs = root:FindFirstChild("Notifications")
                local textNotifs = notifs and notifs:FindFirstChild("TextNotifications")
                if textNotifs then
                    for _, child in ipairs(textNotifs:GetChildren()) do
                        if child:IsA("GuiObject") and child.Name ~= "UIListLayout" and child.Visible then
                            local msg = child:FindFirstChild("Message")
                            if msg and msg:IsA("TextLabel") and string.find(string.lower(msg.Text), "1000") then
                                child.Visible = false
                            end
                        end
                    end
                end
            end
        end)
    end)
    table.insert(activeCleanupHooks, function() hideConn:Disconnect() end)
end

if CFG.AutoRoll then
    pcall(function() RollServiceRE:FireServer(false) end)
end

local farmEngine = task.spawn(function()
    local lastRoll        = 0
    local lastCollect     = 0
    local lastRebirth     = 0
    local lastEquipBest   = 0
    local lastLevelUnit   = 0
    local lastDiceCheck   = 0
    local lastUpgradeCheck= 0
    local lastQuestCheck  = 0
    local lastRewardCheck = 0
    local lastBoostCheck  = 0
    local lastCodeCheck   = 0
    local lastGradeRoll   = 0
    local lastHalloweenDiceRoll = 0
    local lastTicketShopCheck = 0
    local attemptedCodes  = {}
    local allCodesDone    = false
    local lastClaimAllPath = 0
    local lastHalloweenAutoSellSync = 0
    
    if CFG.AutoSell then
	    local rarity = NumberFormatter.ParseCompact(CFG.AutoSellValue)
	    if rarity then
	        UpdateAutoSellRE:FireServer(rarity)
	    end
	end

    while task.wait(0.08) do
        local now = os.clock()
        local data = DataController.___X
        local defaultRollAttempted = false

        if data then
			if now - lastHalloweenAutoSellSync >= 5 then
			    lastHalloweenAutoSellSync = now
			
			    pcall(function()
			        SyncHalloweenDiceAutoSell(data)
			    end)
			end

            local isTradingNow = tradeSession and tradeSession.active
            
            if CFG.AutoQuest and (now - lastClaimAllPath >= 60) then
			    lastClaimAllPath = now
			
			    pcall(function()
			        ClaimAllPath:FireServer()
			    end)
			end

			if CFG.AutoRoll and not isTradingNow and (now - lastRoll >= 0.11) then
			    lastRoll = now
			
			    pcall(function()
			        local uCount, maxStorage = GetStorageStats(data)
			        local freeSlots = maxStorage - uCount
			
			        if freeSlots > 1 then
			            defaultRollAttempted = true
			            RollServiceRF:InvokeServer()
			        end
			    end)
			end
			
			if CFG.AutoRollHalloweenDice
			    and not isTradingNow
			    and (now - lastHalloweenDiceRoll >= 2.1)
			then
			    pcall(function()
			        local multi = PumpkinDiceConfig.MULTI
			        local cost = PumpkinDiceConfig.COST * multi
			
					local inventory = data.Inventory
					local pumpkinEntry = inventory and inventory.Pumpkins
					local pumpkins = pumpkinEntry and pumpkinEntry.amount or 0
			
			        local uCount, maxStorage = GetStorageStats(data)
			        local freeSlots = maxStorage - uCount
			
			        if pumpkins >= cost and freeSlots >= multi then
			            lastHalloweenDiceRoll = now
			            PumpkinDiceRoll(multi)
			        end
			    end)
			end

            if CFG.AutoEquipBest and (now - lastEquipBest >= 3.0) then
                lastEquipBest = now
                pcall(function() PlotEquipBestRE:FireServer() end)
            end

            if CFG.AutoCollect and (now - lastCollect >= 0.5) then
                lastCollect = now
                pcall(function()
                    if data.Slots then
                        for slotIdx in pairs(data.Slots) do
                            PlotCollectRE:FireServer(tonumber(slotIdx))
                        end
                    end
                end)
            end

            if CFG.AutoLevelUnit and (now - lastLevelUnit >= 0.6) then
                lastLevelUnit = now
                pcall(function()
                    if not (data.Slots and data.Inventory) then return end
                    local money = data.Money or 0
                    for slotIdx, slotData in pairs(data.Slots) do
                        local uid = slotData.unitId
                        if uid then
                            local unit = data.Inventory[uid]
                            if unit then
                                local curLvl = (unit.attributes and unit.attributes.level) or 1
                                if curLvl < CFG.MaxUnitLevel then
                                    local ok, cost = pcall(function()
                                        return UnitUtil.GetLevelPrice(unit.name, unit.attributes)
                                    end)
                                    if ok and cost and money >= cost then
                                        LevelUpSlotRE:FireServer(tonumber(slotIdx))
                                        task.wait(0.04)
                                    end
                                end
                            end
                        end
                    end
                end)
            end

            if CFG.AutoRebirth and (now - lastRebirth >= 1.0) then
                lastRebirth = now
                pcall(function()
                    local cur = data.Rebirth or 0
                    local nxt = RebirthsConfig.GetNext(cur)
                    if nxt and (data.Money or 0) >= nxt.cost then
                        RebirthRE:FireServer()
                    end
                end)
            end

            if CFG.AutoDice and (now - lastDiceCheck >= 1.5) then
                lastDiceCheck = now
                pcall(function()
                    local owned = data.OwnedDice or {}
                    local bestDice, bestLuck = nil, -1
                    for dName in pairs(owned) do
                        local info = DiceConfig.Get(dName)
                        if info and info.luck and info.luck > bestLuck then
                            bestLuck = info.luck; bestDice = dName
                        end
                    end
                    if bestDice and data.Dice ~= bestDice then
                        EquipDiceRE:FireServer(bestDice)
                    end

                    local money = data.Money or 0
                    local allDice = DiceConfig.GetAll()
                    local candidates = {}
                    for dName, dInfo in pairs(allDice) do
                        if not owned[dName] and dInfo.price and dInfo.price <= money then
                            table.insert(candidates, {name = dName, price = dInfo.price, luck = dInfo.luck or 0})
                        end
                    end
                    table.sort(candidates, function(a, b) return a.luck > b.luck end)
                    if #candidates > 0 then
                        BuyDiceRE:FireServer(candidates[1].name)
                    end
                end)
            end

            if CFG.AutoUpgrade and (now - lastUpgradeCheck >= 0.8) then
                lastUpgradeCheck = now
                pcall(function()
                    local ownedUpgrades = data.Upgrades or {}
                    local money         = data.Money or 0
                    local buyList       = {}

                    for upgName, upgInfo in pairs(UpgradesConfig) do
                        if not ownedUpgrades[upgName] and upgInfo.price and upgInfo.price <= money then
                            local parent = TreeStructure.GetParent(upgName)
                            local parentUnlocked = (not parent) or (parent == "Start") or (ownedUpgrades[parent] == true)
                            if parentUnlocked then
                                table.insert(buyList, {
                                    name  = upgName,
                                    price = upgInfo.price,
                                    cat   = upgInfo.category or "General"
                                })
                            end
                        end
                    end

                    if #buyList > 0 then
                        if CFG.UpgradePriority ~= "balance" then
                            table.sort(buyList, function(a, b)
                                local aP = (string.find(string.lower(a.name), string.lower(CFG.UpgradePriority)) or string.find(string.lower(a.cat), string.lower(CFG.UpgradePriority))) and 1 or 0
                                local bP = (string.find(string.lower(b.name), string.lower(CFG.UpgradePriority)) or string.find(string.lower(b.cat), string.lower(CFG.UpgradePriority))) and 1 or 0
                                if aP ~= bP then return aP > bP end
                                return a.price < b.price
                            end)
                        else
                            table.sort(buyList, function(a, b) return a.price < b.price end)
                        end
                        BuyUpgradeRE:FireServer(buyList[1].name)
                    end
                end)
            end

			if CFG.AutoQuest and (now - lastQuestCheck >= 2.0) then
			    lastQuestCheck = now
			
			    pcall(function()
			        local questsData = data.Quests or {}
			
			        for pName, pConfig in pairs(QuestConfig.Periods) do
			            local userPeriod = questsData[pName]
			
			            if userPeriod then
			                for _, q in ipairs(pConfig.quests) do
			                    local prog = (userPeriod.progress and userPeriod.progress[q.id]) or 0
			                    local claimed = userPeriod.claimed and userPeriod.claimed[q.id]
			
			                    if prog >= q.target and not claimed then
			                        QuestClaimRE:FireServer(pName, q.id, userPeriod.expiresAt)
			                    end
			                end
			            end
			        end
			
					for _, period in ipairs(HalloweenQuests.PERIODS or {}) do
					    local config = HalloweenQuests[period]
					    local halloweenData = data.Halloween
					    local questData = config
					        and halloweenData
					        and halloweenData[config.dataKey]
					
					    if config and type(questData) == "table" then
					        for _, questId in ipairs(questData.ids or {}) do
					            local quest
					
					            for _, entry in ipairs(config.pool or {}) do
					                if entry.id == questId then
					                    quest = entry
					                    break
					                end
					            end
					
					            if quest then
					                local progress =
					                    (questData.progress or {})[questId] or 0
					                local claimed =
					                    (questData.claimed or {})[questId] == true
					
					                if progress >= quest.target and not claimed then
					                    HalloweenQuestClaimRE:FireServer(period, questId)
					                    task.wait(0.3)
					                end
					            end
					        end
					    end
			        end
			    end)
			end

            if CFG.AutoReward and (now - lastRewardCheck >= 30.0) then
                lastRewardCheck = now
                pcall(function()
                    OfflineEarningsRE:FireServer()
                    DailyRewardRE:FireServer()
                    GroupRewardRE:FireServer()
                end)
            end

            if CFG.AutoBoost and BoostServiceRE and (now - lastBoostCheck >= 5.0) then
                lastBoostCheck = now
                pcall(function()
                    local inv = data.Inventory
                    local active = data.ActiveEntries or {}
                    if not inv then return end

                    local bestByCategory = {}
                    for itmName, itmData in pairs(inv) do
                        if itmData.amount and itmData.amount > 0 then
                            local bConfig = BoostConfig.entries and BoostConfig.entries[itmName]
                            if bConfig and bConfig.category and bConfig.tier and bConfig.tier <= 2 then
                                local cat = bConfig.category
                                if not bestByCategory[cat] or bConfig.tier > bestByCategory[cat].tier then
                                    bestByCategory[cat] = {
                                        name = itmName,
                                        tier = bConfig.tier,
                                        category = cat
                                    }
                                end
                            end
                        end
                    end

                    local activeCategories = {}
                    for activeName, activeData in pairs(active) do
                        local bConfig = BoostConfig.entries and BoostConfig.entries[activeName]
                        if bConfig and bConfig.category then
                            activeCategories[bConfig.category] = true
                        end
                    end

                    for cat, boostInfo in pairs(bestByCategory) do
                        if not activeCategories[cat] then
                            BoostServiceRE:FireServer(boostInfo.name)
                            task.wait(0.2)
                        end
                    end
                end)
            end

            if (CFG.AutoRedeemCode or CFG.RedeemCode) and RedeemCodeRE and not allCodesDone and (now - lastCodeCheck >= 10.0) then
                lastCodeCheck = now
                pcall(function()
                    local redeemed = data.RedeemedCodes or {}
                    local codesList = CFG.Codes or DEFAULT_REDEEM_CODES
                    local pendingCount = 0

                    for _, code in ipairs(codesList) do
                        if not redeemed[code] and not attemptedCodes[code] then
                            pendingCount = pendingCount + 1
                            attemptedCodes[code] = true
                            RedeemCodeRE:FireServer(code)
                            task.wait(0.3)
                        end
                    end

                    if pendingCount == 0 then
                        allCodesDone = true
                    end
                end)
            end

            if CFG.AutoGrade and not isTradingNow and (now - lastGradeRoll >= 0.3) then
                lastGradeRoll = now
                pcall(function()
                    if not (data.Slots and data.Inventory) then return end
                    local gems, _, _ = GetBackpackItemStats(data)
                    local reserveGems = tonumber(CFG.GradeMinGemsReserve) or 0
                    if gems <= reserveGems then return end

                    local targetOrder = GetGradeOrder(CFG.TargetGrade or "A")
                    if targetOrder <= 0 then targetOrder = 4 end

                    local slotKeys = {}
                    for sKey in pairs(data.Slots) do
                        table.insert(slotKeys, tonumber(sKey) or sKey)
                    end
                    table.sort(slotKeys, function(a, b)
                        if type(a) == "number" and type(b) == "number" then return a < b end
                        return tostring(a) < tostring(b)
                    end)

                    for _, slotIdx in ipairs(slotKeys) do
                        local slotData = data.Slots[tostring(slotIdx)] or data.Slots[slotIdx]
                        local uid = slotData and slotData.unitId
                        if uid then
                            local unit = data.Inventory[uid]
                            if unit then
                                local curGrade = (unit.attributes and unit.attributes.grade) or "None"
                                local curOrder = GetGradeOrder(curGrade)

                                if curOrder < targetOrder then
                                    GradeSignalRoll:Fire(uid, true)
                                    break
                                end
                            end
                        end
                    end
                end)
            end

            if not isTradingNow and (now - lastTicketShopCheck >= 1.5) then
                lastTicketShopCheck = now
                pcall(function()
                    local tickets = 0
                    if data.Inventory then
                        for _, entry in pairs(data.Inventory) do
                            if entry and entry.name then
                                local nm = string.lower(entry.name)
                                if nm == "tickets" or nm == "ticket" or string.find(nm, "ticket") then
                                    tickets = tickets + (entry.amount or entry.count or 1)
                                end
                            end
                        end
                    end
                    if tickets <= 0 then return end

                    local ownedPasses = data.OwnedGamepasses or {}
                    local priorityList = {
                        { name = "Ultra Luck",  price = 599, isPass = true },
                        { name = "Roll Speed",  price = 499, isPass = true },
                        { name = "More Cash",   price = 199, isPass = true },
                        { name = "Luck",        price = 199, isPass = true },
                        { name = "Lucky Spin",  price = 10,  isPass = false },
                    }

                    for _, item in ipairs(priorityList) do
                        if item.isPass then
                            if not ownedPasses[item.name] and tickets >= item.price then
                                QuestSignalBuy:Fire(item.name)
                                break
                            end
                        else
                            local anyPassPending = false
                            for _, pItem in ipairs(priorityList) do
                                if pItem.isPass and not ownedPasses[pItem.name] and tickets >= pItem.price then
                                    anyPassPending = true
                                    break
                                end
                            end

                            if not anyPassPending and tickets >= item.price then
                                QuestSignalBuy:Fire(item.name)
                                break
                            end
                        end
                    end
                end)
            end
        end
    end
end)
table.insert(activeCleanupHooks, function() task.cancel(farmEngine) end)

if CFG.AutoTrickOrTreat then
    local trickOrTreatEngine = task.spawn(function()
    	local HalloweenTeleport = game:GetService("ReplicatedStorage").Network.HalloweenService.RF.Teleport

        local function IsInHalloweenWorld()
            local character = LocalPlayer.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            local zones = workspace:FindFirstChild("Zones")
            local zone = zones and zones:FindFirstChild("HalloweenWorld")

            if not root or not zone then
                return false
            end

            local p = zone.CFrame:PointToObjectSpace(root.Position)
            local half = zone.Size / 2

            return math.abs(p.X) <= half.X
                and math.abs(p.Y) <= half.Y
                and math.abs(p.Z) <= half.Z
        end

        local function EnsureHalloweenWorld()
            if IsInHalloweenWorld() then
                return true
            end

            local ok, err = pcall(function()
                HalloweenTeleport:InvokeServer("Island")
            end)

            if not ok then
                return false
            end

            local deadline = os.clock() + 15

            repeat
                if not CFG.AutoTrickOrTreat then
                    return false
                end

                if IsInHalloweenWorld() then
                    return true
                end

                task.wait(0.25)
            until os.clock() >= deadline

            return false
        end
    
        local function getDoorPosition(door)
            if door:IsA("Model") then
                return door:GetPivot().Position
            elseif door:IsA("BasePart") then
                return door.Position
            end

            return nil
        end
        
        local function doorIsReachableCharacter(humanoid)
		    return humanoid
		        and humanoid.Parent
		        and humanoid.Health > 0
		end

        local function walkTo(target)
            local character = LocalPlayer.Character
            local humanoid = character
                and character:FindFirstChildOfClass("Humanoid")
            local root = character
                and character:FindFirstChild("HumanoidRootPart")

            if not humanoid or not root or humanoid.Health <= 0 then
                return false
            end

            local path = PathfindingService:CreatePath({
                AgentCanJump = true,
                WaypointSpacing = 4,
            })

            local success = pcall(function()
                path:ComputeAsync(root.Position, target)
            end)

            if not success or path.Status ~= Enum.PathStatus.Success then
                return false
            end

            for _, waypoint in ipairs(path:GetWaypoints()) do
                if not CFG.AutoTrickOrTreat then
                    return false
                end

                if not doorIsReachableCharacter(humanoid) then
                    return false
                end

                if waypoint.Action == Enum.PathWaypointAction.Jump then
                    humanoid.Jump = true
                end

                humanoid:MoveTo(waypoint.Position)

                local reached = false
                local connection
                connection = humanoid.MoveToFinished:Connect(function(ok)
                    reached = ok
                end)

                local deadline = os.clock() + 8

                while not reached and os.clock() < deadline do
                    if not CFG.AutoTrickOrTreat
                        or not humanoid.Parent
                        or humanoid.Health <= 0 then
                        break
                    end
                    task.wait(0.1)
                end

                if connection then
                    connection:Disconnect()
                end

                if not reached then
                    return false
                end
            end

            return true
        end

        while task.wait(1) do
            if not CFG.AutoTrickOrTreat then
                continue
            end
            
            if not EnsureHalloweenWorld() then
		        task.wait(3)
		        continue
		    end
		
			local doors = CollectionService:GetTagged("TrickOrTreatDoor")

            table.sort(doors, function(a, b)
                return a:GetFullName() < b:GetFullName()
            end)

            if #doors == 0 then
                task.wait(3)
                continue
            end

            for _, door in ipairs(doors) do
                if not CFG.AutoTrickOrTreat then
                    break
                end

                if door.Parent then
                    local target = getDoorPosition(door)

                    if target then
                        walkTo(target)
                        task.wait(2)
                    end
                end
            end
        end
    end)

    table.insert(activeCleanupHooks, function()
        pcall(function()
            task.cancel(trickOrTreatEngine)
        end)
    end)
end

local towerEngine = task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            local UIReferences = require(ReplicatedStorage.Framework.Features.UI.UIReferences)
            local Screen = UIReferences.Root.Tower.Screen
            local Hidden = Screen.Parent.Hidden
            local inTower = (Screen and Screen.Visible) or (Hidden and Hidden.Visible)

            if inTower then
                local floorMatch = nil
                if Screen and Screen:FindFirstChild("Floor") and Screen.Floor.Text then
                    floorMatch = string.match(Screen.Floor.Text, "%d+")
                end
                if not floorMatch and Hidden and Hidden:FindFirstChild("Label") and Hidden.Label.Text then
                    floorMatch = string.match(Hidden.Label.Text, "%d+")
                end
                if floorMatch then
                    CurrentTowerFloor = tonumber(floorMatch) or CurrentTowerFloor
                end
                if CurrentRunningTower == "None" or CurrentRunningTower == "" then
                    CurrentRunningTower = "Infinity Tower"
                end

                if Hidden then
                    -- Re-read the button callback + its real "hidden" state every tick
                    -- (the game rebuilds it each run). Only toggle when NOT already hidden.
                    local callback
                    pcall(function()
                        for _, con in ipairs(getconnections(Hidden.Activated)) do
                            if con.Function then callback = con.Function break end
                        end
                    end)

                    local stateKnown, isHidden = false, false
                    if callback and typeof(getupvalues) == "function" then
                        pcall(function()
                            local inner = getupvalues(callback)[2]
                            if typeof(inner) == "function" then
                                stateKnown = true
                                isHidden = getupvalues(inner)[1] and true or false
                            end
                        end)
                    end

                    if stateKnown then
                        if not isHidden then callback() end
                    elseif Screen and Screen.Visible then
                        -- fallback: old behaviour if the state can't be read
                        if typeof(firesignal) == "function" then
                            firesignal(Hidden.Activated)
                        elseif callback then
                            callback()
                        end
                    end
                end
            else
                CurrentRunningTower = "None"
                CurrentTowerFloor = 0

                if CFG.AutoTower then
                    EquipBestTowerRE:FireServer()
                    task.wait(0.3)

                    local function EvaluateSmartTower()
                        local data = DataController.___X
                        if not data then return "Dragon Tower" end

                        local totalTeamDmg = 0
                        local totalTeamHp  = 0
                        local inv = data.Inventory or {}
                        local team = data.TowerTeam or {}

                        for i = 1, 3 do
                            local uid = team[i]
                            if uid and inv[uid] then
                                local u = inv[uid]
                                local cfg = EntryRegistry.getEntryConfig(u.name)
                                if cfg then
                                    local dmg = (cfg.damage and cfg.damage(u.attributes)) or 0
                                    local hp  = (cfg.health and cfg.health(u.attributes)) or 0
                                    totalTeamDmg = totalTeamDmg + dmg
                                    totalTeamHp  = totalTeamHp + hp
                                end
                            end
                        end

                        local rebirth = data.Rebirth or 0

                        if totalTeamDmg >= 12000000 and rebirth >= 25 then
                            return "Hidden Leaf Tower"
                        elseif totalTeamDmg >= 600000 and rebirth >= 10 then
                            return "Pirate Tower"
                        elseif totalTeamDmg >= 30000 and rebirth >= 3 then
                            return "Cursed Tower"
                        elseif totalTeamDmg >= 1200 then
                            return "Dragon Tower"
                        else
                            return "Infinity Tower"
                        end
                    end

                    local chosenTower = "Infinity Tower"
                    if CFG.TowerMode == "auto" then
                        chosenTower = "Infinity Tower"
                    else
                        local modeStr = string.lower(tostring(CFG.TowerMode))
                        if string.find(modeStr, "inf") then
                            chosenTower = "Infinity Tower"
                        elseif string.find(modeStr, "dragon") then
                            chosenTower = "Dragon Tower"
                        elseif string.find(modeStr, "cursed") then
                            chosenTower = "Cursed Tower"
                        elseif string.find(modeStr, "pirate") then
                            chosenTower = "Pirate Tower"
                        elseif string.find(modeStr, "shadow") then
                        	chosenTower = "Shadow Tower"
                        elseif string.find(modeStr, "front") or string.find(modeStr, "yard") then
                        	chosenTower = "Front Yard"
                        elseif string.find(modeStr, "foyer") then
                        	chosenTower = "Foyer"
                        elseif string.find(modeStr, "crypt") then
                        	chosenTower = "Crypt"
                        elseif string.find(modeStr, "attic") then
                        	chosenTower = "Attic"
                        elseif string.find(modeStr, "bell") then
                        	chosenTower = "Bell Tower"
                        elseif string.find(modeStr, "catacomb") then
                        	chosenTower = "Catacombs"
                        elseif string.find(modeStr, "abyss") then
                        	chosenTower = "The Abyss"
                        elseif string.find(modeStr, "leaf") or string.find(modeStr, "hidden") then
                            chosenTower = "Hidden Leaf Tower"
                        elseif string.find(modeStr, "smart") then
                            chosenTower = EvaluateSmartTower()
                        else
                            chosenTower = CFG.TowerMode
                        end
                    end

					CurrentRunningTower = chosenTower
					TowerController.startTower(chosenTower)
                end
            end
        end)
    end
end)
table.insert(activeCleanupHooks, function() task.cancel(towerEngine) end)

local function GetSmartTradeData(data)
    if not data then
        return {
            isReady = false,
            offers = {},
            statusText = "Farming (waiting for character data...)",
            gems = 0,
            traits = 0,
            tickets = 0,
            units = 0
        }
    end

    local inv = data.Inventory or {}
    local slots = data.Slots or {}
    local plotted = SellUtil.GetPlottedUnits(slots)
    local untradeables = (TradeConfig and TradeConfig.UNTRADEABLE_ENTRIES) or {"Tickets"}

    local tokenOffers = {}
    local unitOffers = {}
    local curGems = 0
    local curTraits = 0
    local curTickets = 0
    local curSpins = 0

    for key, entry in pairs(inv) do
        if entry and entry.name and entry.amount and entry.amount > 0 then
            local cfg = EntryRegistry.getEntryConfig(entry.name)
            if cfg and cfg.kind ~= "Unit" then
                local name = string.lower(entry.name)
                local amt = entry.amount or 1
                local isUntradeable = table.find(untradeables, entry.name) ~= nil

                if name == "gems" or string.find(name, "gem") then
                    curGems = curGems + amt
                    if CFG.TradeGems == true and not isUntradeable then
                        table.insert(tokenOffers, {key = key, amount = amt, kind = "token", name = entry.name})
                    end
                elseif name == "trait reroll" or string.find(name, "trait") then
                    curTraits = curTraits + amt
                    if CFG.TradeTraits == true and not isUntradeable then
                        table.insert(tokenOffers, {key = key, amount = amt, kind = "token", name = entry.name})
                    end
                elseif name == "tickets" or name == "ticket" or string.find(name, "ticket") then
                    curTickets = curTickets + amt
                    if CFG.TradeTickets == true and not isUntradeable then
                        table.insert(tokenOffers, {
                            key = key,
                            amount = amt,
                            kind = "token",
                            name = entry.name
                        })
                    end
                elseif name == "jackpot spin" or name == "jackpot spins" then
                    curSpins = curSpins + amt
                    if CFG.TradeSpins == true and not isUntradeable then
                        table.insert(tokenOffers, {
                            key = key,
                            amount = amt,
                            kind = "token",
                            name = entry.name
                        })
                    end
                elseif name == "lucky spin" or name == "lucky spins" then
                    curSpins = curSpins + amt
                    if CFG.TradeSpins == true and not isUntradeable then
                        table.insert(tokenOffers, {
                            key = key,
                            amount = amt,
                            kind = "token",
                            name = entry.name
                        })
                    end
                elseif string.find(name, "income")
                    or string.find(name, "luck")
                    or string.find(name, "speed")
                    or string.find(name, "damage") then

                    local hasTier = string.find(name, " iii")
                        or string.find(name, " iv")

                    if CFG.TradePotions == true
                        and hasTier
                        and not isUntradeable then

                        table.insert(tokenOffers, {
                            key = key,
                            amount = amt,
                            kind = "token",
                            name = entry.name
                        })
                    end
                end
            end
        end
    end

    local minUnitIncome = ParseIncomeValue(CFG.TradeMinUnitIncome)
    local maxUnitIncome = ParseIncomeValue(CFG.TradeMaxUnitIncome)

    if CFG.TradeUnits == true then
        for key, unit in pairs(inv) do
            local cfg = EntryRegistry.getEntryConfig(unit.name)
            if cfg and cfg.kind == "Unit" and not (unit.attributes and unit.attributes.locked) then
                local isSlotted = plotted[key] ~= nil
                local allowSlotted = not (CFG.TradeKeepSlotted ~= false and isSlotted)

                if allowSlotted then
                    local inc = (cfg.income and cfg.income(unit.attributes)) or 0
                    local matchMin = (minUnitIncome <= 0) or (inc >= minUnitIncome)
                    local matchMax = (maxUnitIncome <= 0) or (inc <= maxUnitIncome)

                    if matchMin and matchMax then
                        table.insert(unitOffers, {key = key, amount = 1, kind = "unit", name = unit.name, income = inc})
                    end
                end
            end
        end
    end

    local gemThreshold = tonumber(CFG.TradeMinGems) or 0
    local traitThreshold = tonumber(CFG.TradeMinTraits) or 0
    local unitMinCount = tonumber(CFG.TradeMinUnits) or 1

    local gemsReady = (CFG.TradeGems == true) and (curGems > 0) and (gemThreshold <= 0 or curGems >= gemThreshold)
    local traitsReady = (CFG.TradeTraits == true) and (curTraits > 0) and (traitThreshold <= 0 or curTraits >= traitThreshold)
    local unitsReady = (CFG.TradeUnits == true) and (#unitOffers >= unitMinCount)
    local spinReady = (CFG.TradeSpins == true) and (curSpins > 0)

    local isReady = gemsReady or traitsReady or unitsReady or spinReady

    local finalOffers = {}
    for _, t in ipairs(tokenOffers) do table.insert(finalOffers, t) end
    for _, u in ipairs(unitOffers) do table.insert(finalOffers, u) end

    local progressList = {}
    if CFG.TradeGems ~= false and gemThreshold > 0 then
        table.insert(progressList, string.format("Gems: %d/%d", curGems, gemThreshold))
    end
    if CFG.TradeTraits ~= false and traitThreshold > 0 then
        table.insert(progressList, string.format("Trait: %d/%d", curTraits, traitThreshold))
    end
    if CFG.TradeUnits == true and unitMinCount > 1 then
        table.insert(progressList, string.format("Units: %d/%d", #unitOffers, unitMinCount))
    end

	local statusText = "Farming and collecting items..."
	if #progressList > 0 then
	    statusText = "Farming (" .. table.concat(progressList, " • ") .. ")"
	end

    return {
        isReady = isReady,
        offers = finalOffers,
        statusText = statusText,
        gems = curGems,
        traits = curTraits,
        tickets = curTickets,
        units = #unitOffers
    }
end

local function GetTradeableOfferList(data)
    local smart = GetSmartTradeData(data)
    return smart.offers, #smart.offers
end

local tradeEvt = TradeSignalEvent:Connect(function(evt, payload)
    pcall(function()
        if not CFG.AutoTrade then return end
		if evt == "RequestReceived" then
		    task.wait(0.3)
		
		    local sender = payload and payload.player
		    local allow = false
		
		    if sender then
		        local hostStr = tostring(CFG.TradeHost or ""):gsub("@", "")
		
		        if hostStr ~= "" and hostStr ~= "0" then
		            local hostId = tonumber(hostStr)
		
		            if hostId then
		                allow = (sender.UserId == hostId)
		            else
		                allow = (sender.Name:lower() == hostStr:lower())
		            end
		        end
		    end
		
		    if allow then
		        TradeSignalRespondToRequest:Fire(true)
		    else
		        TradeSignalRespondToRequest:Fire(false)
            end
        elseif evt == "Started" then
            tradeSession.active = true
            tradeSession.phase = "Offer"
            tradeSession.partner = payload and payload.partner
            tradeSession.offered = false
            tradeSession.ownReady = false
            tradeSession.otherReady = false
            tradeSession.ownAccepted = false
            tradeSession.otherAccepted = false
            tradeSession.lastAction = os.clock()
        elseif evt == "Updated" and payload then
            tradeSession.phase = payload.phase or tradeSession.phase
            tradeSession.ownReady = payload.ownReady or false
            tradeSession.otherReady = payload.otherReady or false
            tradeSession.ownAccepted = payload.ownAccepted or false
            tradeSession.otherAccepted = payload.otherAccepted or false
        elseif evt == "Ended" or evt == "Completed" or evt == "Cancelled" or evt == "RequestClosed" then
            tradeSession.active = false
            tradeSession.phase = "None"
            tradeSession.offered = false
            tradeSession.partner = nil
            tradeSession.cooldownUntil = os.clock() + (CFG.TradeCooldown or 15)
        end
    end)
end)
table.insert(activeCleanupHooks, function() tradeEvt:Disconnect() end)

local tradeEngine = task.spawn(function()
    while task.wait(0.3) do
        if CFG.AutoTrade and tostring(CFG.TradeHost) ~= "0" and CFG.TradeHost ~= "" then
            pcall(function()
                local data = DataController.___X
                if not data then return end

                local hostStr = tostring(CFG.TradeHost):gsub("@", "")
                local hostId = tonumber(hostStr)
                local isHost = (hostId and LocalPlayer.UserId == hostId) or (LocalPlayer.Name:lower() == hostStr:lower())

                local hostTarget = nil
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer then
                        if (hostId and p.UserId == hostId) or (p.Name:lower() == hostStr:lower()) then
                            hostTarget = p
                            break
                        end
                    end
                end

                local UIReferences = require(ReplicatedStorage.Framework.Features.UI.UIReferences)
                local TradeScreen = UIReferences.Root.Trading.TradeScreen

                if not hostTarget and CFG.TradeGather and not isHost then
                    local env = (getgenv and getgenv()) or _G
                    if env and env.HOST_JOB_ID and env.HOST_JOB_ID ~= game.JobId then
                        TeleportService:TeleportToPlaceInstance(PlaceId, env.HOST_JOB_ID, LocalPlayer)
                    end
                end

                local isTrading = (TradeScreen and TradeScreen.Visible) or tradeSession.active

                if not isTrading and not isHost and hostTarget then
                    local minRolls = (TradeConfig and TradeConfig.MIN_ROLLS) or 1000
                    local minAge = (TradeConfig and TradeConfig.MIN_ACCOUNT_AGE) or 14
                    local smartTrade = GetSmartTradeData(data)
                    local isCooldown = tradeSession.cooldownUntil and os.clock() < tradeSession.cooldownUntil

                    if (data.Rolls or 0) >= minRolls and LocalPlayer.AccountAge >= minAge and not isCooldown and smartTrade.isReady and #smartTrade.offers > 0 then
                        if os.clock() - tradeSession.lastAction >= 7.0 then
                            tradeSession.lastAction = os.clock()
                            TradeSignalRequestTrade:Fire(hostTarget)
                        end
                    end
                end

                if isTrading then
                    local maxEntries = (TradeConfig and TradeConfig.MAX_UNIQUE_ENTRIES) or 20

                    if not isHost then
                        if tradeSession.phase == "Offer" or tradeSession.phase == "None" then
                            if not tradeSession.offered then
                                local smartTrade = GetSmartTradeData(data)
                                local tradeables = smartTrade.offers
                                local offeredCount = 0

                                if #tradeables == 0 then
                                    tradeSession.cooldownUntil = os.clock() + (CFG.TradeCooldown or 15)
                                    pcall(function()
                                        local closeBtn = TradeScreen.Background.Container.Close
                                        if closeBtn then firesignal(closeBtn.Activated) end
                                    end)
                                else
                                    for _, item in ipairs(tradeables) do
                                        TradeSignalChangeOffer:Fire(item.key, item.amount)
                                        offeredCount = offeredCount + 1
                                        task.wait(0.25)
                                        if offeredCount >= maxEntries then break end
                                    end
                                end

                                tradeSession.offered = true
                                tradeSession.lastAction = os.clock()
                                task.wait(0.3)
                            end

                            if tradeSession.offered and not tradeSession.ownReady and (os.clock() - tradeSession.lastAction >= 0.5) then
                                tradeSession.lastAction = os.clock()
                                TradeSignalAdvanceTrade:Fire()
                            end
                        elseif tradeSession.phase == "Confirm" or tradeSession.phase == "Countdown" then
                            if not tradeSession.ownAccepted and (os.clock() - tradeSession.lastAction >= 0.8) then
                                tradeSession.lastAction = os.clock()
                                TradeSignalAdvanceTrade:Fire()
                            end
                        end
                    else
                        if tradeSession.phase == "Offer" or tradeSession.phase == "None" then
                            if tradeSession.otherReady and not tradeSession.ownReady and (os.clock() - tradeSession.lastAction >= 0.5) then
                                tradeSession.lastAction = os.clock()
                                TradeSignalAdvanceTrade:Fire()
                            end
                        elseif tradeSession.phase == "Confirm" or tradeSession.phase == "Countdown" then
                            if not tradeSession.ownAccepted and (os.clock() - tradeSession.lastAction >= 0.8) then
                                tradeSession.lastAction = os.clock()
                                TradeSignalAdvanceTrade:Fire()
                            end
                        end
                    end
                end
            end)
        end
    end
end)
table.insert(activeCleanupHooks, function() pcall(function() task.cancel(tradeEngine) end) end)

local lastLoggedMoney = 0
local lastLoggedTime = os.clock()
local computedIncomePerSec = 0

local statsEngine = task.spawn(function()
    local lastSerenitySend = -10
    while task.wait(0.5) do
        pcall(function()
            local data = DataController.___X
            local now = os.clock()
            local runtimeSec = os.time() - StartTime
            local hrs = math.floor(runtimeSec / 3600)
            local mins = math.floor((runtimeSec % 3600) / 60)
            local secs = runtimeSec % 60
            local runtimeStr = string.format("%02d:%02d:%02d", hrs, mins, secs)

            if data then
                local money   = data.Money or 0
                local rebirth = data.Rebirth or 0
                local rolls   = data.Rolls or 0

                local dt = now - lastLoggedTime
                if dt >= 2.0 then
                    computedIncomePerSec = math.max(0, (money - lastLoggedMoney) / dt)
                    lastLoggedMoney = money
                    lastLoggedTime = now
                end

                local fallbackIncome = CalculateTotalPlotIncome(data)
                local displayIncome = computedIncomePerSec > 0 and computedIncomePerSec or fallbackIncome

				if CFG.ShowOverlay then
				    local uCount, maxStorage = GetStorageStats(data)
				    local diceName = tostring(data.Dice or "Basic")
				
				    if OverlayUI.TowerLabel then
				        OverlayUI.TowerLabel.Text = string.format(
				            "Tower : %s : Floor %s",
				            tostring(CurrentRunningTower),
				            tostring(CurrentTowerFloor)
				        )
				    end
				
				    if OverlayUI.RebirthDiceLabel then
				        OverlayUI.RebirthDiceLabel.Text = string.format(
				            "Rebirth : %d • Dice : %s",
				            rebirth,
				            diceName
				        )
				    end
				
				    if OverlayUI.StorageLabel then
				        OverlayUI.StorageLabel.Text = string.format(
				            "Storage : %d/%d",
				            uCount,
				            maxStorage
				        )
				    end
				
				    if OverlayUI.TokensLabel then
				        local gems, traits, tickets = GetBackpackItemStats(data)
				
				        OverlayUI.TokensLabel.Text = string.format(
				            "Gems : %s • Trait : %s • Ticket : %s",
				            FormatNumber(gems),
				            FormatNumber(traits),
				            FormatNumber(tickets)
				        )
				    end
				
				    if OverlayUI.RuntimeLabel then
				        OverlayUI.RuntimeLabel.Text = "Runtime : " .. runtimeStr
				    end
				end

                if CFG.SerenityLog and (now - lastSerenitySend >= 150.0) then
                    lastSerenitySend = now
                    pcall(function()
                        local requestFunction = nil
                        if typeof(request) == "function" then
                            requestFunction = request
                        elseif typeof(http_request) == "function" then
                            requestFunction = http_request
                        elseif typeof(syn) == "table" and typeof(syn.request) == "function" then
                            requestFunction = syn.request
                        elseif typeof(http) == "table" and typeof(http.request) == "function" then
                            requestFunction = http.request
                        end

                        local token = CFG.ApiToken
                        local dashboardURL = "http://uk-02.rrhosting.eu:7828/api/update"

                        if typeof(requestFunction) ~= "function" then return end
                        if typeof(token) ~= "string" or token == "" then return end

                        local gems, traits, tickets = GetBackpackItemStats(data)

                        local payload = {
                            username = LocalPlayer.Name,
                            cash = tonumber(money) or 0,
                            cashFormatted = tonumber(money) or 0,
                            gems = tonumber(gems) or 0,
                            gemsFormatted = tonumber(gems) or 0,
                            tickets = tonumber(tickets) or 0,
                            ticketsFormatted = tonumber(tickets) or 0,
                            jackpotSpins = 0,
                            jackpotSpinsFormatted = 0,
                            luckySpins = 0,
                            luckySpinsFormatted = 0,
                            traitRerolls = tonumber(traits) or 0,
                            traitRerollsFormatted = tonumber(traits) or 0,
                            rebirths = tonumber(rebirth) or 0,
                            rebirthsFormatted = tonumber(rebirth) or 0,
                            rolls = tonumber(rolls) or 0,
                            rollsFormatted = tonumber(rolls) or 0
                        }

                        if data.Inventory then
                            for _, entry in pairs(data.Inventory) do
                                if entry and entry.name then
                                    local name = string.lower(tostring(entry.name))
                                    local amount = tonumber(entry.amount or entry.count) or 1
                                    if name == "jackpot spin" or name == "jackpot spins" then
                                        payload.jackpotSpins = payload.jackpotSpins + amount
                                        payload.jackpotSpinsFormatted = payload.jackpotSpins
                                    elseif name == "lucky spin" or name == "lucky spins" then
                                        payload.luckySpins = payload.luckySpins + amount
                                        payload.luckySpinsFormatted = payload.luckySpins
                                    end
                                end
                            end
                        end

                        requestFunction({
                            Url = dashboardURL,
                            Method = "POST",
                            Headers = {
                                ["Content-Type"] = "application/json",
                                ["Authorization"] = "Bearer " .. token
                            },
                            Body = HttpService:JSONEncode(payload)
                        })
                    end)
                end
            end
        end)
    end
end)
table.insert(activeCleanupHooks, function() task.cancel(statsEngine) end)

if CFG.AntiAFK then
    pcall(function()
        local playerScripts = LocalPlayer:FindFirstChild("PlayerScripts")
        local playerAFK = playerScripts and playerScripts:FindFirstChild("AFK")

        if playerAFK and playerAFK:IsA("LocalScript") and not playerAFK.Disabled then
            playerAFK.Disabled = true
        end

        local starterPlayer = game:GetService("StarterPlayer")
        local starterScripts = starterPlayer:FindFirstChild("StarterPlayerScripts")
        local starterAFK = starterScripts and starterScripts:FindFirstChild("AFK")

        if starterAFK and starterAFK:IsA("LocalScript") and not starterAFK.Disabled then
            starterAFK.Disabled = true
        end
    end)

    local afkConn = LocalPlayer.Idled:Connect(function()
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.zero)
        end)
    end)
    table.insert(activeCleanupHooks, function() afkConn:Disconnect() end)

    local afkPulse = task.spawn(function()
        while task.wait(60) do
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new(100, 100))
            end)
        end
    end)
    table.insert(activeCleanupHooks, function() task.cancel(afkPulse) end)

    pcall(function()
        GuiService:SetGameplayPausedNotificationEnabled(false)
    end)
end

pcall(function()
    if typeof(hookfunction) == "function" and TeleportService then
        local oldTeleport, oldTeleportInstance, oldTeleportParty
        
        if TeleportService.Teleport then
            oldTeleport = hookfunction(TeleportService.Teleport, function(self, ...)
                return
            end)
        end

        if TeleportService.TeleportToPlaceInstance then
            oldTeleportInstance = hookfunction(TeleportService.TeleportToPlaceInstance, function(self, ...)
                return
            end)
        end

        if TeleportService.TeleportAsync then
            oldTeleportParty = hookfunction(TeleportService.TeleportAsync, function(self, ...)
                return
            end)
        end

        table.insert(activeCleanupHooks, function()
            pcall(function()
                if oldTeleport then hookfunction(TeleportService.Teleport, oldTeleport) end
                if oldTeleportInstance then hookfunction(TeleportService.TeleportToPlaceInstance, oldTeleportInstance) end
                if oldTeleportParty then hookfunction(TeleportService.TeleportAsync, oldTeleportParty) end
            end)
        end)
    end
end)

local gcPulse = task.spawn(function()
    while task.wait(60) do
        pcall(function()
            if typeof(collectgarbage) == "function" then
                collectgarbage("collect")
            end
        end)
    end
end)
table.insert(activeCleanupHooks, function() pcall(function() task.cancel(gcPulse) end) end)

local function KaitunCleanup()
    for _, hook in ipairs(activeCleanupHooks) do pcall(hook) end
    pcall(function()
        if typeof(collectgarbage) == "function" then
            collectgarbage("collect")
        end
    end)
    pcall(function()
        local function SafeDestroy(inst)
            pcall(function() if inst and inst.Parent then inst:Destroy() end end)
        end
        local cg = game:GetService("CoreGui")
        for _, v in ipairs(cg:GetChildren()) do
            if v.Name == "XDFLEX_Kaitun_Overlay" then SafeDestroy(v) end
        end
        if typeof(gethui) == "function" then
            local h = gethui()
            if h then
                for _, v in ipairs(h:GetChildren()) do
                    if v.Name == "XDFLEX_Kaitun_Overlay" then SafeDestroy(v) end
                end
            end
        end
        local lp = game:GetService("Players").LocalPlayer
        local pg = lp and lp:FindFirstChild("PlayerGui")
        if pg then
            for _, v in ipairs(pg:GetChildren()) do
                if v.Name == "XDFLEX_Kaitun_Overlay" then SafeDestroy(v) end
            end
        end
    end)
end

if env then
    env.XDFLEX_KAITUN_CLEANUP = KaitunCleanup
    env.HOST_JOB_ID = game.JobId
end