local Lighting = game:GetService("Lighting")

local Pinguin = getgenv().Pinguin
if not Pinguin then return end

local colorCorrection = Lighting:FindFirstChild("PinguinColorCorrection")
if not colorCorrection then
    colorCorrection = Instance.new("ColorCorrectionEffect")
    colorCorrection.Name = "PinguinColorCorrection"
    colorCorrection.Brightness = 0
    colorCorrection.Contrast = 0
    colorCorrection.Saturation = 0
    colorCorrection.Parent = Lighting
end

local Module = {}

function Module.UpdateWorld()
    if Pinguin.World.Ambient.Enabled then
        Lighting.Ambient = Pinguin.World.Ambient.Color
    else
        Lighting.Ambient = Color3.fromRGB(127, 127, 127)
    end

    if Pinguin.World.Fog.Enabled then
        Lighting.FogColor = Pinguin.World.Fog.Color
        Lighting.FogEnd = 100
        Lighting.FogStart = 0
    else
        Lighting.FogColor = Color3.fromRGB(255, 255, 255)
        Lighting.FogEnd = 100000
        Lighting.FogStart = 0
    end

    if Pinguin.World.Saturation.Enabled then
        colorCorrection.Saturation = Pinguin.World.Saturation.Value / 100
    else
        colorCorrection.Saturation = 0
    end

    if Pinguin.World.Time.Enabled then
        Lighting:SetMinutesAfterMidnight(Pinguin.World.Time.Value * 60)
    end
end

function Module.Unload()
    Lighting.Ambient = Color3.fromRGB(127, 127, 127)
    Lighting.FogColor = Color3.fromRGB(255, 255, 255)
    Lighting.FogEnd = 100000
    Lighting.FogStart = 0
    if colorCorrection then
        colorCorrection:Destroy()
        colorCorrection = nil
    end
end

return Module
