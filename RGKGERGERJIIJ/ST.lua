-- Chargement de la bibliothèque GUI SORONICE
local soronice = loadstring(game:HttpGet('https://raw.githubusercontent.com/soft972/librairie-SOFT-HUB/refs/heads/main/lib%20v11%20modulaire/v1.lua'))()

-- Services de base
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPack = game:GetService("StarterPack")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- ==========================================
-- SÉCURISATION DU PARENT DES INTERFACES (MOBILE COMPATIBLE)
-- ==========================================
local CoreGui = game:GetService("CoreGui")
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local function getSafeParent()
    local success, _ = pcall(function()
        local test = Instance.new("Folder")
        test.Parent = CoreGui
        test:Destroy()
    end)
    return success and CoreGui or PlayerGui
end
local SafeParent = getSafeParent()

-- ==========================================
-- SÉCURISATION DE L'API DRAWING (ANTI-CRASH EXÉCUTEURS FAIBLES)
-- ==========================================
local function safeDrawing(drawingType)
    if type(Drawing) == "table" and Drawing.new then
        local success, obj = pcall(Drawing.new, drawingType)
        if success then return obj end
    end
    local dummy = {
        Visible = false,
        Color = Color3.new(1,1,1),
        Thickness = 1,
        Transparency = 1,
        From = Vector2.new(),
        To = Vector2.new(),
        Size = Vector2.new(),
        Position = Vector2.new(),
        Filled = false,
        Center = false,
        Outline = false,
        Text = ""
    }
    function dummy:Remove() end
    function dummy:Destroy() end
    return dummy
end

-- Variables d'état
local speedMultiplierEnabled = false
local infiniteJumpEnabled = false
local silentAimEnabled = false
local fovVisible = false
local espBoxEnabled = false
local espSkeletonEnabled = false
local espLaserTargetEnabled = false
local cheaterDetectionEnabled = false
local antiFallEnabled = false
local autoBuryEnabled = false
local manualBuryEnabled = false
local manualBuryDepth = -20
local desyncEnabled = false
local antiAimEnabled = false
local isMovementPaused = false 
local markedCheaters = {}

-- Paramètres de réglage
local multiplicateurValeur = 1.4
local puissanceSaut = 40 
local fovSize = 100

-- Initialisation de la Fenêtre UI (Ordre des onglets modifié)
local Window = soronice:CreateWindow({
    Name = "SOFT-HUB",
    BrandLogo   = "99988830313432",
    ShowDevice = true,
    ShowPing = true,
    ShowFPS = true,
    VersionTag = "V1",
    KeySystem = false,
    KeySettings = { Title = "ACCES PREMIUM", LinkText = "Copier", Key = "1234", GrabKeyFromSite = false, Link = "" }
})
local MainTab = Window:CreateTab("Main", 79047049601630) 
local Tab = Window:CreateTab("Mouvement") -- Mouvement passe devant
local joueurTab = Window:CreateTab("Joueur", 74615953378946) -- Joueur passe derrière mouvement
local VisionTab = Window:CreateTab("Vision FPS", 137310194899135)
local ServeurTab = Window:CreateTab("Serveur", 137633026925616) 

-- ==========================================
-- 1. VISUELS : CERCLE DE VISÉE
-- ==========================================
local CrosshairGui = Instance.new("ScreenGui")
CrosshairGui.Name = "FOVCircle_Jaune"
CrosshairGui.ResetOnSpawn = false 
CrosshairGui.Parent = SafeParent

local Circle = Instance.new("Frame", CrosshairGui)
Circle.Name = "Ring"
Circle.AnchorPoint = Vector2.new(0.5, 0.5)
Circle.Position = UDim2.new(0.5, 0, 0.5, 0)
Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
Circle.BackgroundTransparency = 1 
Circle.Visible = false

local Stroke = Instance.new("UIStroke", Circle)
Stroke.Color = Color3.fromRGB(255, 255, 0)
Stroke.Thickness = 2.5
Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local Corner = Instance.new("UICorner", Circle)
Corner.CornerRadius = UDim.new(1, 0)

RunService.RenderStepped:Connect(function()
    Circle.Visible = fovVisible
    Circle.Size = UDim2.new(0, fovSize * 2, 0, fovSize * 2)
end)

