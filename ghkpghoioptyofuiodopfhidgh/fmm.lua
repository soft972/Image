local WeaponModule = {}

-- ==========================================================
-- TA BASE DE DONNÉES DE RARETÉS (Modifiable sur GitHub)
-- ==========================================================
WeaponModule.Database = {
    -- ["nom_en_minuscules"] = Color3.fromRGB(R, G, B)
    ["p226"] = Color3.fromRGB(0, 170, 255), 
    ["clè"] = Color3.fromRGB(0, 170, 255), 
    ["lame de commutation"] = Color3.fromRGB(0, 170, 255), 
    ["balai en diamant"] = Color3.fromRGB(0, 170, 255), 
    
    ["g3"] = Color3.fromRGB(0, 255, 0), 
    ["marteau"] = Color3.fromRGB(0, 255, 0), 
    
    ["fists"] = Color3.fromRGB(150, 150, 150),
    ["combat"] = Color3.fromRGB(150, 150, 150)
}

-- Fonction interne de récupération de texture
function WeaponModule.getToolTexture(tool)
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

-- Fonction de décryptage par MeshId
function WeaponModule.matchToolName(tool, ReplicatedStorage, StarterPack)
    if not tool then return "Unknown", WeaponModule.getToolTexture(nil) end
    if toolCache[tool] then return toolCache[tool].name, toolCache[tool].texture end

    local nameLower = tool.Name:lower()
    if nameLower == "combat" or nameLower == "fists" or nameLower == "fist" then
        local tex = WeaponModule.getToolTexture(tool)
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
                                local matchedTex = WeaponModule.getToolTexture(item)
                                toolCache[tool] = {name = matchedName, texture = matchedTex}
                                return matchedName, matchedTex 
                            end
                        end
                    end
                end
            end
        end
    end
    
    local fallbackTex = WeaponModule.getToolTexture(tool)
    toolCache[tool] = {name = realName, texture = fallbackTex}
    return realName, fallbackTex
end

-- Fonction d'attribution de la couleur de rareté
function WeaponModule.getToolRarityColor(toolName)
    local name = tostring(toolName):lower()
    if WeaponModule.Database[name] then
        return WeaponModule.Database[name]
    end
    return Color3.fromRGB(255, 255, 255) -- Blanc par défaut si non trouvé
end

return WeaponModule
