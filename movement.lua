local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local Pinguin = getgenv().Pinguin
if not Pinguin then return end

local playerCharacter, playerHumanoid, playerHumanoidRootPart

local function updateCharacterReferences()
    if LocalPlayer.Character then
        playerCharacter = LocalPlayer.Character
    else
        playerCharacter = LocalPlayer.CharacterAdded:Wait()
    end
    playerHumanoid = playerCharacter:WaitForChild("Humanoid")
    playerHumanoidRootPart = playerCharacter:WaitForChild("HumanoidRootPart")
end

updateCharacterReferences()
LocalPlayer.CharacterAdded:Connect(updateCharacterReferences)

-- Modules
local WalkspeedLoop
local JumpPowerLoop
local SpinbotConnection
local NoclipConnection
local FlyConnection
local FlyPos, FlyGyro, FlyCore

local originalCollideStates = {}
local flying = false
local keys = {w = false, s = false, a = false, d = false}

local Module = {}

-- WALKSPEED & JUMPPOWER (Loop based for exploit resilience)
local function MovementLoop()
    if Pinguin.Movement.WalkSpeed.Enabled and playerHumanoid then
        playerHumanoid.WalkSpeed = Pinguin.Movement.WalkSpeed.Value
    end
    if Pinguin.Movement.JumpPower.Enabled and playerHumanoid then
        playerHumanoid.UseJumpPower = true
        playerHumanoid.JumpPower = Pinguin.Movement.JumpPower.Value
    end
end
RunService.Stepped:Connect(MovementLoop)

function Module.ToggleWalkspeed(state)
    Pinguin.Movement.WalkSpeed.Enabled = state
    if not state and playerHumanoid then
        playerHumanoid.WalkSpeed = 16
    end
end

function Module.ToggleJumpPower(state)
    Pinguin.Movement.JumpPower.Enabled = state
    if not state and playerHumanoid then
        playerHumanoid.UseJumpPower = false
        playerHumanoid.JumpPower = 50
    end
end

-- NOCLIP
local function storeOriginalStates()
    if playerCharacter then
        for _, part in pairs(playerCharacter:GetDescendants()) do
            if part:IsA("BasePart") then
                originalCollideStates[part] = part.CanCollide
            end
        end
    end
end

function Module.ToggleNoclip(state)
    Pinguin.Movement.NoClip.Enabled = state
    if state then
        storeOriginalStates()
        if not NoclipConnection then
            NoclipConnection = RunService.Stepped:Connect(function()
                if playerCharacter then
                    for _, part in pairs(playerCharacter:GetDescendants()) do
                        if part:IsA("BasePart") and part.CanCollide then
                            part.CanCollide = false
                        end
                    end
                end
            end)
        end
    else
        if NoclipConnection then
            NoclipConnection:Disconnect()
            NoclipConnection = nil
        end
        if playerCharacter then
            for part, originalState in pairs(originalCollideStates) do
                if part and part:IsA("BasePart") then
                    part.CanCollide = originalState
                end
            end
        end
        -- Clear state so next toggle re-reads fresh
        table.clear(originalCollideStates)
    end
end

-- SPINBOT
function Module.ToggleSpinbot(state)
    Pinguin.Movement.Spinbot.Enabled = state
    if state then
        if not SpinbotConnection then
            if playerHumanoid then playerHumanoid.AutoRotate = true end
            SpinbotConnection = RunService.RenderStepped:Connect(function()
                if playerHumanoidRootPart then
                    playerHumanoidRootPart.CFrame = playerHumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(Pinguin.Movement.Spinbot.Speed), 0)
                end
            end)
        end
    else
        if SpinbotConnection then
            SpinbotConnection:Disconnect()
            SpinbotConnection = nil
        end
    end
end

LocalPlayer.CharacterAdded:Connect(function(character)
    local hum = character:WaitForChild("Humanoid")
    hum.Died:Connect(function()
        if Pinguin.Movement.Spinbot.Enabled then
            Module.ToggleSpinbot(false)
        end
    end)
end)

-- FLY
local function findTorso(character)
    return character:FindFirstChild("LowerTorso") or 
           character:FindFirstChild("Torso") or 
           character:FindFirstChild("Head")
end