-- ==========================================
-- 2. DÉTECTION CIBLE (CERCLE JAUNE)
-- ==========================================
local function getTargetInsideFOV()
    local target = nil
    local shortestDistance = fovSize
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local targetPart = player.Character:FindFirstChild("UpperTorso") or player.Character:FindFirstChild("Torso") or player.Character:FindFirstChild("HumanoidRootPart")
                
                if targetPart then
                    local pos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                    
                    -- Sécurité anti-ghosting également intégrée à la détection de cible
                    if onScreen and pos.Z > 0 then
                        local screenPos = Vector2.new(pos.X, pos.Y)
                        local distance = (screenPos - center).Magnitude
                        
                        if distance <= fovSize and distance < shortestDistance then
                            target = targetPart
                            shortestDistance = distance
                        end
                    end
                end
            end
        end
    end
    return target
end

local CurrentSilentAimTarget = nil
RunService.RenderStepped:Connect(function()
    if silentAimEnabled or espLaserTargetEnabled then
        CurrentSilentAimTarget = getTargetInsideFOV()
    else
        CurrentSilentAimTarget = nil
    end
end)

-- ==========================================
-- 3. INTERCEPTION & BYPASS WALLBANG / DISTANCE TOTAL
-- ==========================================
local safe_newcclosure = newcclosure or function(f) return f end

pcall(function()
    if type(hookmetamethod) == "function" and type(getrawmetatable) == "function" then
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", safe_newcclosure(function(self, ...)
            local method = getnamecallmethod()
            local args = {...}

            if not checkcaller() then
                if method == "FireServer" or method == "InvokeServer" then
                    if tostring(self) == "Send" then
                        if type(args[2]) == "string" and args[2] == "melee_attack" then
                            if type(args[1]) == "number" then lastCombatKey = args[1] end
                            if silentAimEnabled and CurrentSilentAimTarget then
                                if type(args[4]) == "table" then args[4] = {CurrentSilentAimTarget.Parent} end
                                if typeof(args[5]) == "CFrame" then
                                    args[5] = CFrame.new(CurrentSilentAimTarget.Position + Vector3.new(0, 1, 0), CurrentSilentAimTarget.Position)
                                end
                            end
                        end
                    end
                    
                    if silentAimEnabled and CurrentSilentAimTarget then
                        if tostring(self) ~= "MousePosUpdate" and tostring(self) ~= "UpdateMouse" and tostring(self) ~= "Send" then
                            local a_ete_modifie = false
                            for i, v in pairs(args) do
                                if typeof(v) == "Vector3" then
                                    args[i] = CurrentSilentAimTarget.Position
                                    a_ete_modifie = true
                                elseif typeof(v) == "CFrame" then
                                    args[i] = CFrame.new(CurrentSilentAimTarget.Position + Vector3.new(0, 1, 0), CurrentSilentAimTarget.Position)
                                    a_ete_modifie = true
                                end
                            end
                            if a_ete_modifie then return oldNamecall(self, unpack(args)) end
                        end
                    end
                -- TÉLÉPORTATION DES RAYONS DIRECTEMENT SUR LA CIBLE (TRAVERSE TOUS LES MURS)
                elseif method == "Raycast" and silentAimEnabled and CurrentSilentAimTarget then
                    args[1] = CurrentSilentAimTarget.Position + Vector3.new(0, 1, 0) -- Origine juste au dessus de lui
                    args[2] = Vector3.new(0, -2, 0) -- Direction descendante directe dans son corps
                    return oldNamecall(self, unpack(args))
                elseif (method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRay") and silentAimEnabled and CurrentSilentAimTarget then
                    args[1] = Ray.new(CurrentSilentAimTarget.Position + Vector3.new(0, 1, 0), Vector3.new(0, -2, 0))
                    return oldNamecall(self, unpack(args))
                end
            end
            return oldNamecall(self, ...)
        end))

        local oldIndex
        oldIndex = hookmetamethod(game, "__index", safe_newcclosure(function(self, index)
            if silentAimEnabled and CurrentSilentAimTarget and not checkcaller() then
                if self == Mouse then
                    if index == "Hit" or index == "hit" then return CurrentSilentAimTarget.CFrame
                    elseif index == "Target" or index == "target" then return CurrentSilentAimTarget end
                end
            end
            return oldIndex(self, index)
        end))
    end
end)

-- ==========================================
-- 4. MÉCANIQUE SPOOFING (ANTI-MORT, DESYNC & ANTI-AIM)
-- ==========================================
local isBuried = false
local savedSurfacePosition = nil
local targetUndergroundCFrame = nil

RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end

    -- LOGIQUE ANTI-MORT
    if autoBuryEnabled and hum.Health > 0 then
        if hum.Health <= (hum.MaxHealth * 0.30) then
            if not isBuried then
                isBuried = true
                savedSurfacePosition = hrp.CFrame
                targetUndergroundCFrame = CFrame.new(savedSurfacePosition.X, savedSurfacePosition.Y - 100, savedSurfacePosition.Z)
            end
            
            pcall(function()
                local realLocalCFrame = hrp.CFrame
                hrp.CFrame = targetUndergroundCFrame
                hrp.Velocity = Vector3.new(0, 0, 0)
                RunService.RenderStepped:Wait()
                hrp.CFrame = CFrame.new(realLocalCFrame.X, targetUndergroundCFrame.Y, realLocalCFrame.Z)
            end)
        else
            if isBuried then
                isBuried = false
                if savedSurfacePosition then hrp.CFrame = savedSurfacePosition end
            end
        end
    else
        if isBuried then
            isBuried = false
            if savedSurfacePosition then hrp.CFrame = savedSurfacePosition end
        end
    end

    isMovementPaused = isBuried

    -- DESYNC / FAKE LAG
    if desyncEnabled and not isMovementPaused then
        pcall(function()
            local oldVelocity = hrp.Velocity
            hrp.Velocity = Vector3.new(math.random(-1000, 1000), math.random(-1000, 1000), math.random(-1000, 1000))
            RunService.RenderStepped:Wait()
            hrp.Velocity = oldVelocity
        end)
    end

    -- LOGIQUE ANTI-AIM (MICRO-ESQUIVE NERVEUSE)
    if antiAimEnabled and not isMovementPaused and hum.Health > 0 then
        pcall(function()
            hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(math.random(-25, 25)), 0)
        end)
    end
end)

-- ==========================================
-- 4.5 GUI ET LOGIQUE DE LA CAMÉRA LIBRE (FREECAM)
-- ==========================================
local FreecamGui = Instance.new("ScreenGui")
FreecamGui.Name = "SORONICE_FreecamUI"
FreecamGui.ResetOnSpawn = false
FreecamGui.Enabled = false
FreecamGui.Parent = SafeParent

local FCFrame = Instance.new("Frame")
FCFrame.Size = UDim2.new(0, 200, 0, 45)
FCFrame.Position = UDim2.new(0.5, -100, 0, 20)
FCFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
FCFrame.Parent = FreecamGui

local FCCorner = Instance.new("UICorner")
FCCorner.CornerRadius = UDim.new(0, 6)
FCCorner.Parent = FCFrame

local FCStroke = Instance.new("UIStroke")
FCStroke.Color = Color3.fromRGB(255, 255, 255)
FCStroke.Thickness = 1.5
FCStroke.Parent = FCFrame

local FCBtn = Instance.new("TextButton")
FCBtn.Size = UDim2.new(1, 0, 1, 0)
FCBtn.BackgroundTransparency = 1
FCBtn.Text = "Caméra Libre: OFF"
FCBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
FCBtn.Font = Enum.Font.GothamBold
FCBtn.TextSize = 16
FCBtn.Parent = FCFrame

local freecamActive = false
local camSpeed = 2
local pitch, yaw = 0, 0
local moveKeys = {W = 0, A = 0, S = 0, D = 0, E = 0, Q = 0}
local isRightClicking = false

local function toggleFreecam(state)
    freecamActive = state
    if freecamActive then
        FCBtn.Text = "Caméra Libre: ON"
        FCBtn.TextColor3 = Color3.fromRGB(50, 255, 50)
        Camera.CameraType = Enum.CameraType.Scriptable
        local rX, rY, rZ = Camera.CFrame:ToEulerAnglesYXZ()
        pitch, yaw = rX, rY
    else
        FCBtn.Text = "Caméra Libre: OFF"
        FCBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
        Camera.CameraType = Enum.CameraType.Custom
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            Camera.CameraSubject = LocalPlayer.Character.Humanoid
        end
    end
end

FCBtn.MouseButton1Click:Connect(function() toggleFreecam(not freecamActive) end)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp and not freecamActive then return end
    if input.KeyCode == Enum.KeyCode.W then moveKeys.W = 1
    elseif input.KeyCode == Enum.KeyCode.S then moveKeys.S = 1
    elseif input.KeyCode == Enum.KeyCode.A then moveKeys.A = 1
    elseif input.KeyCode == Enum.KeyCode.D then moveKeys.D = 1
    elseif input.KeyCode == Enum.KeyCode.E then moveKeys.E = 1
    elseif input.KeyCode == Enum.KeyCode.Q then moveKeys.Q = 1
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then isRightClicking = true
    end
