--[[
    ========================================================================
    SYSTÈME DE BAN CINÉMATIQUE & ULTRA-SPECTACULAIRE (30 SECONDES)
    ========================================================================
    Version optimisée pour EXÉCUTEURS (Anti-Error & Mouvement Bloqué)
    ========================================================================
]]

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")

-- Détection ultra-sécurisée du LocalPlayer (Évite l'erreur 'nil with Character')
local player = Players.LocalPlayer
while not player do
    task.wait(0.1)
    player = Players.LocalPlayer
end

local playerGui = player:WaitForChild("PlayerGui", 10)
local camera = workspace.CurrentCamera

-- ==================== CONFIGURATION DU BAN ====================
local PLATFORM_NAME = "SOFTಸ್ HUB"      -- Le nom de ta plateforme
local BANNER_NAME = "SOFTಸ್"      -- Le nom du modérateur qui applique le ban

-- Ressources audio
local AMBIENT_MUSIC_ID = "rbxassetid://1836294362"        -- Musique permanente sombre
local LIGHTNING_SOUND_ID = "rbxassetid://124432034597461"   -- Son d'éclair
local IMPACT_SOUND_ID = "rbxassetid://128356543877971"      -- Son de l'impact majeur
-- ==============================================================

-- ==================== BLOCAGE TOTAL DU JOUEUR ====================
-- Cette boucle tourne en tâche de fond pour s'assurer que le joueur reste figé
local blockThread = task.spawn(function()
    while true do
        local char = player.Character
        if char then
            -- 1. Ancrage de la pièce maîtresse
            local root = char:FindFirstChild("HumanoidRootPart")
            if root and not root.Anchored then
                root.Anchored = true
            end
            -- 2. Désactivation des contrôles physiques de marche/saut
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.WalkSpeed = 0
                hum.JumpPower = 0
            end
        end
        task.wait(0.1) -- Vérification constante
    end
end)

-- ======= COUPE AUTOMATIQUE DE TOUS LES AUTRES SONS DU JEU =======
local function muteAllGameSounds()
    for _, descendant in ipairs(game:GetDescendants()) do
        if descendant:IsA("Sound") then
            descendant.Volume = 0
        end
    end
    
    game.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("Sound") and not descendant:IsDescendantOf(playerGui) then
            descendant.Volume = 0
        end
    end)
end

muteAllGameSounds()

-- ============ CRÉATION DE L'INTERFACE DE BAN ============
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CinematicBanGui"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 999999
screenGui.Parent = playerGui

local MARGIN = 50
local MAX_SHAKE = 20

local rootBasePos = UDim2.new(0, -MARGIN, 0, -MARGIN)
local rootLayer = Instance.new("Frame")
rootLayer.Name = "RootLayer"
rootLayer.Size = UDim2.new(1, MARGIN * 2, 1, MARGIN * 2)
rootLayer.Position = rootBasePos
rootLayer.BackgroundTransparency = 1
rootLayer.Parent = screenGui

local background = Instance.new("Frame")
background.Size = UDim2.new(1, 0, 1, 0)
background.BackgroundColor3 = Color3.fromRGB(6, 3, 5) 
background.BorderSizePixel = 0
background.ZIndex = 1
background.Parent = rootLayer

local vignette = Instance.new("Frame")
vignette.Size = UDim2.new(1, 0, 1, 0)
vignette.BackgroundColor3 = Color3.fromRGB(110, 12, 20)
vignette.BackgroundTransparency = 0.6
vignette.BorderSizePixel = 0
vignette.ZIndex = 1
vignette.Parent = background

local vignetteGradient = Instance.new("UIGradient")
vignetteGradient.Rotation = 90
vignetteGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.9),
    NumberSequenceKeypoint.new(0.5, 0.1),
    NumberSequenceKeypoint.new(1, 0.9),
})
vignetteGradient.Parent = vignette

local particleFolder = Instance.new("Folder")
particleFolder.Parent = rootLayer

local crackFolder = Instance.new("Folder")
crackFolder.Parent = rootLayer

-- ============ MUSIQUE & EFFETS SONORES DU SCRIPT ============
local bgMusic = Instance.new("Sound")
bgMusic.Name = "BanAmbientMusic"
bgMusic.SoundId = AMBIENT_MUSIC_ID
bgMusic.Volume = 0
bgMusic.Looped = true
bgMusic.Parent = rootLayer
bgMusic:Play()
TweenService:Create(bgMusic, TweenInfo.new(1.5, Enum.EasingStyle.Linear), { Volume = 0.8 }):Play()

