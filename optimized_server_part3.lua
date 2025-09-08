-- OPTIMIZED MEDICAL SYSTEM AND LOOP OPTIMIZATION
-- Part 3 of optimized ACS server script

-- OPTIMIZATION: Consolidated medical system with reduced redundancy
local MedicalSystem = {
    -- Cache frequently accessed medical functions
    Functions = Evt.MedSys,
    FunctionsMulti = Evt.MedSys.Multi,
    
    -- OPTIMIZATION: Pre-cache all medical events to reduce lookups
    Events = {
        Bandage = Evt.MedSys.Bandage,
        Splint = Evt.MedSys.Splint,
        PainRelief = Evt.MedSys.PainRelief,
        Energy = Evt.MedSys.Energy,
        Tourniquet = Evt.MedSys.Tourniquet,
        Algemar = Evt.MedSys.Algemar,
        Fome = Evt.MedSys.Fome,
        Collapse = Evt.MedSys.Collapse,
        rodeath = Evt.MedSys.rodeath,
        Reset = Evt.MedSys.Reset,
    },
    
    MultiEvents = {
        Compress = Evt.MedSys.Multi.Compress,
        Bandage = Evt.MedSys.Multi.Bandage,
        Splint = Evt.MedSys.Multi.Splint,
        EnergyShot = Evt.MedSys.Multi.EnergyShot,
        Tranquilizer = Evt.MedSys.Multi.Tranquilizer,
        Suppressant = Evt.MedSys.Multi.Suppressant,
        BloodBag = Evt.MedSys.Multi.BloodBag,
        Tourniquet = Evt.MedSys.Multi.Tourniquet,
        prolene = Evt.MedSys.Multi.prolene,
        o2 = Evt.MedSys.Multi.o2,
        defib = Evt.MedSys.Multi.defib,
        npa = Evt.MedSys.Multi.npa,
        catheter = Evt.MedSys.Multi.catheter,
        etube = Evt.MedSys.Multi.etube,
        nylon = Evt.MedSys.Multi.nylon,
        balloon = Evt.MedSys.Multi.balloon,
        skit = Evt.MedSys.Multi.skit,
        bvm = Evt.MedSys.Multi.bvm,
        nrb = Evt.MedSys.Multi.nrb,
        scalpel = Evt.MedSys.Multi.scalpel,
        suction = Evt.MedSys.Multi.suction,
        clamp = Evt.MedSys.Multi.clamp,
        prolene5 = Evt.MedSys.Multi.prolene5,
        drawblood = Evt.MedSys.Multi.drawblood,
    }
}

-- OPTIMIZATION: Generic medical function handler to reduce code duplication
local function HandleMedicalAction(player, actionType, isMulti)
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    local saude = character:FindFirstChild("Saude")
    if not saude then return end
    
    local variaveis = saude:FindFirstChild("Variaveis")
    local stances = saude:FindFirstChild("Stances")
    local kit = saude:FindFirstChild("Kit")
    
    if not variaveis or not stances or not kit then return end
    
    local enabled = variaveis:FindFirstChild("Doer")
    local caido = stances:FindFirstChild("Caido")
    
    if not enabled or not caido then return end
    
    -- Rate limiting for medical actions
    if IsRateLimited(player, actionType, 0.5) then return end
    
    return {
        humanoid = humanoid,
        enabled = enabled,
        caido = caido,
        variaveis = variaveis,
        stances = stances,
        kit = kit,
        character = character
    }
end