end)

UserInputService.InputEnded:Connect(function(input, gp)
    if input.KeyCode == Enum.KeyCode.W then moveKeys.W = 0
    elseif input.KeyCode == Enum.KeyCode.S then moveKeys.S = 0
    elseif input.KeyCode == Enum.KeyCode.A then moveKeys.A = 0
    elseif input.KeyCode == Enum.KeyCode.D then moveKeys.D = 0
    elseif input.KeyCode == Enum.KeyCode.E then moveKeys.E = 0
    elseif input.KeyCode == Enum.KeyCode.Q then moveKeys.Q = 0
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then isRightClicking = false
    end
end)

UserInputService.InputChanged:Connect(function(input, gp)
    if freecamActive then
        if input.UserInputType == Enum.UserInputType.MouseWheel then
            camSpeed = math.clamp(camSpeed + (input.Position.Z * 2), 0.5, 60)
        elseif input.UserInputType == Enum.UserInputType.MouseMovement and isRightClicking then
            local delta = input.Delta
            yaw = yaw - delta.X * 0.005
            pitch = math.clamp(pitch - delta.Y * 0.005, -math.rad(89), math.rad(89))
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if freecamActive then
        UserInputService.MouseBehavior = isRightClicking and Enum.MouseBehavior.LockCurrentPosition or Enum.MouseBehavior.Default
        local cf = CFrame.new(Camera.CFrame.Position) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0)
        local direction = Vector3.new(moveKeys.D - moveKeys.A, moveKeys.E - moveKeys.Q, moveKeys.S - moveKeys.W)
        Camera.CFrame = cf + (cf:vectorToWorldSpace(direction) * camSpeed)
    end
end)

-- ==========================================
-- 5. MOUVEMENT (VITESSE & SAUT RAFALE MULTIPLIÉ)
-- ==========================================
RunService.Stepped:Connect(function()
    if speedMultiplierEnabled and not isMovementPaused then
        pcall(function()
            local character = LocalPlayer.Character
            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                local rootPart = character:FindFirstChild("HumanoidRootPart")
                if humanoid and rootPart and humanoid.MoveDirection.Magnitude > 0 then
                    local force = multiplicateurValeur * 1.5
                    rootPart.CFrame = rootPart.CFrame + (humanoid.MoveDirection * (force / 10))
                end
            end
        end)
    end
end)

-- INFINITE JUMP RAFALE CONSERVÉ DANS RENDERSTEPPED
RunService.RenderStepped:Connect(function()
    if infiniteJumpEnabled and not isMovementPaused then
        pcall(function()
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hum and hrp then
                    local isHoldingJump = UserInputService:IsKeyDown(Enum.KeyCode.Space) or hum.Jump
                    if isHoldingJump then
                        -- Applique une série d'états rapides pour simuler la rafale "4x4"
                        hum:ChangeState(Enum.HumanoidStateType.Jumping)
                        hrp.AssemblyLinearVelocity = Vector3.new(
                            hrp.AssemblyLinearVelocity.X, 
                            puissanceSaut * 1.3, -- Boost léger de vélocité instantanée
                            hrp.AssemblyLinearVelocity.Z
                        )
                    end
                end
            end
        end)
    end
end)

-- SOUTERRAIN MANUEL
local savedManualSurfaceY = nil
RunService.RenderStepped:Connect(function()
    if manualBuryEnabled and not isMovementPaused then
        pcall(function()
            local hrp = LocalPlayer.Character.HumanoidRootPart
            if not savedManualSurfaceY then 
                savedManualSurfaceY = hrp.Position.Y 
            end
            
            hrp.CFrame = CFrame.new(hrp.Position.X, savedManualSurfaceY + manualBuryDepth, hrp.Position.Z) * CFrame.Angles(0, math.rad(hrp.Orientation.Y), 0)
            hrp.Velocity = Vector3.new(hrp.Velocity.X, 0, hrp.Velocity.Z)
        end)
    else
        if savedManualSurfaceY then
            pcall(function() 
                local hrp = LocalPlayer.Character.HumanoidRootPart
                hrp.CFrame = CFrame.new(hrp.Position.X, savedManualSurfaceY, hrp.Position.Z) * CFrame.Angles(0, math.rad(hrp.Orientation.Y), 0)
            end)
            savedManualSurfaceY = nil
        end
    end
end)

