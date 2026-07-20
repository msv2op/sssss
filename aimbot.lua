local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local Vector2new, CFramenew, Drawingnew = Vector2.new, CFrame.new, Drawing.new

local Pinguin = getgenv().Pinguin
if not Pinguin then return end

local FOVCircle = Drawingnew("Circle")
local Locked = nil
local triggerBotConnection
local renderSteppedConnection
local heartbeatConnection
local inputBeganConnection
local inputEndedConnection

local localPlayer = Players.LocalPlayer

local possibleHitParts = {
    "RightUpperLeg", "RightLowerLeg", "RightFoot",
    "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
    "UpperTorso", "LowerTorso", "HumanoidRootPart",
    "LeftUpperArm", "LeftLowerArm", "LeftHand",
    "RightUpperArm", "RightLowerArm", "RightHand",
    "Head"
}

local function RandomizeLockPart()
    local part = Pinguin.Aimbot.Settings.LockPart
    if part == "Randomization" then
        return possibleHitParts[math.random(1, #possibleHitParts)]
    else
        return part
    end
end

local function IsInFOV(player)
    local targetPart = player.Character and player.Character:FindFirstChild(RandomizeLockPart())
    if not targetPart then return false end

    local screenPoint = Camera:WorldToViewportPoint(targetPart.Position)
    local distance = (Vector2new(screenPoint.X, screenPoint.Y) - UserInputService:GetMouseLocation()).Magnitude
    return distance <= FOVCircle.Radius
end

local function IsVisible(part)
    if not Pinguin.Aimbot.Settings.WallCheck then return true end
    local origin = Camera.CFrame.Position
    local direction = (part.Position - origin).Unit * 500
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {Camera, Players.LocalPlayer.Character}

    local result = workspace:Raycast(origin, direction, raycastParams)
    return not result or result.Instance:IsDescendantOf(part.Parent)
end

local function GetClosestPlayer()
    local closest, closestDistance = nil, math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Players.LocalPlayer and player.Character then
            -- Check TeamCheck
            local isTeammate = Pinguin.Aimbot.Settings.TeamCheck and Pinguin.IsTeammate(player)
            
            if not isTeammate then
                local targetPart = player.Character:FindFirstChild(RandomizeLockPart())
                if targetPart and IsInFOV(player) and IsVisible(targetPart) then
                    local screenPoint = Camera:WorldToViewportPoint(targetPart.Position)
                    local distance = (Vector2new(screenPoint.X, screenPoint.Y) - UserInputService:GetMouseLocation()).Magnitude
                    if distance < closestDistance then
                        closest, closestDistance = player, distance
                    end
                end
            end
        end
    end
    return closest
end

local function InitConnections()
    if renderSteppedConnection then return end

    renderSteppedConnection = RunService.RenderStepped:Connect(function()
        FOVCircle.Visible = Pinguin.Aimbot.FOVSettings.Visible
        FOVCircle.Thickness = Pinguin.Aimbot.FOVSettings.Thickness
        FOVCircle.Transparency = Pinguin.Aimbot.FOVSettings.Transparency
        FOVCircle.NumSides = Pinguin.Aimbot.FOVSettings.NumSides
        FOVCircle.Position = UserInputService:GetMouseLocation()

        if Locked and Pinguin.Aimbot.Settings.Enabled then
            local targetPart = Locked.Character and Locked.Character:FindFirstChild(RandomizeLockPart())
            if targetPart then
                local targetPosition = targetPart.Position
                local rootPart = Locked.Character:FindFirstChild("HumanoidRootPart")
                local playerVelocity = rootPart and rootPart.Velocity or Vector3.zero
                targetPosition = targetPosition + playerVelocity * Pinguin.Aimbot.Settings.Prediction

                if Pinguin.Aimbot.Settings.AimMethod == "MouseMoveRel (LEGIT)" then
                    local currentMousePos = UserInputService:GetMouseLocation()
                    local targetScreenPos = Camera:WorldToViewportPoint(targetPosition)
                    local deltaX = (targetScreenPos.X - currentMousePos.X) * Pinguin.Aimbot.Settings.ThirdPersonSensitivity
                    local deltaY = (targetScreenPos.Y - currentMousePos.Y) * Pinguin.Aimbot.Settings.ThirdPersonSensitivity
                    if mousemoverel then
                        mousemoverel(deltaX, deltaY)
                    end
                elseif Pinguin.Aimbot.Settings.AimMethod == "CFrame (RISKY)" then
                    Camera.CFrame = CFramenew(Camera.CFrame.Position, targetPosition)
                end
                FOVCircle.Color = Pinguin.Aimbot.FOVSettings.LockedColor
            else
                Locked = nil
            end
        else
            FOVCircle.Color = Pinguin.Aimbot.FOVSettings.Color
        end
    end)

    inputBeganConnection = UserInputService.InputBegan:Connect(function(input)
        local isTriggerKey = false
        if input.UserInputType == Enum.UserInputType.Keyboard then
            isTriggerKey = input.KeyCode == Pinguin.Aimbot.Settings.TriggerKey
        elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 then
            isTriggerKey = input.UserInputType == Pinguin.Aimbot.Settings.TriggerKey
        end

        if isTriggerKey and Pinguin.Aimbot.Settings.Enabled then
            local closestPlayer = GetClosestPlayer()
            if closestPlayer then
                Locked = closestPlayer
            end
        end
    end)

    inputEndedConnection = UserInputService.InputEnded:Connect(function(input)
        local isTriggerKey = false
        if input.UserInputType == Enum.UserInputType.Keyboard then
            isTriggerKey = input.KeyCode == Pinguin.Aimbot.Settings.TriggerKey
        elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 then
            isTriggerKey = input.UserInputType == Pinguin.Aimbot.Settings.TriggerKey
        end

        if isTriggerKey then
            Locked = nil
        end
    end)

    heartbeatConnection = RunService.Heartbeat:Connect(function()
        local humanoidRootPart = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
        if Pinguin.Aimbot.FOVSettings.DynamicFOV and humanoidRootPart then
            local closestDistance = math.huge
            local thresholdDistance = 20
            local dynamicRadius = Pinguin.Aimbot.FOVSettings.Radius

            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= localPlayer and player.Character then
                    local enemyRootPart = player.Character:FindFirstChild("HumanoidRootPart")
                    if enemyRootPart then
                        local distance = (enemyRootPart.Position - humanoidRootPart.Position).magnitude
                        if distance < closestDistance then
                            closestDistance = distance
                        end
                    end
                end
            end

            if closestDistance < thresholdDistance then
                dynamicRadius = Pinguin.Aimbot.FOVSettings.Radius + (thresholdDistance - closestDistance) * 5
            else
                dynamicRadius = Pinguin.Aimbot.FOVSettings.Radius
            end
            FOVCircle.Radius = dynamicRadius
        else
            FOVCircle.Radius = Pinguin.Aimbot.FOVSettings.Radius
        end
    end)
end

local Module = {}

function Module.ToggleTriggerbot(enabled)
    Pinguin.Aimbot.Settings.TriggerBot = enabled
    if enabled then
        if not triggerBotConnection then
            triggerBotConnection = RunService.RenderStepped:Connect(function()
                local mouse = localPlayer:GetMouse()
                if mouse.Target and mouse.Target.Parent:FindFirstChild("Humanoid") and mouse.Target.Parent.Name ~= localPlayer.Name then
                    if mouse1press then
                        mouse1press()
                        task.wait()
                        mouse1release()
                    end
                end
            end)
        end
    else
        if triggerBotConnection then
            triggerBotConnection:Disconnect()
            triggerBotConnection = nil
        end
    end
end

function Module.Unload()
    if renderSteppedConnection then renderSteppedConnection:Disconnect() renderSteppedConnection = nil end
    if inputBeganConnection then inputBeganConnection:Disconnect() inputBeganConnection = nil end
    if inputEndedConnection then inputEndedConnection:Disconnect() inputEndedConnection = nil end
    if heartbeatConnection then heartbeatConnection:Disconnect() heartbeatConnection = nil end
    Module.ToggleTriggerbot(false)
    FOVCircle.Visible = false
    FOVCircle:Remove()
    Locked = nil
end

InitConnections()

return Module
