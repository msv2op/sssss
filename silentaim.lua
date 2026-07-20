local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

getgenv().Pinguin = getgenv().Pinguin or {}
getgenv().Pinguin.SilentAim = getgenv().Pinguin.SilentAim or {
    Settings = {
        Enabled = false,
        TeamCheck = false,
        VisibleCheck = false,
        TargetPart = "HumanoidRootPart",
        Method = "Raycast",
        HitChance = 100,
        MouseHitPrediction = false,
        PredictionAmount = 0.165,
        ShowTarget = false
    },
    FOVSettings = {
        Visible = false,
        Radius = 130,
        Color = Color3.fromRGB(54, 57, 241),
        Thickness = 1,
        Transparency = 1,
        NumSides = 100
    }
}

local ValidTargetParts = {"Head", "HumanoidRootPart"}

local mouse_box = Drawing.new("Square")
mouse_box.Visible = false 
mouse_box.ZIndex = 999 
mouse_box.Color = Color3.fromRGB(54, 57, 241)
mouse_box.Thickness = 2 
mouse_box.Size = Vector2.new(20, 20)
mouse_box.Filled = false 

local fov_circle = Drawing.new("Circle")
fov_circle.Thickness = 1
fov_circle.NumSides = 100
fov_circle.Radius = 130
fov_circle.Filled = false
fov_circle.Visible = false
fov_circle.ZIndex = 999
fov_circle.Transparency = 1
fov_circle.Color = Color3.fromRGB(54, 57, 241)

local ExpectedArguments = {
    FindPartOnRayWithIgnoreList = { ArgCountRequired = 3, Args = { "Instance", "Ray", "table", "boolean", "boolean" } },
    FindPartOnRayWithWhitelist = { ArgCountRequired = 3, Args = { "Instance", "Ray", "table", "boolean" } },
    FindPartOnRay = { ArgCountRequired = 2, Args = { "Instance", "Ray", "Instance", "boolean", "boolean" } },
    Raycast = { ArgCountRequired = 3, Args = { "Instance", "Vector3", "Vector3", "RaycastParams" } }
}

local function CalculateChance(Percentage)
    Percentage = math.floor(Percentage)
    local chance = math.floor(Random.new().NextNumber(Random.new(), 0, 1) * 100) / 100
    return chance <= Percentage / 100
end

local function getPositionOnScreen(Vector)
    local Vec3, OnScreen = Camera:WorldToViewportPoint(Vector)
    return Vector2.new(Vec3.X, Vec3.Y), OnScreen
end

local function ValidateArguments(Args, RayMethod)
    local Matches = 0
    if #Args < RayMethod.ArgCountRequired then return false end
    for Pos, Argument in next, Args do
        if typeof(Argument) == RayMethod.Args[Pos] then Matches = Matches + 1 end
    end
    return Matches >= RayMethod.ArgCountRequired
end

local function getDirection(Origin, Position)
    return (Position - Origin).Unit * 1000
end

local function getMousePosition()
    return UserInputService:GetMouseLocation()
end

local function IsPlayerVisible(Player)
    local PlayerCharacter = Player.Character
    local LocalPlayerCharacter = LocalPlayer.Character
    if not (PlayerCharacter or LocalPlayerCharacter) then return false end 
    
    local targetPartName = getgenv().Pinguin.SilentAim.Settings.TargetPart
    if targetPartName == "Random" then targetPartName = "HumanoidRootPart" end
    
    local PlayerRoot = PlayerCharacter:FindFirstChild(targetPartName) or PlayerCharacter:FindFirstChild("HumanoidRootPart")
    if not PlayerRoot then return false end 
    
    local CastPoints = {PlayerRoot.Position, LocalPlayerCharacter, PlayerCharacter}
    local IgnoreList = {LocalPlayerCharacter, PlayerCharacter}
    local ObscuringObjects = #Camera:GetPartsObscuringTarget(CastPoints, IgnoreList)
    
    return ObscuringObjects == 0
end