local function NormalFlyLoop()
    if not playerHumanoid or not FlyPos or not FlyGyro then return end
    playerHumanoid.PlatformStand = true
    local new = FlyGyro.CFrame - FlyGyro.CFrame.p + FlyPos.Position
    local speed = Pinguin.Movement.Fly.Speed

    if not keys.w and not keys.s and not keys.a and not keys.d then
        speed = 15
    end

    if keys.w then new = new + workspace.CurrentCamera.CFrame.LookVector * speed end
    if keys.s then new = new - workspace.CurrentCamera.CFrame.LookVector * speed end
    if keys.d then new = new * CFrame.new(speed, 0, 0) end
    if keys.a then new = new * CFrame.new(-speed, 0, 0) end

    FlyPos.Position = new.p
    FlyGyro.CFrame = workspace.CurrentCamera.CFrame
end

local function CFrameFlyLoop()
    if not playerHumanoidRootPart then return end
    local camera = workspace.CurrentCamera
    local direction = Vector3.new(0, 0, 0)
    
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then direction = direction + camera.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then direction = direction - camera.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then direction = direction - camera.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then direction = direction + camera.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then direction = direction + Vector3.new(0, 1, 0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then direction = direction - Vector3.new(0, 1, 0) end

    if direction.Magnitude > 0 then
        direction = direction.Unit * (Pinguin.Movement.Fly.Speed * 10)
        playerHumanoidRootPart.Velocity = Vector3.new(direction.x, direction.y, direction.z)
    else
        playerHumanoidRootPart.Velocity = Vector3.new(0, 3, 0)
    end
end

function Module.ToggleFly(state)
    Pinguin.Movement.Fly.Enabled = state
    if state then
        flying = true
        if Pinguin.Movement.Fly.Method == "Normal" then
            local torso = findTorso(playerCharacter)
            if not torso then return end
            
            FlyCore = Instance.new("Part")
            FlyCore.Name = "Core"
            FlyCore.Size = Vector3.new(0.05, 0.05, 0.05)
            FlyCore.Anchored = false
            FlyCore.Transparency = 1
            FlyCore.CanCollide = false
            FlyCore.Parent = workspace

            local weld = Instance.new("Weld")
            weld.Part0 = FlyCore
            weld.Part1 = torso
            weld.C0 = CFrame.new(0, 0, 0)
            weld.Parent = FlyCore

            FlyPos = Instance.new("BodyPosition")
            FlyPos.Name = "EPIXPOS"
            FlyPos.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            FlyPos.Position = FlyCore.Position
            FlyPos.Parent = FlyCore

            FlyGyro = Instance.new("BodyGyro")
            FlyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            FlyGyro.CFrame = FlyCore.CFrame
            FlyGyro.Parent = FlyCore
            
            if not FlyConnection then
                FlyConnection = RunService.RenderStepped:Connect(NormalFlyLoop)
            end
        else
            if not FlyConnection then
                FlyConnection = RunService.RenderStepped:Connect(CFrameFlyLoop)
            end
        end
    else
        flying = false
        if FlyConnection then
            FlyConnection:Disconnect()
            FlyConnection = nil
        end
        if FlyGyro then FlyGyro:Destroy() end
        if FlyPos then FlyPos:Destroy() end
        if FlyCore then FlyCore:Destroy() end
        if playerHumanoid then playerHumanoid.PlatformStand = false end
        if playerHumanoidRootPart then playerHumanoidRootPart.Velocity = Vector3.new(0, 0, 0) end
    end
end

-- Key handling for Normal Fly
local function onKeyPress(key)
    if key == "w" then keys.w = true
    elseif key == "s" then keys.s = true
    elseif key == "a" then keys.a = true
    elseif key == "d" then keys.d = true
    end
end

local function onKeyRelease(key)
    if key == "w" then keys.w = false
    elseif key == "s" then keys.s = false
    elseif key == "a" then keys.a = false
    elseif key == "d" then keys.d = false
    end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed then
        onKeyPress(input.KeyCode.Name:lower())
    end
end)

UserInputService.InputEnded:Connect(function(input)
    onKeyRelease(input.KeyCode.Name:lower())
end)

function Module.Unload()
    Module.ToggleNoclip(false)
    Module.ToggleSpinbot(false)
    Module.ToggleFly(false)
    Pinguin.Movement.WalkSpeed.Enabled = false
    Pinguin.Movement.JumpPower.Enabled = false
    if playerHumanoid then
        playerHumanoid.WalkSpeed = 16
        playerHumanoid.JumpPower = 50
        playerHumanoid.UseJumpPower = false
    end
end

return Module
