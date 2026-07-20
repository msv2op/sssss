-- Visuals (SKELETON) (skeleton.lua) (PinguinDEV)
getgenv().Pinguin = getgenv().Pinguin or {}
getgenv().Pinguin.Visuals = getgenv().Pinguin.Visuals or {}
getgenv().Pinguin.Visuals.Skeleton = getgenv().Pinguin.Visuals.Skeleton or {
    Enabled = false,
    Color = Color3.fromRGB(255, 255, 255),
    Transparency = 1,
    Thickness = 1
}

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local playerSkeletons = {}

local R15_Connections = {
    {"Head", "UpperTorso"},
    {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"},
    {"LeftUpperArm", "LeftLowerArm"},
    {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"},
    {"RightUpperArm", "RightLowerArm"},
    {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"},
    {"LeftUpperLeg", "LeftLowerLeg"},
    {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"},
    {"RightUpperLeg", "RightLowerLeg"},
    {"RightLowerLeg", "RightFoot"}
}

local R6_Connections = {
    {"Head", "Torso"},
    {"Torso", "Left Arm"},
    {"Torso", "Right Arm"},
    {"Torso", "Left Leg"},
    {"Torso", "Right Leg"}
}

local function CreateSkeleton(player)
    if player == LocalPlayer then return end
    
    local lines = {}
    -- Max connections is 14 for R15
    for i = 1, 14 do
        local line = Drawing.new("Line")
        local cfg = getgenv().Pinguin.Visuals.Skeleton
        line.Visible = false
        line.Color = cfg.Color or Color3.fromRGB(255, 255, 255)
        line.Transparency = cfg.Transparency or 1
        line.Thickness = cfg.Thickness or 1
        table.insert(lines, line)
    end

    playerSkeletons[player.UserId] = {
        player = player,
        lines = lines,
    }
end

local function UpdateSkeleton(player)
    local data = playerSkeletons[player.UserId]
    if not data then return end

    local character = data.player.Character
    local cfg = getgenv().Pinguin.Visuals.Skeleton

    local isTeammate = getgenv().Pinguin.Visuals.TeamCheck and getgenv().Pinguin.IsTeammate(data.player)

    if not character or not cfg.Enabled or isTeammate then
        for _, line in ipairs(data.lines) do
            line.Visible = false
        end
        return
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        for _, line in ipairs(data.lines) do
            line.Visible = false
        end
        return
    end

    local isR15 = humanoid.RigType == Enum.HumanoidRigType.R15
    local connections = isR15 and R15_Connections or R6_Connections

    for i, line in ipairs(data.lines) do
        local conn = connections[i]
        if conn then
            local part1 = character:FindFirstChild(conn[1])
            local part2 = character:FindFirstChild(conn[2])

            if part1 and part2 then
                local pos1, onScreen1 = Camera:WorldToViewportPoint(part1.Position)
                local pos2, onScreen2 = Camera:WorldToViewportPoint(part2.Position)

                if onScreen1 or onScreen2 then
                    line.From = Vector2.new(pos1.X, pos1.Y)
                    line.To = Vector2.new(pos2.X, pos2.Y)
                    line.Color = cfg.Color or Color3.fromRGB(255, 255, 255)
                    line.Transparency = cfg.Transparency or 1
                    line.Thickness = cfg.Thickness or 1
                    line.Visible = true
                else
                    line.Visible = false
                end
            else
                line.Visible = false
            end
        else
            line.Visible = false
        end
    end
end

local function RemoveSkeleton(player)
    if playerSkeletons[player.UserId] then
        for _, line in ipairs(playerSkeletons[player.UserId].lines) do
            line:Remove()
        end
        playerSkeletons[player.UserId] = nil
    end
end

local function ToggleSkeleton(state)
    getgenv().Pinguin.Visuals.Skeleton.Enabled = state
    if not state then
        for _, data in pairs(playerSkeletons) do
            for _, line in ipairs(data.lines) do
                line.Visible = false
            end
        end
    end
end

RunService.RenderStepped:Connect(function()
    for _, data in pairs(playerSkeletons) do
        if getgenv().Pinguin.Visuals.Skeleton.Enabled then
            UpdateSkeleton(data.player)
        else
            for _, line in ipairs(data.lines) do
                if line.Visible then
                    line.Visible = false
                end
            end
        end
    end
end)

local function InitializeSkeletons()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            CreateSkeleton(player)
        end
    end
end

Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        CreateSkeleton(player)
    end
end)

Players.PlayerRemoving:Connect(RemoveSkeleton)

return {
    Initialize = InitializeSkeletons,
    Toggle = ToggleSkeleton,
    UpdateColor = function(color)
        getgenv().Pinguin.Visuals.Skeleton.Color = color
        for _, data in pairs(playerSkeletons) do
            for _, line in ipairs(data.lines) do
                line.Color = color
            end
        end
    end,
    UpdateTransparency = function(transparency)
        getgenv().Pinguin.Visuals.Skeleton.Transparency = transparency
        for _, data in pairs(playerSkeletons) do
            for _, line in ipairs(data.lines) do
                line.Transparency = transparency
            end
        end
    end
}