local function getClosestPlayer()
    local cfg = getgenv().Pinguin.SilentAim.Settings
    if not cfg.Enabled then return nil end
    
    local Closest = nil
    local DistanceToMouse = math.huge
    
    for _, Player in pairs(Players:GetPlayers()) do
        if Player == LocalPlayer then continue end
        
        if cfg.TeamCheck and getgenv().Pinguin.IsTeammate and getgenv().Pinguin.IsTeammate(Player) then continue end

        local Character = Player.Character
        if not Character then continue end
        
        if cfg.VisibleCheck and not IsPlayerVisible(Player) then continue end

        local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
        local Humanoid = Character:FindFirstChild("Humanoid")
        if not HumanoidRootPart or not Humanoid or Humanoid.Health <= 0 then continue end

        local ScreenPosition, OnScreen = getPositionOnScreen(HumanoidRootPart.Position)
        if not OnScreen then continue end

        local Distance = (getMousePosition() - ScreenPosition).Magnitude
        if Distance <= getgenv().Pinguin.SilentAim.FOVSettings.Radius and Distance < DistanceToMouse then
            local targetPartName = cfg.TargetPart
            if targetPartName == "Random" then
                targetPartName = ValidTargetParts[math.random(1, #ValidTargetParts)]
            end
            Closest = Character:FindFirstChild(targetPartName)
            DistanceToMouse = Distance
        end
    end
    return Closest
end

local RenderConnection = RunService.RenderStepped:Connect(function()
    local cfg = getgenv().Pinguin.SilentAim.Settings
    local fovCfg = getgenv().Pinguin.SilentAim.FOVSettings

    if cfg.ShowTarget and cfg.Enabled then
        local TargetPart = getClosestPlayer()
        if TargetPart then 
            local RootToViewportPoint, IsOnScreen = Camera:WorldToViewportPoint(TargetPart.Position)
            mouse_box.Visible = IsOnScreen
            mouse_box.Position = Vector2.new(RootToViewportPoint.X - 10, RootToViewportPoint.Y - 10)
        else 
            mouse_box.Visible = false 
        end
    else
        mouse_box.Visible = false
    end
    
    if fovCfg.Visible then 
        fov_circle.Visible = true
        fov_circle.Color = fovCfg.Color
        fov_circle.Radius = fovCfg.Radius
        fov_circle.Thickness = fovCfg.Thickness
        fov_circle.Transparency = fovCfg.Transparency
        fov_circle.NumSides = fovCfg.NumSides
        fov_circle.Position = getMousePosition()
    else
        fov_circle.Visible = false
    end
end)

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(...)
    local Method = getnamecallmethod()
    local Arguments = {...}
    local self = Arguments[1]
    
    local cfg = getgenv().Pinguin.SilentAim.Settings
    if not cfg.Enabled then return oldNamecall(...) end
    
    local chance = CalculateChance(cfg.HitChance)
    if self == workspace and not checkcaller() and chance == true then
        local HitPart = getClosestPlayer()
        if HitPart then
            if Method == "FindPartOnRayWithIgnoreList" and cfg.Method == Method then
                if ValidateArguments(Arguments, ExpectedArguments.FindPartOnRayWithIgnoreList) then
                    local Origin = Arguments[2].Origin
                    Arguments[2] = Ray.new(Origin, getDirection(Origin, HitPart.Position))
                    return oldNamecall(unpack(Arguments))
                end
            elseif Method == "FindPartOnRayWithWhitelist" and cfg.Method == Method then
                if ValidateArguments(Arguments, ExpectedArguments.FindPartOnRayWithWhitelist) then
                    local Origin = Arguments[2].Origin
                    Arguments[2] = Ray.new(Origin, getDirection(Origin, HitPart.Position))
                    return oldNamecall(unpack(Arguments))
                end
            elseif (Method == "FindPartOnRay" or Method == "findPartOnRay") and cfg.Method:lower() == Method:lower() then
                if ValidateArguments(Arguments, ExpectedArguments.FindPartOnRay) then
                    local Origin = Arguments[2].Origin
                    Arguments[2] = Ray.new(Origin, getDirection(Origin, HitPart.Position))
                    return oldNamecall(unpack(Arguments))
                end
            elseif Method == "Raycast" and cfg.Method == Method then
                if ValidateArguments(Arguments, ExpectedArguments.Raycast) then
                    local Origin = Arguments[2]
                    Arguments[3] = getDirection(Origin, HitPart.Position)
                    return oldNamecall(unpack(Arguments))
                end
            end
        end
    end
    return oldNamecall(...)
end))

local oldIndex = nil 
oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, Index)
    local cfg = getgenv().Pinguin.SilentAim.Settings
    if self == Mouse and not checkcaller() and cfg.Enabled and cfg.Method == "Mouse.Hit/Target" then
        local HitPart = getClosestPlayer()
        if HitPart then
            if Index == "Target" or Index == "target" then 
                return HitPart
            elseif Index == "Hit" or Index == "hit" then 
                local targetCFrame = HitPart.CFrame
                if cfg.MouseHitPrediction and HitPart.Parent:FindFirstChild("HumanoidRootPart") then
                    targetCFrame = targetCFrame + (HitPart.Parent.HumanoidRootPart.Velocity * cfg.PredictionAmount)
                end
                return targetCFrame
            elseif Index == "X" or Index == "x" then 
                return self.X 
            elseif Index == "Y" or Index == "y" then 
                return self.Y 
            elseif Index == "UnitRay" then 
                return Ray.new(self.Origin, (self.Hit - self.Origin).Unit)
            end
        end
    end
    return oldIndex(self, Index)
end))

return {
    Unload = function()
        if RenderConnection then RenderConnection:Disconnect() end
        mouse_box:Remove()
        fov_circle:Remove()
        getgenv().Pinguin.SilentAim.Settings.Enabled = false
    end
}