local function playOneShot(soundId, volume)
    if not soundId or soundId == "rbxassetid://0" then return end
    local s = Instance.new("Sound")
    s.SoundId = soundId
    s.Volume = volume
    s.Parent = rootLayer
    s:Play()
    s.Ended:Connect(function() s:Destroy() end)
    task.delay(5, function() if s and s.Parent then s:Destroy() end end)
end

-- ============ TREMBLEMENT DE CAMÉRA (SHAKE) ============
local shakeIntensity = 0
local shakeLoopRunning = false

local function addShake(amount)
    shakeIntensity = math.min(shakeIntensity + amount, MAX_SHAKE)
    if not shakeLoopRunning then
        shakeLoopRunning = true
        task.spawn(function()
            while shakeIntensity > 0.4 do
                local dx = math.random(-shakeIntensity, shakeIntensity)
                local dy = math.random(-shakeIntensity, shakeIntensity)
                rootLayer.Position = UDim2.new(0, -MARGIN + dx, 0, -MARGIN + dy)
                shakeIntensity = shakeIntensity * 0.85
                task.wait(0.03)
            end
            shakeIntensity = 0
            rootLayer.Position = rootBasePos
            shakeLoopRunning = false
        end)
    end
end

-- ============ CRÉATION DES ÉCLAIRS ZIGZAGS ============
local function toPixel(scaleX, scaleY)
    local size = camera.ViewportSize
    return Vector2.new(scaleX * size.X, scaleY * size.Y)
end

local function createBoltSegment(p1, p2, thickness, color, transparency, zIndexVal, parent)
    local delta = p2 - p1
    local length = delta.Magnitude
    local angle = math.deg(math.atan2(delta.Y, delta.X))

    local seg = Instance.new("Frame")
    seg.AnchorPoint = Vector2.new(0, 0.5)
    seg.Position = UDim2.new(0, p1.X, 0, p1.Y)
    seg.Size = UDim2.new(0, length, 0, thickness)
    seg.Rotation = angle
    seg.BackgroundColor3 = color
    seg.BackgroundTransparency = transparency
    seg.BorderSizePixel = 0
    seg.ZIndex = zIndexVal
    seg.Parent = parent
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = seg
    return seg
end

local function spawnLightningBolt()
    local startScale = Vector2.new(math.random(10, 90) / 100, math.random(10, 90) / 100)
    local dirAngle = math.rad(math.random(0, 360))
    local totalLength = math.random(250, 500)
    local segmentCount = math.random(6, 10)

    local bolt = Instance.new("Folder")
    bolt.Parent = crackFolder

    local currentPixel = toPixel(startScale.X, startScale.Y)
    local allSegs = {}

    for i = 1, segmentCount do
        local segLength = (totalLength / segmentCount) * (0.8 + math.random() * 0.4)
        dirAngle = dirAngle + math.rad(math.random(-25, 25))
        local nextPixel = currentPixel + Vector2.new(math.cos(dirAngle), math.sin(dirAngle)) * segLength
        local taper = 1 - (i / segmentCount) * 0.5

        table.insert(allSegs, createBoltSegment(currentPixel, nextPixel, 11 * taper, Color3.fromRGB(255, 10, 10), 0.6, 3, bolt))
        table.insert(allSegs, createBoltSegment(currentPixel, nextPixel, 5 * taper, Color3.fromRGB(255, 60, 60), 0.25, 4, bolt))
        table.insert(allSegs, createBoltSegment(currentPixel, nextPixel, math.max(2 * taper, 1), Color3.fromRGB(255, 240, 240), 0.05, 5, bolt))

        currentPixel = nextPixel
    end

    for _, seg in ipairs(allSegs) do
        TweenService:Create(seg, TweenInfo.new(0.08, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 2, true), { BackgroundTransparency = 1 }):Play()
    end

    playOneShot(LIGHTNING_SOUND_ID, 0.7)
    task.delay(0.5, function() bolt:Destroy() end)
end

-- ============ FLASH & LIGNE DE DÉCHIRURE VISUELLE ============
local flash = Instance.new("Frame")
flash.AnchorPoint = Vector2.new(0.5, 0.5)
flash.Position = UDim2.new(0.5, 0, 0.5, 0)
flash.Size = UDim2.new(0, 0, 0, 0)
flash.BackgroundColor3 = Color3.fromRGB(255, 220, 220)
flash.BorderSizePixel = 0
flash.ZIndex = 10
flash.Parent = rootLayer
local flashCorner = Instance.new("UICorner")
flashCorner.CornerRadius = UDim.new(1, 0)
flashCorner.Parent = flash