-- OPTIMIZATION: Consolidated single-player medical actions
local function SetupSingleMedicalActions()
    local actions = {
        Bandage = function(player)
            local data = HandleMedicalAction(player, "Bandage", false)
            if not data then return end
            
            local bandages = data.kit:FindFirstChild("Bandage")
            local sangrando = data.stances:FindFirstChild("Sangrando")
            
            if data.enabled.Value == false and data.caido.Value == false and 
               bandages and bandages.Value >= 1 and sangrando and sangrando.Value then
                data.enabled.Value = true
                task.wait(0.3)
                sangrando.Value = false
                bandages.Value = bandages.Value - 1
                task.wait(2)
                data.enabled.Value = false
            end
        end,
        
        Splint = function(player)
            local data = HandleMedicalAction(player, "Splint", false)
            if not data then return end
            
            local splints = data.kit:FindFirstChild("Splint")
            local ferido = data.stances:FindFirstChild("Ferido")
            
            if data.enabled.Value == false and data.caido.Value == false and 
               splints and splints.Value >= 1 and ferido and ferido.Value then
                data.enabled.Value = true
                task.wait(0.3)
                ferido.Value = false
                splints.Value = splints.Value - 1
                task.wait(2)
                data.enabled.Value = false
            end
        end,
        
        PainRelief = function(player)
            local data = HandleMedicalAction(player, "PainRelief", false)
            if not data then return end
            
            local painRelief = data.kit:FindFirstChild("PainRelief")
            local dor = data.variaveis:FindFirstChild("Dor")
            
            if data.enabled.Value == false and data.caido.Value == false and 
               painRelief and painRelief.Value >= 1 and dor and dor.Value >= 1 then
                data.enabled.Value = true
                task.wait(0.3)
                dor.Value = dor.Value - math.random(60, 75)
                painRelief.Value = painRelief.Value - 1
                task.wait(2)
                data.enabled.Value = false
            end
        end,
        
        Energy = function(player)
            local data = HandleMedicalAction(player, "Energy", false)
            if not data then return end
            
            local energy = data.kit:FindFirstChild("Energy")
            
            if data.enabled.Value == false and data.caido.Value == false and 
               energy and energy.Value >= 1 and data.humanoid.Health < data.humanoid.MaxHealth then
                data.enabled.Value = true
                task.wait(0.3)
                data.humanoid.Health = data.humanoid.Health + (data.humanoid.MaxHealth / 3)
                energy.Value = energy.Value - 1
                task.wait(2)
                data.enabled.Value = false
            end
        end,
        
        Tourniquet = function(player)
            local data = HandleMedicalAction(player, "Tourniquet", false)
            if not data then return end
            
            local tourniquets = data.kit:FindFirstChild("Tourniquet")
            local tourniquetStance = data.stances:FindFirstChild("Tourniquet")
            
            if not tourniquets or not tourniquetStance then return end
            
            if data.enabled.Value == false then
                if tourniquetStance.Value == false and tourniquets.Value > 0 then
                    data.enabled.Value = true
                    task.wait(0.3)
                    tourniquetStance.Value = true
                    tourniquets.Value = tourniquets.Value - 1
                    task.wait(2)
                    data.enabled.Value = false
                elseif tourniquetStance.Value == true then
                    data.enabled.Value = true
                    task.wait(0.3)
                    tourniquetStance.Value = false
                    tourniquets.Value = tourniquets.Value + 1
                    task.wait(2)
                    data.enabled.Value = false
                end
            end
        end
    }
    
    -- Connect all single medical actions
    for actionName, actionFunc in pairs(actions) do
        MedicalSystem.Events[actionName].OnServerEvent:Connect(actionFunc)
    end
end