-- ==========================================
-- 6. ANTI-CHUTE (STABILISATEUR)
-- ==========================================
RunService.Heartbeat:Connect(function()
    if antiFallEnabled and not isMovementPaused then
        pcall(function()
            local char = LocalPlayer.Character
            local hum = char:FindFirstChildOfClass("Humanoid")
            local hrp = char:FindFirstChild("HumanoidRootPart")
            
            if hum and hrp and not hum.Sit then
                hrp.RotVelocity = Vector3.new(0, hrp.RotVelocity.Y, 0)
                hrp.CFrame = CFrame.new(hrp.CFrame.Position) * CFrame.Angles(0, math.rad(hrp.Orientation.Y), 0)
                
                hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
                if hum:GetState() == Enum.HumanoidStateType.FallingDown or hum:GetState() == Enum.HumanoidStateType.Ragdoll then
                    hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                end
            end
        end)
    end
end)

-- ==========================================
-- 7. ESP AVANCÉ (VOTRE VERSION INITIALE 100% SÉCURISÉE)
-- ==========================================
local function getToolTexture(tool)
    if not tool then return "rbxassetid://4483345998" end
    if typeof(tool.TextureId) == "string" and tool.TextureId ~= "" then return tool.TextureId end
    if tool:GetAttribute("ImageId") then return tool:GetAttribute("ImageId") end
    
    local handle = tool:FindFirstChild("Handle")
    if handle then
        if handle:IsA("MeshPart") and handle.TextureID ~= "" then return handle.TextureID end
        local decal = handle:FindFirstChildOfClass("Decal")
        if decal and decal.Texture ~= "" then return decal.Texture end
        local mesh = handle:FindFirstChildOfClass("SpecialMesh")
        if mesh and mesh.TextureId ~= "" then return mesh.TextureId end
    end
    return "rbxassetid://4483345998"
end

local toolCache = setmetatable({}, {__mode = "k"})

local function matchToolName(tool)
    if not tool then return "Unknown", getToolTexture(nil) end
    if toolCache[tool] then return toolCache[tool].name, toolCache[tool].texture end

    local nameLower = tool.Name:lower()
    if nameLower == "combat" or nameLower == "fists" or nameLower == "fist" then
        local tex = getToolTexture(tool)
        toolCache[tool] = {name = "FISTS", texture = tex}
        return "FISTS", tex
    end

    local realName = tool.Name
    if tool:FindFirstChild("ToolTip") and tool.ToolTip.Value ~= "" then
        realName = tool.ToolTip.Value
    end

    local handle = tool:FindFirstChild("Handle")
    local uniqueMeshId = nil

    if handle then
        if handle:IsA("MeshPart") then
            uniqueMeshId = handle.MeshId
        else
            local mesh = handle:FindFirstChildOfClass("SpecialMesh")
            if mesh then uniqueMeshId = mesh.MeshId end
        end
    end

    if uniqueMeshId and uniqueMeshId ~= "" then
        for _, source in ipairs({ReplicatedStorage:FindFirstChild("Items"), StarterPack}) do
            if source then
                for _, item in ipairs(source:GetDescendants()) do
                    if item:IsA("Tool") and item ~= tool then
                        local iHandle = item:FindFirstChild("Handle")
                        if iHandle then
                            local iMeshId = nil
                            if iHandle:IsA("MeshPart") then iMeshId = iHandle.MeshId
                            else
                                local iMesh = iHandle:FindFirstChildOfClass("SpecialMesh")
                                if iMesh then iMeshId = iMesh.MeshId end
                            end
                            
                            if iMeshId == uniqueMeshId then
                                local matchedName = item.Name
                                local matchedTex = getToolTexture(item)
                                toolCache[tool] = {name = matchedName, texture = matchedTex}
                                return matchedName, matchedTex 
                            end
                        end
                    end
                end
            end
        end
    end
    
    local fallbackTex = getToolTexture(tool)
    toolCache[tool] = {name = realName, texture = fallbackTex}
    return realName, fallbackTex
end

local function getToolRarityColor(toolName)
    local name = tostring(toolName):lower()
    if name == "p226" or name == "clè" or name == "lame de commutation" or name == "balai en diamant" then
        return Color3.fromRGB(0, 170, 255) 
    elseif name == "g3" or name == "marteau" then
        return Color3.fromRGB(0, 255, 0) 
    elseif name == "fists" then
        return Color3.fromRGB(150, 150, 150) 
    end
    return Color3.fromRGB(150, 150, 150)