local slash = Instance.new("Frame")
slash.AnchorPoint = Vector2.new(0.5, 0.5)
slash.Size = UDim2.new(1.8, 0, 0, 12)
slash.Position = UDim2.new(-0.9, 0, 0.5, 0)
slash.Rotation = -15
slash.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
slash.BorderSizePixel = 0
slash.ZIndex = 9
slash.Parent = rootLayer

local slashGradient = Instance.new("UIGradient")
slashGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
})
slashGradient.Parent = slash

-- ============ ÉTINCELLES EN MOUVEMENT ============
local function spawnEmber()
    local size = math.random(3, 7)
    local p = Instance.new("Frame")
    p.Size = UDim2.new(0, size, 0, size)
    p.Position = UDim2.new(math.random(0, 1000) / 1000, 0, 1, 0)
    p.BackgroundColor3 = Color3.fromRGB(math.random(220, 255), math.random(10, 50), 10)
    p.BackgroundTransparency = math.random(0, 2) / 10
    p.BorderSizePixel = 0
    p.ZIndex = 2
    p.Parent = particleFolder
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = p

    local targetY = -(math.random(50, 150) / 1000)
    local targetX = p.Position.X.Scale + (math.random(-80, 80) / 1000)
    local tween = TweenService:Create(p, TweenInfo.new(math.random(3, 5), Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
        Position = UDim2.new(targetX, 0, targetY, 0),
        BackgroundTransparency = 1,
    })
    tween:Play()
    tween.Completed:Connect(function() p:Destroy() end)
end

local function spawnRadialBurst(count, colorFrom, colorTo)
    for i = 1, count do
        local angle = math.random() * math.pi * 2
        local distance = math.random(300, 800) / 1000
        local size = math.random(4, 10)
        local p = Instance.new("Frame")
        p.AnchorPoint = Vector2.new(0.5, 0.5)
        p.Size = UDim2.new(0, size, 0, size)
        p.Position = UDim2.new(0.5, 0, 0.5, 0)
        p.BackgroundColor3 = colorFrom:Lerp(colorTo, math.random())
        p.BorderSizePixel = 0
        p.ZIndex = 4
        p.Parent = particleFolder
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = p

        local targetX = 0.5 + math.cos(angle) * distance
        local targetY = 0.5 + math.sin(angle) * distance
        local tween = TweenService:Create(p, TweenInfo.new(math.random(10, 18) / 10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = UDim2.new(targetX, 0, targetY, 0),
            BackgroundTransparency = 1,
        })
        tween:Play()
        tween.Completed:Connect(function() p:Destroy() end)
    end
end

-- ============ LE PANNEAU DE BAN ============
local panelHolder = Instance.new("Frame")
panelHolder.Name = "PanelHolder"
panelHolder.AnchorPoint = Vector2.new(0.5, 0.5)
panelHolder.Position = UDim2.new(0.5, 0, 0.5, 0)
panelHolder.Size = UDim2.new(0, 0, 0, 0)
panelHolder.BackgroundTransparency = 1
panelHolder.ZIndex = 6
panelHolder.Parent = rootLayer

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.new(1, 0, 1, 0)
panel.BackgroundColor3 = Color3.fromRGB(13, 6, 8)
panel.BorderSizePixel = 0
panel.ZIndex = 6
panel.Parent = panelHolder
local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 18)
panelCorner.Parent = panel

local panelUIStroke = Instance.new("UIStroke")
panelUIStroke.Thickness = 3
panelUIStroke.Color = Color3.fromRGB(255, 20, 25)
panelUIStroke.Transparency = 1
panelUIStroke.Parent = panel

local content = Instance.new("Frame")
content.Name = "Content"
content.Size = UDim2.new(1, 0, 1, 0)
content.BackgroundTransparency = 1
content.ZIndex = 7
content.Parent = panel

local contentLayout = Instance.new("UIListLayout")
contentLayout.FillDirection = Enum.FillDirection.Vertical
contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
contentLayout.VerticalAlignment = Enum.VerticalAlignment.Center
contentLayout.Padding = UDim.new(0, 20)
contentLayout.Parent = content

local title = Instance.new("TextLabel")
title.Size = UDim2.new(0.9, 0, 0, 50)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBlack
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextTransparency = 1
title.TextScaled = true
title.Text = "ACCÈS INTERDIT À VIE"
title.ZIndex = 7
title.Parent = content

local titleGradient = Instance.new("UIGradient")
titleGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 80)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 0, 0)),
})
titleGradient.Rotation = 90
titleGradient.Parent = title

