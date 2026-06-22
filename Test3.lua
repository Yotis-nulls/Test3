-- palofsc: Arsenal için düzeltilmiş takım ayrımı ve raycast görünürlük denetimi

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local AimEnabled = false

-- RaycastParams ile daha güvenilir görünürlük denetimi
local function isVisible(targetPart)
    local origin = Camera.CFrame.Position
    local direction = targetPart.Position - origin
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, workspace.CurrentCamera}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    
    local raycastResult = workspace:Raycast(origin, direction, raycastParams)
    
    if raycastResult and raycastResult.Instance then
        -- Vurulan parça hedef karakterin bir parçası mı?
        return raycastResult.Instance:IsDescendantOf(targetPart.Parent)
    end
    return false
end

-- AimLock ana döngüsü
RunService.RenderStepped:Connect(function()
    if not AimEnabled then return end
    
    local closestPlayer = nil
    local shortestDistance = math.huge
    
    for _, player in pairs(Players:GetPlayers()) do
        -- Takım kontrolü: 'Team' özelliği nil değilse ve takım ID'leri farklıysa
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
            if player.Team == LocalPlayer.Team then continue end -- Aynı takımdaysa atla
            
            local head = player.Character.Head
            
            -- Görünürlük kontrolü: Raycast kullanılıyor
            if not isVisible(head) then continue end
            
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
        -- Smoothing (akıcılık) eklenmiş hedefleme
        local targetPosition = closestPlayer.Character.Head.Position
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPosition)
    end
end)
