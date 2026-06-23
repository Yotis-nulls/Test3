-- palofsc: Kusursuzlaştırılmış Görünürlük ve Spinbot Entegreli AimLock

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
local RgbGunEnabled = false
local MevlanaEnabled = false

-- Rayfield Arayüzü
local Window = Rayfield:CreateWindow({
   Name = "Arsenal Pro & Fun",
   LoadingTitle = "Modüller Yükleniyor...",
   LoadingSubtitle = "by palofsc",
   ConfigurationSaving = { Enabled = false },
   KeySystem = false
})

local Tab = Window:CreateTab("Combat", nil)
local TabEsp = Window:CreateTab("Visuals", nil)
local TabFun = Window:CreateTab("Fun", nil)

-- Combat Sekmesi
Tab:CreateToggle({
   Name = "AimLock",
   CurrentValue = false,
   Callback = function(Value) AimEnabled = Value end
})

Tab:CreateToggle({
   Name = "Visibility Check (Duvar Arkası Engeli)",
   CurrentValue = true,
   Callback = function(Value) VisibilityCheck = Value end
})

-- Visuals (ESP) Sekmesi
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

-- Fun Sekmesi
TabFun:CreateSlider({
   Name = "Karakter Görüş Açısı (FOV Changer)",
   Range = {70, 120},
   Increment = 5,
   CurrentValue = 70,
   Callback = function(Value) 
      Camera.FieldOfView = Value 
   end
})

TabFun:CreateToggle({
   Name = "RGB Gun (Silah Renk Değişimi)",
   CurrentValue = false,
   Callback = function(Value) 
      RgbGunEnabled = Value 
   end
})

TabFun:CreateToggle({
   Name = "Mevlana (Spinbot)",
   CurrentValue = false,
   Callback = function(Value) 
      MevlanaEnabled = Value 
   end
})

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

-- Optimize Edilmiş Görünürlük Tarama Fonksiyonu
local function isVisible(targetPart, character)
    local origin = Camera.CFrame.Position
    local direction = targetPart.Position - origin
    
    local rayParams = RaycastParams.new()
    -- Işının kendi karakterini ve kamerayı delip geçmesi sağlanır
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character, workspace.CurrentCamera}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.IgnoreWater = true
    
    local result = workspace:Raycast(origin, direction, rayParams)
    
    -- Eğer raycast hedef parçaya veya o parçanın ebeveynine (karaktere) çarparsa önü açıktır
    if result then
        return result.Instance:IsDescendantOf(character) or result.Instance == targetPart
    end
    return false
end

-- Ana Loop Döngüleri
RunService.RenderStepped:Connect(function()
    -- 1. ESP Mantığı
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

    -- 2. RGB Gun (Gökkuşağı Silah) Efekti
    if RgbGunEnabled and LocalPlayer.Character then
        local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if tool then
            for _, part in ipairs(tool:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Color = Color3.fromHSV(tick() % 5 / 5, 1, 1)
                end
            end
        end
    end

    -- 3. AimLock Mantığı
    if not AimEnabled then return end
    
    local closestPlayer = nil
    local shortestDistance = math.huge
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
            
            -- Kendi Takımına Kilitlememe
            if player.Team == LocalPlayer.Team then continue end
            
            -- Ölüleri Hedef Almama
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health <= 0 then continue end
            
            -- Duvar arkası/Görünürlük Filtrelemesi
            if VisibilityCheck and not isVisible(player.Character.Head, player.Character) then 
                continue 
            end
            
            -- Ekranda olma kontrolü ve merkeze olan mesafe
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
    
    -- Hedefe Kamerayı Sabitleme
    if closestPlayer then
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, closestPlayer.Character.Head.Position)
    end
end)

-- Spinbot için engellenme yapmayan fiziksel döngü
RunService.Stepped:Connect(function()
    if MevlanaEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local rootPart = LocalPlayer.Character.HumanoidRootPart
        -- Titremeyi önleyecek şekilde rotasyon açısı artırıldı
        rootPart.CFrame = rootPart.CFrame * CFrame.Angles(0, math.rad(60), 0)
    end
end)
