local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Pinguin = getgenv().Pinguin
if not Pinguin then return end

local TeleportConnection
local SpectateConnection
local FovConnection

local Module = {}

-- MOUSE CLICK TP
function Module.ToggleMouseTP(state)
    Pinguin.Camera.MouseTP.Enabled = state
    if state then
        if not TeleportConnection then
            TeleportConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if not gameProcessed and input.UserInputType == Enum.UserInputType.MouseButton1 then
                    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                        local mouse = LocalPlayer:GetMouse()
                        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(mouse.Hit.Position)
                        end
                    end
                end
            end)
        end
    else
        if TeleportConnection then
            TeleportConnection:Disconnect()
            TeleportConnection = nil
        end
    end
end

-- FOV CHANGER
function Module.ToggleFOV(state)
    Pinguin.Camera.FOV.Enabled = state
    if state then
        if not FovConnection then
            FovConnection = RunService.RenderStepped:Connect(function()
                if Pinguin.Camera.FOV.Enabled then
                    Camera.FieldOfView = Pinguin.Camera.FOV.Value
                end
            end)
        end
    else
        if FovConnection then
            FovConnection:Disconnect()
            FovConnection = nil
        end
        Camera.FieldOfView = 70
    end
end

-- SPECTATE
function Module.ToggleSpectate(state)
    Pinguin.Camera.Spectate.Enabled = state
    if state then
        if not SpectateConnection then
            SpectateConnection = RunService.RenderStepped:Connect(function()
                if Pinguin.Camera.Spectate.Enabled and Pinguin.Camera.Spectate.Target then
                    local targetPlayer = Players:FindFirstChild(Pinguin.Camera.Spectate.Target)
                    if targetPlayer and targetPlayer.Character then
                        local hum = targetPlayer.Character:FindFirstChild("Humanoid")
                        if hum then
                            Camera.CameraSubject = hum
                        end
                    end
                else
                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                        Camera.CameraSubject = LocalPlayer.Character.Humanoid
                    end
                end
            end)
        end
    else
        if SpectateConnection then
            SpectateConnection:Disconnect()
            SpectateConnection = nil
        end
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            Camera.CameraSubject = LocalPlayer.Character.Humanoid
        end
    end
end

function Module.Unload()
    Module.ToggleMouseTP(false)
    Module.ToggleFOV(false)
    Module.ToggleSpectate(false)
end

return Module
