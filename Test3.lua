-- palofsc: Kusursuz Görünürlük ve FOV Kontrollü Orijinal AimLock

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local UserInputService = game:GetService("UserInputService")

-- Ayarlar
local AimEnabled = false
local EspEnabled = false
local FovRadius = 150 -- FOV Çemberinin Büyüklüğü (Merkez)

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

Tab:CreateSlider({
   Name = "FOV Çapı (Büyüklük)",
   Range = {50, 400},
   Increment = 10,
   CurrentValue = 150,
   Callback = function(Value) FovRadius = Value end
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

-- Ekrana Yuvarlak (FOV Çemberi) Ekleme
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 1
fovCircle.NumSides = 60
fovCircle.Radius = FovRadius
fovCircle.Filled = false
fovCircle.Color = Color3.fromRGB(255, 255, 255)
fovCircle.Visible = false

-- Menü Açma / Kapatma Tuşu (INSERT TUŞU)
local isMenuVisible = true
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.Insert then
        isMenuVisible = not isMenuVisible
        local coreGui = game:GetService("CoreGui")
        local rayfieldUI = coreGui:FindFirstChild("Rayfield")
        if rayfieldUI then
            for _, child in ipairs(rayfieldUI:GetChildren()) do
                if child:IsA("ScreenGui") then child.Enabled = isMenuVisible end
            end
        end
    end
end)

-- Kusursuz Duvar Arkası Kontrolü (Canlı Tarama)
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

-- RenderStepped (AimLock & ESP & FOV)
RunService.RenderStepped:Connect(function()
    -- FOV Çemberini Güncelle
    fovCircle.Radius = FovRadius
    fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    fovCircle.Visible = AimEnabled

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
    local centerScreen = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local shortestDistance = FovRadius 
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
            
            -- 1. Kendi Takımına Kilitlememe
            if player.Team == LocalPlayer.Team then continue end
            
            -- 2. Ölüleri Hedef Almama
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health <= 0 then continue end
            
            -- 3. FOV Çemberi İçi/Dışı Kontrolü (Ekran merkezine göre mesafesi)
            local pos, onScreen = Camera:WorldToViewportPoint(player.Character.Head.Position)
            if onScreen then
                local mouseDistance = (Vector2.new(pos.X, pos.Y) - centerScreen).Magnitude
                
                -- Eğer çemberin dışındaysa bu hedefi direkt es geç
                if mouseDistance > FovRadius then continue end
                
                -- 4. Görünürlük / Canlı Duvar Arkası Kesme Kontrolü
                if not isVisible(player.Character.Head, player.Character) then continue end
                
                if mouseDistance < shortestDistance then
                    shortestDistance = mouseDistance
                    closestPlayer = player
                end
            end
        end
    end
    
    -- Orijinal Ekran Sabitleme (AimLock)
    if closestPlayer then
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, closestPlayer.Character.Head.Position)
    end
end)
