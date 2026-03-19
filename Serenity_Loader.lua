local HttpService = game:GetService("HttpService")
local jsonUrl = "https://raw.githubusercontent.com/atqraxiaa/SerenityHub/main/Games/Serenity_Loader.json"

local success, data = pcall(function()
    local response = game:HttpGet(jsonUrl)
    return HttpService:JSONDecode(response)
end)

if not success then
    warn("Failed to load JSON")
    setclipboard("Failed to load JSON")
    return
end

local Games = data.Games or {}
local Fallback = data.Fallback

local currentGameId = tostring(game.PlaceId)
local scriptUrl = Games[currentGameId] or Fallback

if not scriptUrl then
    warn("No script found for this game")
    return
end

local ok, err = pcall(function()
    loadstring(game:HttpGet(scriptUrl))()
end)
if not ok then
    warn("Failed to execute script: "..tostring(err))
end