end

local espObjects = {}
local targetLaser = safeDrawing("Line")
targetLaser.Visible = false; targetLaser.Color = Color3.fromRGB(255, 0, 0); targetLaser.Thickness = 2; targetLaser.Transparency = 1

local bones = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"}, {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}
}
local bonesR6 = {{"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"}, {"Torso", "Left Leg"}, {"Torso", "Right Leg"}}

local EspImageGui = Instance.new("ScreenGui")
EspImageGui.Name = "ESP_ToolImages"
EspImageGui.ResetOnSpawn = false
EspImageGui.Parent = SafeParent

local function CreateESP(player)
    local box = safeDrawing("Square")
    box.Visible = false; box.Color = Color3.fromRGB(255, 255, 255); box.Thickness = 1; box.Filled = false
    
    local info = safeDrawing("Text")
    info.Visible = false; info.Color = Color3.new(1, 1, 1); info.Size = 14; info.Outline = true; info.Center = true

    local cheaterLabel = safeDrawing("Text")
    cheaterLabel.Visible = false; cheaterLabel.Color = Color3.fromRGB(0, 170, 255); cheaterLabel.Size = 14; cheaterLabel.Outline = true; cheaterLabel.Center = true

    local skeletonLines = {}
    for i = 1, 15 do
        local line = safeDrawing("Line")
        line.Visible = false; line.Thickness = 1
        table.insert(skeletonLines, line)
    end

    local toolContainer = Instance.new("Frame")
    toolContainer.BackgroundTransparency = 1
    toolContainer.Size = UDim2.new(0, 160, 0, 50)
    toolContainer.AnchorPoint = Vector2.new(0.5, 1)
    toolContainer.Visible = false
    toolContainer.Parent = EspImageGui

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.Padding = UDim.new(0, 5)
    layout.Parent = toolContainer

    local toolSlots = {}
    for i = 1, 4 do
        local slot = Instance.new("Frame")
        slot.BackgroundTransparency = 1
        slot.Size = UDim2.new(0, 35, 0, 50)
        slot.Visible = false
        slot.Parent = toolContainer
        
        local img = Instance.new("ImageLabel")
        img.Size = UDim2.new(0, 35, 0, 35)
        img.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        img.BackgroundTransparency = 0.3
        img.ScaleType = Enum.ScaleType.Crop
        img.Parent = slot
        
        Instance.new("UICorner", img).CornerRadius = UDim.new(1, 0)
        local stroke = Instance.new("UIStroke", img)
        stroke.Thickness = 1.5
        
        local txt = Instance.new("TextLabel")
        txt.Size = UDim2.new(1, 0, 0, 15)
        txt.Position = UDim2.new(0, 0, 0, 35)
        txt.BackgroundTransparency = 1
        txt.TextColor3 = Color3.fromRGB(255, 255, 255)
        txt.TextSize = 10
        txt.TextStrokeTransparency = 1
        txt.Font = Enum.Font.GothamBold
        txt.Parent = slot
        
        table.insert(toolSlots, {slot = slot, img = img, txt = txt, stroke = stroke})
    end

    espObjects[player] = {box = box, info = info, cheaterLabel = cheaterLabel, skeleton = skeletonLines, toolContainer = toolContainer, toolSlots = toolSlots}

    connection = RunService.RenderStepped:Connect(function()
        if not player.Parent then
            box:Remove(); info:Remove(); cheaterLabel:Remove()
            for _, line in pairs(skeletonLines) do line:Remove() end
            toolContainer:Destroy()
            connection:Disconnect()
            espObjects[player] = nil
            return
        end

        local isTargeted = (CurrentSilentAimTarget and player.Character and CurrentSilentAimTarget:IsDescendantOf(player.Character))
        local activeColor = (espLaserTargetEnabled and isTargeted) and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(255, 255, 255)

        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player ~= LocalPlayer then
            local char = player.Character
            local root = char.HumanoidRootPart
            local humanoid = char:FindFirstChild("Humanoid")
            local pos, screen = Camera:WorldToViewportPoint(root.Position)
            
            if cheaterDetectionEnabled and humanoid and not humanoid.Sit then
                local hrpVel = root.Velocity
                local horizontalSpeed = Vector3.new(hrpVel.X, 0, hrpVel.Z).Magnitude
                local verticalSpeed = hrpVel.Y
                
                if horizontalSpeed > 24 or verticalSpeed > 50 then 
                    markedCheaters[player] = true
                end
            end

            -- L'ESP d'origine s'affiche uniquement si l'ennemi est DEVANT (pos.Z > 0) pour empêcher l'affichage inversé
            if espBoxEnabled and screen and pos.Z > 0 then
                box.Visible = true; box.Color = activeColor
                box.Size = Vector2.new(2000 / pos.Z, 3000 / pos.Z)
                box.Position = Vector2.new(pos.X - box.Size.X / 2, pos.Y - box.Size.Y / 2)
                
                info.Visible = true; info.Color = activeColor
                info.Text = player.Name
                info.Position = Vector2.new(pos.X, box.Position.Y - 25)

                if cheaterDetectionEnabled and markedCheaters[player] then
                    cheaterLabel.Visible = true
                    cheaterLabel.Text = "[HACKÉ]"
                    cheaterLabel.Position = Vector2.new(pos.X, info.Position.Y - 16)
                else
                    cheaterLabel.Visible = false
                end

                local toolsData = {}
                for _, v in ipairs(char:GetChildren()) do
                    if (v:IsA("Tool") or v:IsA("HopperBin")) and #toolsData < 4 then table.insert(toolsData, v) end
                end
                local backpack = player:FindFirstChild("Backpack")
                if backpack then
                    for _, v in ipairs(backpack:GetChildren()) do
                        if (v:IsA("Tool") or v:IsA("HopperBin")) and #toolsData < 4 then table.insert(toolsData, v) end
                    end
                end

                if #toolsData > 0 then
                    toolContainer.Visible = true
                    toolContainer.Position = UDim2.new(0, pos.X, 0, box.Position.Y + box.Size.Y + 5)
                    
                    for i = 1, 4 do
                        local tool = toolsData[i]
                        local slotData = toolSlots[i]
                        if tool then
                            slotData.slot.Visible = true
                            
                            local realName, realTexture = matchToolName(tool)
                            
                            if string.match(realName, "^%d+$") then
                                if tool:FindFirstChild("ToolTip") and tool.ToolTip.Value ~= "" and not string.match(tool.ToolTip.Value, "^%d+$") then
                                    realName = tool.ToolTip.Value
                                else
                                    realName = tool.Name
                                end
                            end
                            
                            slotData.txt.Text = realName
                            slotData.stroke.Color = getToolRarityColor(realName)
                            
                            if realTexture and realTexture ~= "" then
                                if string.match(realTexture, "^%d+$") then
                                    slotData.img.Image = "rbxassetid://" .. realTexture
                                else
                                    slotData.img.Image = realTexture
                                end
                            else
                                slotData.img.Image = "rbxassetid://4483345998"
                            end
                        else
                            slotData.slot.Visible = false
                        end
                    end
                else
                    toolContainer.Visible = false
                end
            else
                box.Visible = false; info.Visible = false; toolContainer.Visible = false; cheaterLabel.Visible = false
            end

            if espSkeletonEnabled and screen and pos.Z > 0 then
                local isR15 = char:FindFirstChild("UpperTorso") ~= nil
                local currentBones = isR15 and bones or bonesR6

                for i, bone in ipairs(currentBones) do
                    local part1 = char:FindFirstChild(bone[1]); local part2 = char:FindFirstChild(bone[2])
                    if part1 and part2 then
                        local p1, onScreen1 = Camera:WorldToViewportPoint(part1.Position)
                        local p2, onScreen2 = Camera:WorldToViewportPoint(part2.Position)
                        if onScreen1 and onScreen2 and p1.Z > 0 and p2.Z > 0 then
                            skeletonLines[i].Visible = true; skeletonLines[i].Color = activeColor
                            skeletonLines[i].From = Vector2.new(p1.X, p1.Y); skeletonLines[i].To = Vector2.new(p2.X, p2.Y)
                        else
                            skeletonLines[i].Visible = false
                        end
                    else
                        skeletonLines[i].Visible = false
                    end
                end
            else
                for _, line in pairs(skeletonLines) do line.Visible = false end
            end
        else
            box.Visible = false; info.Visible = false; toolContainer.Visible = false; cheaterLabel.Visible = false
            for _, line in pairs(skeletonLines) do line.Visible = false end
        end
    end)