-- OPTIMIZATION: Consolidated multi-player medical actions
local function SetupMultiMedicalActions()
    local function HandleMultiMedicalAction(player, actionType, targetPlayerName)
        local data = HandleMedicalAction(player, actionType, true)
        if not data then return end
        
        local target = data.variaveis:FindFirstChild("PlayerSelecionado")
        if not target or target.Value == "N/A" then return end
        
        local player2 = Players:FindFirstChild(target.Value)
        if not player2 or not player2.Character then return end
        
        local p2Humanoid = player2.Character:FindFirstChild("Humanoid")
        local p2Saude = player2.Character:FindFirstChild("Saude")
        if not p2Humanoid or not p2Saude then return end
        
        local p2Variaveis = p2Saude:FindFirstChild("Variaveis")
        local p2Stances = p2Saude:FindFirstChild("Stances")
        local p2Kit = p2Saude:FindFirstChild("Kit")
        
        if not p2Variaveis or not p2Stances or not p2Kit then return end
        
        return {
            player = player,
            data = data,
            targetPlayer = player2,
            p2Humanoid = p2Humanoid,
            p2Saude = p2Saude,
            p2Variaveis = p2Variaveis,
            p2Stances = p2Stances,
            p2Kit = p2Kit
        }
    end
    
    -- OPTIMIZATION: Generic multi-medical action handler
    local multiActions = {
        Bandage = function(player)
            local multiData = HandleMultiMedicalAction(player, "Bandage_Multi")
            if not multiData then return end
            
            local bandages = multiData.data.kit:FindFirstChild("Bandage")
            local sangrando = multiData.p2Stances:FindFirstChild("Sangrando")
            
            if multiData.data.enabled.Value == false and 
               bandages and bandages.Value >= 1 and sangrando and sangrando.Value then
                multiData.data.enabled.Value = true
                task.wait(0.3)
                if math.random(1, 2) == 1 then
                    sangrando.Value = false
                end
                bandages.Value = bandages.Value - 1
                task.wait(2)
                multiData.data.enabled.Value = false
            end
        end,
        
        Compress = function(player)
            local multiData = HandleMultiMedicalAction(player, "Compress_Multi")
            if not multiData then return end
            
            local sangrando = multiData.p2Stances:FindFirstChild("Sangrando")
            local tourniquet = multiData.data.stances:FindFirstChild("Tourniquet")
            local isdead = multiData.p2Stances:FindFirstChild("rodeath")
            
            if multiData.data.enabled.Value == false and 
               isdead and isdead.Value and 
               (not sangrando or not sangrando.Value or tourniquet and tourniquet.Value) then
                multiData.data.enabled.Value = true
                multiData.p2Humanoid.Health = multiData.p2Humanoid.Health + 5
                task.wait(0.5)
                multiData.data.enabled.Value = false
            end
        end
    }
    
    -- Connect multi medical actions
    for actionName, actionFunc in pairs(multiActions) do
        MedicalSystem.MultiEvents[actionName].OnServerEvent:Connect(actionFunc)
    end
end

-- Initialize medical systems
SetupSingleMedicalActions()
SetupMultiMedicalActions()

-- OPTIMIZATION: Consolidated stance and animation system
local StanceSystem = {
    -- Cache stance-related events
    Stance = Evt.MedSys.Stance,
    StanceSound = Evt.StanceSound,
    HeadRot = Evt.HeadRot,
    
    -- OPTIMIZATION: Pre-calculate common stance positions
    StancePositions = {
        [0] = { -- Standing
            RootJoint = CFrame.new(0,0,0) * CFrame.Angles(math.rad(0),0,math.rad(0)),
            RightHip = CFrame.new(1,-1,0) * CFrame.Angles(math.rad(0),math.rad(90),math.rad(0)),
            LeftHip = CFrame.new(-1,-1,0) * CFrame.Angles(math.rad(0),math.rad(-90),math.rad(0)),
            RightShoulder = CFrame.new(1,0.5,0) * CFrame.Angles(math.rad(0),math.rad(90),math.rad(0)),
            LeftShoulder = CFrame.new(-1,0.5,0) * CFrame.Angles(math.rad(0),math.rad(-90),math.rad(0))
        },
        [1] = { -- Crouching
            RootJoint = CFrame.new(0,-1,0.25) * CFrame.Angles(math.rad(-10),0,math.rad(0)),
            RightHip = CFrame.new(1,-0.35,-0.65) * CFrame.Angles(math.rad(-20),math.rad(90),math.rad(0)),
            LeftHip = CFrame.new(-1,-1.25,-0.625) * CFrame.Angles(math.rad(-60),math.rad(-90),math.rad(0)),
            RightShoulder = CFrame.new(1,0.5,0) * CFrame.Angles(math.rad(0),math.rad(90),math.rad(0)),
            LeftShoulder = CFrame.new(-1,0.5,0) * CFrame.Angles(math.rad(0),math.rad(-90),math.rad(0))
        },
        [2] = { -- Prone
            RootJoint = CFrame.new(0,-2.5,1.35) * CFrame.Angles(math.rad(-90),0,math.rad(0)),
            RightHip = CFrame.new(1,-1,0) * CFrame.Angles(math.rad(0),math.rad(90),math.rad(0)),
            LeftHip = CFrame.new(-1,-1,0) * CFrame.Angles(math.rad(0),math.rad(-90),math.rad(0)),
            RightShoulder = CFrame.new(0.9,1.1,0) * CFrame.Angles(math.rad(-180),math.rad(90),math.rad(0)),
            LeftShoulder = CFrame.new(-0.9,1.1,0) * CFrame.Angles(math.rad(-180),math.rad(-90),math.rad(0))
        }
    }
}

