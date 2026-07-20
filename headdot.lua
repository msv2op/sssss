-- Visuals (HEADDOT) (ertedHEADDOT2gfdwq.lua) (PinguinDEV)
getgenv().Pinguin = getgenv().Pinguin or {}
getgenv().Pinguin.Visuals = getgenv().Pinguin.Visuals or {}
getgenv().Pinguin.Visuals.HeadDot = getgenv().Pinguin.Visuals.HeadDot or {
    Enabled = false,
    Color = Color3.fromRGB(255, 255, 255),
    Transparency = 1,
    Thickness = 1,
    Filled = false,
    Sides = 50
}

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local playerDots = {}

local function CreateHeadDot(player)
    local headDot = Drawing.new("Circle")
    local cfg = getgenv().Pinguin.Visuals.HeadDot
    headDot.Visible = cfg.Enabled or false
    headDot.Color = cfg.Color or Color3.fromRGB(255, 255, 255)
    headDot.Transparency = cfg.Transparency or 1
    headDot.Thickness = cfg.Thickness or 1
    if cfg.Filled ~= nil then headDot.Filled = cfg.Filled else headDot.Filled = false end
    headDot.NumSides = cfg.Sides or 50

    playerDots[player.UserId] = {
        player = player,
        headDot = headDot,
    }
end

local function UpdateHeadDot(player)
    local data = playerDots[player.UserId]
    if not data or not data.player.Character then return end

    local head = data.player.Character:FindFirstChild("Head")
    if not head then return end

    local headPosition, onScreen = Camera:WorldToViewportPoint(head.Position)
    
    local isTeammate = getgenv().Pinguin.Visuals.TeamCheck and getgenv().Pinguin.IsTeammate(data.player)
    
    data.headDot.Visible = onScreen and getgenv().Pinguin.Visuals.HeadDot.Enabled and not isTeammate
    if data.headDot.Visible then
        data.headDot.Position = Vector2.new(headPosition.X, headPosition.Y)
        local top = Camera:WorldToViewportPoint((head.CFrame * CFrame.new(0, head.Size.Y / 2, 0)).Position)
        local bottom = Camera:WorldToViewportPoint((head.CFrame * CFrame.new(0, -head.Size.Y / 2, 0)).Position)
        data.headDot.Radius = math.abs((top.Y - bottom.Y) - 3)
    end
end

local function RemoveHeadDot(player)
    if playerDots[player.UserId] then
        playerDots[player.UserId].headDot:Remove()
        playerDots[player.UserId] = nil
    end
end

local function ToggleHeadDots(state)
    getgenv().Pinguin.Visuals.HeadDot.Enabled = state
    for _, data in pairs(playerDots) do
        data.headDot.Visible = state
    end
end

RunService.RenderStepped:Connect(function()
    for _, data in pairs(playerDots) do
        UpdateHeadDot(data.player)
    end
end)

local function InitializeHeadDots()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            CreateHeadDot(player)
        end
    end
end

Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        CreateHeadDot(player)
    end
end)

Players.PlayerRemoving:Connect(RemoveHeadDot)

return {
    Initialize = InitializeHeadDots,
    ToggleHeadDotESP = ToggleHeadDots,
    UpdateColor = function(color)
        getgenv().Pinguin.Visuals.HeadDot.Color = color
        for _, data in pairs(playerDots) do
            data.headDot.Color = color
        end
    end,
    UpdateTransparency = function(transparency)
        getgenv().Pinguin.Visuals.HeadDot.Transparency = transparency
        for _, data in pairs(playerDots) do
            data.headDot.Transparency = transparency
        end
    end
}