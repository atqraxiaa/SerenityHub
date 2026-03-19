local HttpService = game:GetService("HttpService")
local jsonUrl = "https://raw.githubusercontent.com/atqraxiaa/SerenityHub/refs/heads/main/Games/Serenity_Loader.json"

local response = game:HttpGet(jsonUrl)
local data = HttpService:JSONDecode(response)

local Games = data.Games or {}
local Fallback = data.Fallback

local currentGameId = tostring(game.PlaceId)
local scriptUrl = Games[currentGameId] or Fallback

if not scriptUrl then
    warn("No script found for this game and no fallback provided!")
    return
end

print("Script URL:", scriptUrl)

local scriptContent = game:HttpGet(scriptUrl)
local func = loadstring(scriptContent)

if not func then
    warn("Failed to compile script!")
    return
end

func()
