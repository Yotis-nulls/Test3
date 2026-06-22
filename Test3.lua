-- palofsc: Arsenal için takım kontrollü ve görünürlük denetimli AimLock

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local AimEnabled = false
-- Rayfield arayüzü entegrasyonu için değişken
local VisibilityCheck = true

-- Rayfield Tab oluşturma (örnek)
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({Name = "Arsenal Advanced", LoadingTitle = "Loading...", KeySystem = false})
local Tab = Window:CreateTab("Combat", nil)

Tab:CreateToggle({
   Name = "AimLock",
   Callback = function(Value) AimEnabled = Value end
})

Tab:CreateToggle({
   Name = "Visibility Check",
   CurrentValue = true,
   Callback = function(Value) VisibilityCheck = Value end
})

-- Görünürlük denetimi fonksiyonu
local function isVisible(targetPart)
    local origin = Camera.CFrame.Position
    local targetPos = targetPart.Position
    local ray = Ray.new(origin, targetPos - origin)
    local hit, position = workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character, workspace.CurrentCamera})
    
    if hit then
        return hit:IsDescendantOf(targetPart.Parent)
    end
    return false
end

-- AimLock ana döngüsü
RunService.RenderStepped:Connect(function()
    if not AimEnabled then return end
    
    local closestPlayer = nil
    local shortestDistance = math.huge
    
    for _, player in pairs(Players:GetPlayers()) do
        -- Takım kontrolü ve karakter kontrolü
        if player ~= LocalPlayer and player.Team ~= LocalPlayer.Team and player.Character and player.Character:FindFirstChild("Head") then
            local head = player.Character.Head
            
            -- Görünürlük kontrolü
            if VisibilityCheck and not isVisible(head) then continue end
            
            local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
            if onScreen then
                local distance = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    closestPlayer = player
                end
            end
        end
    end
    
    if closestPlayer then
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, closestPlayer.Character.Head.Position)
    end
end)