local titleStroke = Instance.new("UIStroke")
titleStroke.Thickness = 4
titleStroke.Color = Color3.fromRGB(0, 0, 0)
titleStroke.Transparency = 1
titleStroke.Parent = title

local description = Instance.new("TextLabel")
description.Size = UDim2.new(0.85, 0, 0, 60)
description.BackgroundTransparency = 1
description.Font = Enum.Font.GothamMedium
description.TextColor3 = Color3.fromRGB(230, 210, 210)
description.TextTransparency = 1
description.TextWrapped = true
description.TextSize = 18
description.Text = "Vous avez été ban et vous ne pouvez jamais être débannis de cette plateforme qui s'appelle :\n[" .. PLATFORM_NAME .. "]"
description.ZIndex = 7
description.Parent = content

local details = Instance.new("TextLabel")
details.Size = UDim2.new(0.85, 0, 0, 45)
details.BackgroundTransparency = 1
details.Font = Enum.Font.GothamBold
details.TextColor3 = Color3.fromRGB(255, 100, 100)
details.TextTransparency = 1
details.TextSize = 16
details.Text = "Banni : " .. player.Name .. "\nBanni par : " .. BANNER_NAME
details.ZIndex = 7
details.Parent = content

local timerLabel = Instance.new("TextLabel")
timerLabel.Size = UDim2.new(0.85, 0, 0, 20)
timerLabel.BackgroundTransparency = 1
timerLabel.Font = Enum.Font.GothamSemibold
timerLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
timerLabel.TextTransparency = 1
timerLabel.TextSize = 14
timerLabel.Text = "Déconnexion forcée dans 25.0s..."
timerLabel.ZIndex = 7
timerLabel.Parent = content

local barBg = Instance.new("Frame")
barBg.Size = UDim2.new(0.7, 0, 0, 8)
barBg.BackgroundColor3 = Color3.fromRGB(30, 15, 20)
barBg.BackgroundTransparency = 1
barBg.BorderSizePixel = 0
barBg.ZIndex = 7
barBg.Parent = content
local barBgCorner = Instance.new("UICorner")
barBgCorner.CornerRadius = UDim.new(1, 0)
barBgCorner.Parent = barBg

local barFill = Instance.new("Frame")
barFill.Size = UDim2.new(1, 0, 1, 0)
barFill.BackgroundColor3 = Color3.fromRGB(255, 30, 35)
barFill.BorderSizePixel = 0
barFill.ZIndex = 8
barFill.Parent = barBg
local barFillCorner = Instance.new("UICorner")
barFillCorner.CornerRadius = UDim.new(1, 0)
barFillCorner.Parent = barFill

local emberThread = task.spawn(function()
    while true do
        spawnEmber()
        task.wait(0.08)
    end
end)

-- ==================== SÉQUENCE CINÉMATIQUE (30s) ====================

-- Étape 1 : Foudre d'introduction
task.wait(0.5)
local crackThread = task.spawn(function()
    for i = 1, 8 do
        spawnLightningBolt()
        addShake(2.5 + i)
        task.wait(math.max(0.4 - i * 0.04, 0.1))
    end
end)
task.wait(2.5)

-- Étape 2 : L'impact colossal
addShake(MAX_SHAKE)
playOneShot(IMPACT_SOUND_ID, 0.9)

local flashGrow = TweenService:Create(flash, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
    Size = UDim2.new(2.5, 0, 2.5, 0),
    BackgroundTransparency = 0,
})
flashGrow:Play()
flashGrow.Completed:Wait()

spawnRadialBurst(110, Color3.fromRGB(255, 230, 200), Color3.fromRGB(220, 0, 10))
spawnLightningBolt()

local flashFade = TweenService:Create(flash, TweenInfo.new(0.4), { BackgroundTransparency = 1 })
flashFade:Play()

local slashMove = TweenService:Create(slash, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
    Position = UDim2.new(1.9, 0, 0.5, 0),
})
slashMove:Play()
slashMove.Completed:Wait()
slash:Destroy()
flash:Destroy()

-- Étape 3 : Révélation du cadre
addShake(12)
panelHolder.Size = UDim2.new(0, 680, 0, 390)

local panelGrow = TweenService:Create(panelHolder, TweenInfo.new(1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size = UDim2.new(0, 680, 0, 390)
})
panelGrow:Play()
TweenService:Create(panelUIStroke, TweenInfo.new(1), { Transparency = 0.2 }):Play()
panelGrow.Completed:Wait()