end

for _, p in pairs(Players:GetPlayers()) do CreateESP(p) end
Players.PlayerAdded:Connect(CreateESP)

RunService.RenderStepped:Connect(function()
    if espLaserTargetEnabled and CurrentSilentAimTarget then
        local pos, onScreen = Camera:WorldToViewportPoint(CurrentSilentAimTarget.Position)
        if onScreen and pos.Z > 0 then
            targetLaser.Visible = true
            targetLaser.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            targetLaser.To = Vector2.new(pos.X, pos.Y)
        else
            targetLaser.Visible = false
        end
    else
        targetLaser.Visible = false
    end
end)

-- ==========================================
-- 8. INTERFACE GUI
-- ==========================================

-- --- ONGLET 1 : MOUVEMENT & TIR ---
Tab:CreateToggle({
    Name = "Activer le mode tir au balle (Silent Aim)", 
    CurrentValue = false, 
    Callback = function(v) 
        fovVisible = v 
        silentAimEnabled = v 
    end
})
Tab:CreateSlider({
    Name = "Taille du Cercle Jaune (FOV)", 
    Range = {50, 800}, 
    Increment = 5, 
    CurrentValue = 100, 
    Callback = function(v) fovSize = v end
})
Tab:CreateToggle({Name = "Saut Infini (Ultra-Rapide)", CurrentValue = false, Callback = function(v) infiniteJumpEnabled = v end})
Tab:CreateSlider({Name = "Hauteur du Saut", Range = {10, 150}, CurrentValue = 40, Callback = function(v) puissanceSaut = v end})
Tab:CreateToggle({Name = "Vitesse Multipliée", CurrentValue = false, Callback = function(v) speedMultiplierEnabled = v end})
Tab:CreateToggle({Name = "Anti-Chute (Stabilisateur)", CurrentValue = false, Callback = function(v) antiFallEnabled = v end})


