-- Visuals (TRACERS) (ertedTRACERSgfdwq.lua) (PinguinDEV)
local Drawing = Drawing or require(game:GetService("Drawing"))
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

getgenv().Pinguin = getgenv().Pinguin or {}
getgenv().Pinguin.TracerModule = getgenv().Pinguin.TracerModule or {
    Settings = {
        Enabled = true,
        Transparency = 1,
        Thickness = 1,
        Color = Color3.new(1, 1, 1),
        TracerPosition = "Bottom"
    },
    WrappedPlayers = {}
}
local Environment = getgenv().Pinguin.TracerModule

local function getTracerStartPosition()
    local viewportSize = Camera.ViewportSize
    if Environment.Settings.TracerPosition == "Center" then
        return Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
    elseif Environment.Settings.TracerPosition == "Mouse" then
        return UserInputService:GetMouseLocation()
    elseif Environment.Settings.TracerPosition == "Top" then
        return Vector2.new(viewportSize.X / 2, 0)
    elseif Environment.Settings.TracerPosition == "Left" then
        return Vector2.new(0, viewportSize.Y / 2)
    elseif Environment.Settings.TracerPosition == "Right" then
        return Vector2.new(viewportSize.X, viewportSize.Y / 2)
    else
        return Vector2.new(viewportSize.X / 2, viewportSize.Y)
    end
end

local function getTracerTargetPosition(Player, Pos, From)
    local useBox = getgenv().PinguinHub and getgenv().PinguinHub.WallHack and getgenv().PinguinHub.WallHack.Settings.BoxSettings.Enabled
    if useBox and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
        local height = Player.Character.HumanoidRootPart.Size.Y * 2200
        local sizeX = 2000 / Pos.Z
        local sizeY = height / Pos.Z
        local top = Pos.Y - sizeY / 2.475
        local bottom = top + sizeY
        local left = Pos.X - sizeX / 2
        local right = Pos.X + sizeX / 2
        local centerX = Pos.X
        local centerY = top + sizeY / 2

        if Environment.Settings.TracerPosition == "Bottom" then
            return Vector2.new(centerX, bottom)
        elseif Environment.Settings.TracerPosition == "Top" then
            return Vector2.new(centerX, top)
        elseif Environment.Settings.TracerPosition == "Left" then
            return Vector2.new(left, centerY)
        elseif Environment.Settings.TracerPosition == "Right" then
            return Vector2.new(right, centerY)
        else
            -- Mouse or Center: Connect to closest point on box outline
            local targetX = math.clamp(From.X, left, right)
            local targetY = math.clamp(From.Y, top, bottom)
            
            -- If strictly outline, force it to an edge if it's inside
            if targetX > left and targetX < right and targetY > top and targetY < bottom then
                local dLeft = targetX - left
                local dRight = right - targetX
                local dTop = targetY - top
                local dBottom = bottom - targetY
                local minDist = math.min(dLeft, dRight, dTop, dBottom)
                if minDist == dLeft then targetX = left
                elseif minDist == dRight then targetX = right
                elseif minDist == dTop then targetY = top
                else targetY = bottom end
            end
            
            return Vector2.new(targetX, targetY)
        end
    end

    return Vector2.new(Pos.X, Pos.Y)
end

local function Wrap(Player)
    local PlayerTable = Environment.WrappedPlayers[Player.Name]

    if not PlayerTable then
        PlayerTable = { Tracer = Drawing.new("Line"), Connections = {} }
        Environment.WrappedPlayers[Player.Name] = PlayerTable

        PlayerTable.Connections.Tracer = RunService.RenderStepped:Connect(function()
            local isTeammate = getgenv().Pinguin.Visuals and getgenv().Pinguin.Visuals.TeamCheck and getgenv().Pinguin.IsTeammate(Player)
            
            if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") and Environment.Settings.Enabled and not isTeammate then
                local Position, OnScreen = Camera:WorldToViewportPoint(Player.Character.HumanoidRootPart.Position)

                if OnScreen then
                    local fromPos = getTracerStartPosition()
                    PlayerTable.Tracer.Visible = true
                    PlayerTable.Tracer.From = fromPos
                    PlayerTable.Tracer.To = getTracerTargetPosition(Player, Position, fromPos)

                    PlayerTable.Tracer.Color = Environment.Settings.Color
                    PlayerTable.Tracer.Thickness = Environment.Settings.Thickness
                    PlayerTable.Tracer.Transparency = Environment.Settings.Transparency
                else
                    PlayerTable.Tracer.Visible = false
                end
            else
                PlayerTable.Tracer.Visible = false
            end
        end)
    end
end

local function UnWrap(Player)
    if Environment.WrappedPlayers[Player.Name] then
        local PlayerTable = Environment.WrappedPlayers[Player.Name]
        PlayerTable.Tracer:Remove()
        PlayerTable.Connections.Tracer:Disconnect()
        Environment.WrappedPlayers[Player.Name] = nil
    end
end

local function Load()
    for _, Player in ipairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer then
            Wrap(Player)
        end
    end

    Players.PlayerAdded:Connect(Wrap)
    Players.PlayerRemoving:Connect(UnWrap)
end

local function toggleTracersESP(state)
    Environment.Settings.Enabled = state

    if state then
        Load()
    else
        for PlayerName, PlayerTable in pairs(Environment.WrappedPlayers) do
            UnWrap(Players:FindFirstChild(PlayerName))
        end
    end
end

return toggleTracersESP