-- Étape 4 : Cascade de texte
TweenService:Create(title, TweenInfo.new(0.5), { TextTransparency = 0 }):Play()
TweenService:Create(titleStroke, TweenInfo.new(0.5), { Transparency = 0.2 }):Play()
task.wait(0.3)

TweenService:Create(description, TweenInfo.new(0.5), { TextTransparency = 0 }):Play()
task.wait(0.3)

TweenService:Create(details, TweenInfo.new(0.5), { TextTransparency = 0 }):Play()
task.wait(0.3)

TweenService:Create(timerLabel, TweenInfo.new(0.5), { TextTransparency = 0 }):Play()
TweenService:Create(barBg, TweenInfo.new(0.5), { BackgroundTransparency = 0 }):Play()
task.wait(0.5)

task.cancel(crackThread)

TweenService:Create(panelUIStroke, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
    Transparency = 0.8,
    Color = Color3.fromRGB(150, 0, 0)
}):Play()

TweenService:Create(vignette, TweenInfo.new(2.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
    BackgroundTransparency = 0.4
}):Play()

-- Étape 5 : Compte à rebours étendu à 30 secondes au total
local totalDuration = 24.5 
local startTime = os.clock()

while os.clock() - startTime < totalDuration do
    local elapsed = os.clock() - startTime
    local remaining = math.max(0, totalDuration - elapsed)
    local progress = remaining / totalDuration
    
    timerLabel.Text = string.format("Fermeture de la connexion dans %.1fs...", remaining)
    barFill.Size = UDim2.new(progress, 0, 1, 0)
    
    task.wait(0.05)
end

timerLabel.Text = "Déconnexion..."
barFill.Size = UDim2.new(0, 0, 1, 0)
task.wait(0.5)

-- Nettoyage de la boucle de blocage physique avant kick
task.cancel(blockThread)

-- Étape 6 : Expulsion finale
-- Service de localisation Roblox
local LocalizationService = game:GetService("LocalizationService")

-- Détection de la langue du joueur (ex: "fr-fr", "en-us", "es-es")
local playerLocale = "en"
pcall(function()
    playerLocale = string.sub(string.lower(LocalizationService.RobloxLocaleId), 1, 2)
end)

-- Messages traduits selon la langue
local messages = {
    fr = {
        header = "[ BANNISSEMENT DÉFINITIF ET IRRÉVOCABLE ]",
        desc = "Vous avez été banni définitivement de la plateforme :",
        by = "Sanction appliquée par : ",
        footer = "Toute tentative de reconnexion est vaine. Votre dossier est clos."
    },
    en = {
        header = "[ PERMANENT AND IRREVOCABLE BAN ]",
        desc = "You have been permanently banned from the platform:",
        by = "Sanction applied by: ",
        footer = "Any reconnection attempt is futile. Your case is closed."
    },
    es = {
        header = "[ BANEO PERMANENTE E IRREVOCABLE ]",
        desc = "Has sido baneado permanentemente de la plataforma:",
        by = "Sanción aplicada por: ",
        footer = "Cualquier intento de reconexión es inútil. Su expediente está cerrado."
    },
    de = {
        header = "[ DAUERHAFTER UND UNWIDERRUFLICHER BAN ]",
        desc = "Du wurdest dauerhaft von der Plattform gebannt:",
        by = "Sanktion angewendet von: ",
        footer = "Jeder Versuch einer Neuanmeldung ist zwecklos. Ihr Fall ist abgeschlossen."
    },
    pt = {
        header = "[ BANIMENTO PERMANENTE E IRREVOGÁVEL ]",
        desc = "Você foi banido permanentemente da plataforma:",
        by = "Sanção aplicada por: ",
        footer = "Qualquer tentativa de reconexão é inútil. Seu caso está encerrado."
    },
    ru = {
        header = "[ ПОСТОЯННЫЙ И НЕОТЗЫВНЫЙ БАН ]",
        desc = "Вы были навсегда заблокированы на платформе:",
        by = "Наказание применил: ",
        footer = "Любые попытки повторного подключения бесполезны. Ваше дело закрыто."
    }
}

-- Sélection du message (utilisation de l'anglais par défaut si la langue n'est pas dans la liste)
local msg = messages[playerLocale] or messages["en"]

-- Étape 6 : Expulsion finale multilingue
player:Kick(
    "\n========================================\n" ..
    msg.header .. "\n" ..
    "========================================\n\n" ..
    msg.desc .. "\n" ..
    "-> " .. PLATFORM_NAME .. "\n\n" ..
    msg.by .. BANNER_NAME .. "\n\n" ..
    msg.footer
)
