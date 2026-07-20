-- Visuals (HIGHLIGHT) (ertedHIGHTLIGHTgfdwq.lua) (PinguinDEV)
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Teams = game:GetService("Teams")
local RunService = game:GetService("RunService")

getgenv().Pinguin = getgenv().Pinguin or {}
getgenv().Pinguin.Visuals = getgenv().Pinguin.Visuals or {}
getgenv().Pinguin.Visuals.Chams = getgenv().Pinguin.Visuals.Chams or {
    Enabled = false,
    Color = Color3.fromRGB(255, 255, 255),
    FillColor = Color3.fromRGB(255, 255, 255),
    FillTransparency = 0.5,
    FillEnabled = true
}

local function lightenColor(color, factor)
    return Color3.new(
        math.min(color.R + factor, 1),
        math.min(color.G + factor, 1),
        math.min(color.B + factor, 1)
    )
end

local function highlightPlayer(player)
    if player == LocalPlayer then return end

    if player.Character then
        local existingHighlight = player.Character:FindFirstChild("PlayerHighlight")
        if existingHighlight then
            existingHighlight:Destroy()
        end
    end

    if getgenv().Pinguin.Visuals.Chams.Enabled then
        local isTeammate = getgenv().Pinguin.Visuals.TeamCheck and getgenv().Pinguin.IsTeammate(player)
        
        if not isTeammate then
            local highlight = Instance.new("Highlight")
            highlight.Name = "PlayerHighlight"
            highlight.FillColor = getgenv().Pinguin.Visuals.Chams.FillColor
            highlight.FillTransparency = getgenv().Pinguin.Visuals.Chams.FillEnabled and getgenv().Pinguin.Visuals.Chams.FillTransparency or 1
            highlight.OutlineColor = getgenv().Pinguin.Visuals.Chams.Color
            highlight.Parent = player.Character
        end
    end
end

local function onPlayerAdded(player)
    if getgenv().Pinguin.Visuals.Chams.Enabled then
        if player.Character then
            highlightPlayer(player)
        end
        player.CharacterAdded:Connect(function()
            highlightPlayer(player)
        end)
    end
end

local function onPlayerRemoved(player)
    local highlight = player.Character and player.Character:FindFirstChild("PlayerHighlight")
    if highlight then
        highlight:Destroy()
    end
end

for _, player in pairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end

RunService.RenderStepped:Connect(function()
    if not getgenv().Pinguin.Visuals.Chams.Enabled then return end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local isTeammate = getgenv().Pinguin.Visuals.TeamCheck and getgenv().Pinguin.IsTeammate(player)
            local highlight = player.Character:FindFirstChild("PlayerHighlight")
            
            if isTeammate and highlight then
                highlight:Destroy()
            elseif not isTeammate and not highlight then
                highlightPlayer(player)
            end
        end
    end
end)

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoved)

Players.PlayerAdded:Connect(function(player)
    player:GetPropertyChangedSignal("Team"):Connect(function()
        if player.Character then
            highlightPlayer(player)
        end
    end)
end)

local function ToggleChams(state)
    getgenv().Pinguin.Visuals.Chams.Enabled = state
    if state then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                player.CharacterAdded:Connect(function(character)
                    highlightPlayer(player)
                end)
                if player.Character then
                    highlightPlayer(player)
                end
            end
        end
    else
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local highlight = player.Character:FindFirstChild("PlayerHighlight")
                if highlight then
                    highlight:Destroy()
                end
            end
        end
    end
end

return ToggleChams