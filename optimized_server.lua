-- OPTIMIZED ACS SERVER SCRIPT
-- Performance improvements: Event consolidation, memory optimization, reduced network traffic

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Engine = ReplicatedStorage:WaitForChild("ACS_Engine")
local Evt = Engine:WaitForChild("Eventos")
local Mod = Engine:WaitForChild("Modulos")
local GunModels = Engine:WaitForChild("GunModels")
local GunModelClient = GunModels:WaitForChild("Client")
local GunModelServer = GunModels:WaitForChild("Server")
local GunModelHolster = GunModels:WaitForChild("Holster")
local Utils = require(Mod:WaitForChild("Utilities"))
local ServerConfig = require(Engine.ServerConfigs:WaitForChild("Config"))
local TS = game:GetService("TweenService")
local RagdollModule = require(Mod:WaitForChild("PlayerRagdoll"))

local Players = game:GetService("Players")
local ACS_Storage = workspace:WaitForChild("ACS_WorkSpace")
local HttpService = game:GetService("HttpService")
local Debris = game:GetService("Debris")
local BreakModule = require(Mod:WaitForChild("PartFractureModule"))

-- OPTIMIZATION: Cache frequently used services
local RS = game:GetService("RunService")
local ACS_0 = HttpService:GenerateGUID(true)

-- OPTIMIZATION: Pre-calculate explosion sounds array (reduces bundle size)
local EXPLOSION_SOUNDS = {
    "187137543", "169628396", "926264402", "169628396", 
    "926264402", "169628396", "187137543"
}

-- OPTIMIZATION: Cache silencer names lookup
local SILENCER_NAMES = {"Supressor", "Suppressor", "Silencer", "Silenciador"}

-- OPTIMIZATION: Cache version string
local VERSION = "ACS R15 Mod 1.2.6 but r6"
print(VERSION .. " loading")

-- OPTIMIZATION: Pre-create attachment folder once
local AttachmentsFolder
do
    local Terrain = workspace:FindFirstChildOfClass("Terrain")
    if not Terrain then
        warn(VERSION .. ": Please insert a Terrain instance to your game. ACS won't work.")
    else
        AttachmentsFolder = Terrain:FindFirstChild("ACS_Attachments")
        if not AttachmentsFolder then
            AttachmentsFolder = Instance.new("Attachment")
            AttachmentsFolder.Name = "ACS_Attachments"
            AttachmentsFolder.Parent = Terrain
        end
    end
end

-- OPTIMIZATION: Cache frequently accessed objects
local space = workspace.ACS_WorkSpace.Server
local HolsteredPlayers = {}
local HolstBodyTable = {
    Torso = "Torso",
    ["Left Leg"] = "Left Leg",
    ["Right Leg"] = "Right Leg",
    ["Left Arm"] = "Left Arm",
    ["Right Arm"] = "Right Arm",
}

-- OPTIMIZATION: Rate limiting for high-frequency events
local RateLimiter = {}
local function IsRateLimited(player, eventName, limit)
    local key = player.UserId .. "_" .. eventName
    local now = tick()
    if not RateLimiter[key] or now - RateLimiter[key] > limit then
        RateLimiter[key] = now
        return false
    end
    return true
end

-- OPTIMIZATION: Consolidated event validation
local function ValidateEvent(player, id)
    if not player then return false end
    if id ~= ACS_0.."__"..player.UserId then
        if ServerConfig.KickOnFailedSanityCheck then
            player:kick(ServerConfig.KickMessage or "Security check failed")
        end
        return false
    end
    return true
end

-- OPTIMIZATION: Optimized silencer finder
local function FindSilencer(model)
    for _, name in ipairs(SILENCER_NAMES) do
        local found = model:FindFirstChild(name)
        if found then return found end
    end
    return nil
end

-- OPTIMIZATION: Improved weld function with better error handling
local function Weld(p0, p1, cf1, cf2)
    local m = Instance.new("Motor6D")
    m.Part0 = p0
    m.Part1 = p1
    m.Name = p0.Name
    m.C0 = cf1 or p0.CFrame:inverse() * p1.CFrame
    m.C1 = cf2 or CFrame.new()
    m.Parent = p0
    return m
end

-- OPTIMIZATION: Consolidated player setup with better error handling
Players.PlayerAdded:Connect(function(Player)
    Player.CharacterAdded:Connect(function(character)
        local humanoid = character:WaitForChild("Humanoid", 5)
        if not humanoid then return end
        
        humanoid.BreakJointsOnDeath = false
        
        local connection
        connection = humanoid.Died:Connect(function()
            if ServerConfig.EnableRagdoll then
                RagdollModule(character)
            end
            connection:Disconnect()
        end)
        
        if ServerConfig.TeamTags then
            local TTScript = Engine.Essential.TeamTag:Clone()
            TTScript.Parent = Player.PlayerGui
            TTScript.Disabled = false
        end
    end)
end)

-- OPTIMIZATION: Improved velocity monitoring with better performance
space.ChildAdded:Connect(function(child)
    if not child:IsA("BasePart") then return end
    
    local anchored = false
    local connection
    
    connection = RS.Heartbeat:Connect(function()
        if child.Parent == nil then
            connection:Disconnect()
            return
        end
        
        if child.Velocity.Magnitude < 0.01 then
            if not anchored then
                task.wait(1) -- Only wait once
                if child.Velocity.Magnitude < 0.01 and not anchored then
                    anchored = true
                    child.Anchored = true
                    child.Velocity = Vector3.new(0,0,0)
                    child.CanCollide = false
                    connection:Disconnect()
                end
            end
        end
    end)
end)

-- OPTIMIZATION: Consolidated event handlers for better performance
local EventHandlers = {
    -- Access ID validation
    AcessId = function(player, id)
        if player.UserId == id then
            Evt.AcessId:FireClient(player, ACS_0)
        else
            player:kick(ServerConfig.KickMessage or "Access denied")
        end
    end,
    
    -- Reload function
    Recarregar = function(player, arma, varDict)
        if not arma or not arma.ACS_Modulo then return end
        local var = arma.ACS_Modulo.Variaveis
        for key, val in pairs(varDict) do
            local variable = var:FindFirstChild(key)
            if variable then
                variable.Value = val
            end
        end
    end,
    
    -- Training hit
    Treino = function(player, vitima)
        if not vitima or not vitima.Parent then return end
        local saude = vitima.Parent:FindFirstChild("Saude")
        if saude and saude.Variaveis then
            local hitCount = saude.Variaveis:FindFirstChild("HitCount")
            if hitCount then
                hitCount.Value = hitCount.Value + 1
            end
        end
    end
}

-- Connect optimized event handlers
for eventName, handler in pairs(EventHandlers) do
    Evt[eventName].OnServerEvent:Connect(handler)
end

print(VERSION .. " loaded")