-- --- ONGLET 2 : JOUEUR & ANTIS ---
joueurTab:CreateToggle({
    Name = "Anti-Aim (Micro-Esquive Jitter)",
    CurrentValue = false,
    Callback = function(v) antiAimEnabled = v end
})
joueurTab:CreateToggle({
    Name = "Anti-Mort Auto (Spam Souterrain <30%)",
    CurrentValue = false,
    Callback = function(v) autoBuryEnabled = v end
})
joueurTab:CreateToggle({
    Name = "Desync (Fake Lag Carcasse)",
    CurrentValue = false,
    Callback = function(v) desyncEnabled = v end
})
joueurTab:CreateToggle({
    Name = "Souterrain MANUEL (Pour récupérer Stuff)",
    CurrentValue = false,
    Callback = function(v) manualBuryEnabled = v end
})
joueurTab:CreateSlider({
    Name = "Régler Hauteur/Profondeur",
    Range = {-500, 500},
    Increment = 5,
    CurrentValue = -20,
    Callback = function(v) manualBuryDepth = v end
})


-- --- LES AUTRES ONGLETS ---
VisionTab:CreateToggle({Name = "Voir Joueurs (ESP Box & Image Tool)", CurrentValue = false, Callback = function(v) espBoxEnabled = v end})
VisionTab:CreateToggle({Name = "ESP Squelette", CurrentValue = false, Callback = function(v) espSkeletonEnabled = v end})
VisionTab:CreateToggle({Name = "Laser & Cible Rouge (Verrouillage)", CurrentValue = false, Callback = function(v) espLaserTargetEnabled = v end})
VisionTab:CreateToggle({Name = "Détecteur de Cheaters [HACKÉ]", CurrentValue = false, Callback = function(v) cheaterDetectionEnabled = v end})

-- ==========================================
-- 9. Main 
-- ==========================================
local MyParagraph = MainTab:CreateParagraph({
    Title = "À propos",
    Content = "Ce script est réservé aux membres premium. Toute redistribution est interdite."
})

local Copy = MainTab:CreateButton({
    Name = "Copy server discord",
    Callback = function()
        local texteACopier = "https://discord.gg/mcFW7arAf"
        if setclipboard then
            setclipboard(texteACopier)
        elseif toclipboard then
            toclipboard(texteACopier)
        end
        
        soronice:Notify({
           Title = "You copied the link discord",
           Content = "✅You have successfully copied📄 the link Discord.",
           Duration = 6,
           Image = 138160382408834,
        })
    end,
})

soronice:Notify({
   Title = "BlockSpin🔪",
   Content = "Welcome to SORONICE HUB",
   Duration = 5,
   Image = 71401779636326,
})
