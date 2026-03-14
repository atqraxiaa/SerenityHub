local HttpService = game:GetService("HttpService")
local jsonUrl = "https://raw.githubusercontent.com/atqraxiaa/SerenityHub/refs/heads/main/Games/Serenity_Loader.json"

local success, data = pcall(function()
    local response = game:HttpGet(jsonUrl)
    return HttpService:JSONDecode(response)
end)

if not success then
    warn("Serenity Loader: Failed to load JSON from GitHub")
    return
end

local Games = data.Games or {}
local Fallback = data.Fallback

local currentGameId = tostring(game.GameId)
local scriptUrl = Games[currentGameId] or Fallback

pcall(function()
    loadstring(game:HttpGet(scriptUrl))()
end)