-- OPTIMIZATION: Efficient stance application
local function ApplyStance(character, stance, leanDirection, isSurrendered, isHandcuffed)
    if not character or character.Humanoid.Health <= 0 then return end
    
    local torso = character:WaitForChild("Torso")
    local rootPart = character:WaitForChild("HumanoidRootPart")
    local rootJoint = rootPart:WaitForChild("RootJoint")
    local neck = torso:WaitForChild("Neck")
    local rightShoulder = torso:WaitForChild("Right Shoulder")
    local leftShoulder = torso:WaitForChild("Left Shoulder")
    local rightHip = torso:WaitForChild("Right Hip")
    local leftHip = torso:WaitForChild("Left Hip")
    
    rootJoint.C1 = CFrame.new()
    
    local stanceData = StanceSystem.StancePositions[stance]
    if not stanceData then return end
    
    -- Apply base stance
    TS:Create(rootJoint, TweenInfo.new(0.3), {C0 = stanceData.RootJoint}):Play()
    TS:Create(rightHip, TweenInfo.new(0.3), {C0 = stanceData.RightHip}):Play()
    TS:Create(leftHip, TweenInfo.new(0.3), {C0 = stanceData.LeftHip}):Play()
    TS:Create(rightShoulder, TweenInfo.new(0.3), {C0 = stanceData.RightShoulder}):Play()
    TS:Create(leftShoulder, TweenInfo.new(0.3), {C0 = stanceData.LeftShoulder}):Play()
    
    -- Apply lean modifications
    if leanDirection ~= 0 then
        local leanOffset = leanDirection * 1
        local leanAngle = leanDirection * math.rad(30)
        
        TS:Create(rootJoint, TweenInfo.new(0.3), {
            C0 = stanceData.RootJoint * CFrame.new(leanOffset, 0, 0) * CFrame.Angles(0, 0, leanAngle)
        }):Play()
    end
    
    -- Apply surrender/handcuff positions
    if isSurrendered and not isHandcuffed then
        TS:Create(rightShoulder, TweenInfo.new(0.3), {
            C0 = CFrame.new(1,0.75,0) * CFrame.Angles(math.rad(110),math.rad(120),math.rad(70))
        }):Play()
        TS:Create(leftShoulder, TweenInfo.new(0.3), {
            C0 = CFrame.new(-1,0.75,0) * CFrame.Angles(math.rad(110),math.rad(-120),math.rad(-70))
        }):Play()
    elseif isHandcuffed then
        TS:Create(rightShoulder, TweenInfo.new(0.3), {
            C0 = CFrame.new(.6,0.75,0) * CFrame.Angles(math.rad(240),math.rad(120),math.rad(100))
        }):Play()
        TS:Create(leftShoulder, TweenInfo.new(0.3), {
            C0 = CFrame.new(-.6,0.75,0) * CFrame.Angles(math.rad(240),math.rad(-120),math.rad(-100))
        }):Play()
    end
end

-- Connect stance system
StanceSystem.Stance.OnServerEvent:Connect(function(player, stances, virar, rendido)
    local character = player.Character
    if not character then return end
    
    local saude = character:WaitForChild("Saude")
    local stancesData = saude:WaitForChild("Stances")
    
    local isSurrendered = rendido and stancesData:FindFirstChild("Algemado") and not stancesData.Algemado.Value
    local isHandcuffed = stancesData:FindFirstChild("Algemado") and stancesData.Algemado.Value
    
    ApplyStance(character, stances, virar, isSurrendered, isHandcuffed)
end)