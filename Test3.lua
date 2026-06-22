-- palofsc: Roblox Arsenal için RayField tabanlı AimLock ve ESP scripti
-- Kullanım: Scripti herhangi bir executor ile çalıştırın.

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Arsenal Pro",
   LoadingTitle = "Arsenal Script Yükleniyor...",
   LoadingSubtitle = "by palofsc",
   KeySystem = false
})

local Tab = Window:CreateTab("Combat", nil)

-- AimLock Fonksiyonu
local AimEnabled = false
local AimTarget = nil

local ToggleAim = Tab:CreateToggle({
   Name = "AimLock",
   CurrentValue = false,
   Callback = function(Value)
      AimEnabled = Value
   end
})

game:GetService("RunService").RenderStepped:Connect(function()
   if AimEnabled then
      local localPlayer = game.Players.LocalPlayer
      local camera = workspace.CurrentCamera
      local closestPlayer = nil
      local shortestDistance = math.huge
      
      for _, player in pairs(game.Players:GetPlayers()) do
         if player ~= localPlayer and player.Character and player.Character:FindFirstChild("Head") then
            local pos, onScreen = camera:WorldToViewportPoint(player.Character.Head.Position)
            if onScreen then
               local distance = (Vector2.new(pos.X, pos.Y) - Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)).Magnitude
               if distance < shortestDistance then
                  shortestDistance = distance
                  closestPlayer = player
               end
            end
         end
      end
      
      if closestPlayer then
         camera.CFrame = CFrame.new(camera.CFrame.Position, closestPlayer.Character.Head.Position)
      end
   end
end)

-- ESP Fonksiyonu
local ESPEnabled = false

local ToggleESP = Tab:CreateToggle({
   Name = "ESP",
   CurrentValue = false,
   Callback = function(Value)
      ESPEnabled = Value
      for _, player in pairs(game.Players:GetPlayers()) do
         if player.Character and player.Character:FindFirstChild("Highlight") then
            player.Character.Highlight.Enabled = Value
         end
      end
   end
})

game.Players.PlayerAdded:Connect(function(player)
   player.CharacterAdded:Connect(function(char)
      local h = Instance.new("Highlight", char)
      h.Enabled = ESPEnabled
   end)
end)

