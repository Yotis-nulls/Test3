-- palofsc: Rayfield arayüzü ile entegre edilmiş, takım ve görünürlük kontrollü AimLock ve Menü Kısayolu

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local UserInputService = game:GetService("UserInputService")

-- Ayarlar
local AimEnabled = false
local VisibilityCheck = true
local EspEnabled = false

-- Rayfield Arayüzü
local Window = Rayfield:CreateWindow({
   Name = "Arsenal Pro",
   LoadingTitle = "Script Yükleniyor...",
   LoadingSubtitle = "by palofsc",
   ConfigurationSaving = { Enabled = false },
   KeySystem = false
})

local Tab = Window:CreateTab("Combat", nil)
local TabEsp = Window:CreateTab("Visuals", nil)

Tab:CreateToggle({
   Name = "AimLock",
   CurrentValue = false,
   Callback = function(Value) AimEnabled = Value end
})

Tab:CreateToggle({
   Name = "Visibility Check (Duvar Arkası Kilitlenme)",
   CurrentValue = true,
   Callback = function(Value) VisibilityCheck = Value end
})

TabEsp:CreateToggle({
   Name = "Player ESP (Highlight)",
   CurrentValue = false,
   Callback = function(Value) 
      EspEnabled = Value 
      if not EspEnabled then
         for _, p in pairs(Players:GetPlayers()) do
            if p.Character and p.Character:FindFirstChild("Highlight") then
               p.Character.Highlight:Destroy()
            end
         end
      end
   end
})

-- MENÜ AÇMA / KAPATMA TUŞU (INSERT TUŞU)
local isMenuVisible = true
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.Insert then
        isMenuVisible = not isMenuVisible
        
        -- Rayfield arayüzünü gizleme / gösterme mantığı
        local coreGui = game:GetService("CoreGui")
        local rayfieldUI = coreGui:FindFirstChild("Rayfield")
        
        if rayfieldUI then
            for _, child in ipairs(rayfieldUI:GetChildren()) do
                if child:IsA("ScreenGui") then
                    child.Enabled = isMenuVisible
                end
            end
        end
        
        if isMenuVisible then
            Rayfield:Notify({Title = "Panel", Content = "Menü açıldı.", Duration = 2})
        else
            Rayfield:Notify({Title = "Panel", Content = "Menü gizlendi. (INSERT ile tekrar açabilirsin)", Duration = 2})
        end
    end
end)

-- Kusursuz Görünürlük / Duvar Arkası Kontrolü
local function isVisible(targetPart, character)
    local origin = Camera.CFrame.Position
    local direction = targetPart.Position - origin
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, character}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    
    local raycastResult = workspace:Raycast(origin, direction, raycastParams)
    
    if raycastResult then
        return raycastResult.Instance:IsDescendantOf(character)
    end
    return false
end

-- RenderStepped (AimLock & ESP)
RunService.RenderStepped:Connect(function()
    -- ESP Mantığı
    if EspEnabled then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local isTeammate = (player.Team == LocalPlayer.Team)
                
                local h = player.Character:FindFirstChild("Highlight") or Instance.new("Highlight", player.Character)
                h.Adornee = player.Character
                h.FillColor = isTeammate and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
                h.OutlineColor = Color3.fromRGB(255, 255, 255)
                h.FillTransparency = 0.5
            end
        end
    end

    -- AimLock Mantığı
    if not AimEnabled then return end
    
    local closestPlayer = nil
    local shortestDistance = math.huge
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
            
            -- KENDİ TAKIMINA KİLİTLENMEYİ ÖNLEME
            if player.Team == LocalPlayer.Team then continue end
            
            -- Ölüleri hedef alma
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health <= 0 then continue end
            
            -- GÖRÜNÜRLÜK (Duvar Arkası) KONTROLÜ
            if VisibilityCheck and not isVisible(player.Character.Head, player.Character) then continue end
            
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
