-- palofsc: Rayfield arayüzü ile entegre edilmiş, takım ve görünürlük kontrollü AimLock

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Ayarlar
local AimEnabled = false
local VisibilityCheck = true

-- Rayfield Arayüzü
local Window = Rayfield:CreateWindow({
   Name = "Arsenal Pro",
   LoadingTitle = "Script Yükleniyor...",
   LoadingSubtitle = "by palofsc",
   KeySystem = false
})

local Tab = Window:CreateTab("Combat", nil)

Tab:CreateToggle({
   Name = "AimLock",
   CurrentValue = false,
   Callback = function(Value) AimEnabled = Value end
})

Tab:CreateToggle({
   Name = "Visibility Check",
   CurrentValue = true,
   Callback = function(Value) VisibilityCheck = Value end
})

-- Görünürlük Kontrolü
local function isVisible(targetPart)
    local origin = Camera.CFrame.Position
    local direction = targetPart.Position - origin
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, workspace.CurrentCamera}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    
    local raycastResult = workspace:Raycast(origin, direction, raycastParams)
    return raycastResult and raycastResult.Instance:IsDescendantOf(targetPart.Parent)
end

-- AimLock Mantığı
RunService.RenderStepped:Connect(function()
    if not AimEnabled then return end
    
    local closestPlayer = nil
    local shortestDistance = math.huge
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
            -- Takım Kontrolü
            if player.Team == LocalPlayer.Team then continue end
            
            -- Görünürlük Kontrolü
            if VisibilityCheck and not isVisible(player.Character.Head) then continue end
            
            local pos, onScreen = Camera:WorldToViewportPoint(player.Character.Head.Position)
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
