-- OPTIMIZED MEDICAL SYSTEM AND MEMORY MANAGEMENT
-- Part 2 of optimized ACS server script

-- OPTIMIZATION: Memory-efficient explosion handling
local function CreateExplosion(position, settings)
    local hitmark = Instance.new("Attachment")
    hitmark.CFrame = CFrame.new(position)
    hitmark.Parent = AttachmentsFolder
    Debris:AddItem(hitmark, 5)

    local exp = Instance.new("Explosion")
    exp.BlastPressure = settings.ExPressure
    exp.BlastRadius = settings.ExpRadius
    exp.DestroyJointRadiusPercent = settings.DestroyJointRadiusPercent
    exp.ExplosionType = Enum.ExplosionType.NoCraters
    exp.Position = position
    exp.Parent = hitmark

    if settings.ExplosionDamagesTerrain then
        local exp2 = Instance.new("Explosion")
        exp2.BlastPressure = 0
        exp2.BlastRadius = settings.TerrainDamageRadius
        exp2.DestroyJointRadiusPercent = 0
        exp2.Visible = false
        exp2.Position = position
        exp2.Parent = hitmark
    end

    -- OPTIMIZATION: Pre-calculate sound properties
    local dm = settings.ExpSoundDistanceMult or 1
    local vm = settings.ExpSoundVolumeMult or 1
    local soundId = "rbxassetid://" .. EXPLOSION_SOUNDS[math.random(1, #EXPLOSION_SOUNDS)]
    local playbackSpeed = math.random(30, 55) / 40

    -- Create main sound
    local s = Instance.new("Sound")
    s.RollOffMinDistance = 40 * dm
    s.RollOffMaxDistance = 400 * dm
    s.RollOffMode = Enum.RollOffMode.InverseTapered
    s.SoundId = soundId
    s.PlaybackSpeed = playbackSpeed
    s.Volume = 2 * vm
    s.Parent = hitmark

    -- Create distant sound
    local s2 = Instance.new("Sound")
    s2.RollOffMinDistance = 400 * dm
    s2.RollOffMaxDistance = 8000 * dm
    s2.RollOffMode = Enum.RollOffMode.InverseTapered
    s2.SoundId = soundId
    s2.PlaybackSpeed = playbackSpeed * 0.95
    s2.Volume = 0.4 * vm

    local mod = Instance.new("EqualizerSoundEffect")
    mod.HighGain = -36
    mod.MidGain = -3
    mod.LowGain = 3
    mod.Parent = s2
    s2.Parent = hitmark

    -- OPTIMIZATION: Fire sounds to clients efficiently
    Evt.FireSound:FireAllClients(nil, "Play", s, position)
    Evt.FireSound:FireAllClients(nil, "Play", s2, position)

    -- Handle explosion damage
    exp.Hit:Connect(function(hitPart, partDistance)
        local humanoid = hitPart.Parent and hitPart.Parent:FindFirstChild("Humanoid")
        if humanoid then
            local distanceFactor = 1 - (partDistance / settings.ExpRadius)
            if distanceFactor > 0 then
                humanoid:TakeDamage(settings.ExplosionDamage * distanceFactor)
            end
        end
    end)
end

-- OPTIMIZATION: Consolidated hit event handler
Evt.Hit2.OnServerEvent:Connect(function(player, hitPart, offset, material, settings, id, bulletPower, hitType)
    if not ValidateEvent(player, id) or not hitPart then return end

    -- OPTIMIZATION: Rate limiting for hit events
    if IsRateLimited(player, "Hit2", 0.1) then return end

    Evt.Hit2:FireAllClients(player, hitPart, offset, material, settings, bulletPower, hitType)

    -- Handle destroyable lights efficiently
    if hitPart.Parent and (hitPart.Parent:FindFirstChild("DestroyableLight") or hitPart.Parent.Name == "DestroyableLight") then
        for _, light in pairs(hitPart.Parent:GetDescendants()) do
            if light:IsA("Light") then
                light.Enabled = false
            end
        end
    elseif hitPart.Name == "DestroyableLight" then
        for _, light in pairs(hitPart:GetDescendants()) do
            if light:IsA("Light") then
                light.Enabled = false
            end
        end
    end

    -- Handle breakable objects
    if hitPart.Name == "BreakableObj" then
        local breakingPoint = hitPart:FindFirstChild("BreakingPoint")
        if not breakingPoint or not breakingPoint:IsA("Attachment") then
            breakingPoint = Instance.new("Attachment")
            breakingPoint.Name = "BreakingPoint"
            breakingPoint.Parent = hitPart
        end
        breakingPoint.WorldPosition = OffHitCF(hitPart, offset).Position
        BreakModule.FracturePart(hitPart)
    end

    -- Handle explosive hits
    if settings.ExplosiveHit then
        CreateExplosion(OffHitCF(hitPart, offset).Position, settings)
    end
end)

-- OPTIMIZATION: Memory-efficient fake arm creation
local function CreateFakeArm(char, arm)
    local part = char:FindFirstChild("Fake" .. arm.Name)
    if not part then
        part = arm:Clone()
        part.Name = "Fake" .. arm.Name
        part:ClearAllChildren()
        part.Transparency = 1
        part.Size = arm.Size
        part.CanCollide = false
        part.Parent = char
    end

    local weld = part:FindFirstChild(arm.Name)
    if not weld then
        weld = Instance.new("Weld")
        weld.Name = arm.Name
        weld.Part0 = part
        weld.Part1 = arm
        weld.C0 = CFrame.new()
        weld.C1 = CFrame.new()
        weld.Parent = part
    end

    return part
end

-- OPTIMIZATION: Improved weapon equipping with better memory management
Evt.Equipar.OnServerEvent:Connect(function(player, arma)
    local character = player.Character
    if not character then return end

    local head = character:FindFirstChild('Head')
    if not head then return end

    -- Clean up existing holstered weapon
    local existingHolst = character:FindFirstChild('Holst' .. arma.Name)
    if existingHolst then
        existingHolst:Destroy()
    end

    -- Validate gun model exists
    local serverGunModel = GunModelServer:FindFirstChild(arma.Name)
    if not serverGunModel then
        warn("Gun server model not found: " .. arma.Name)
        return
    end

    local serverGun = serverGunModel:Clone()
    serverGun.Name = 'S' .. arma.Name
    local grip = serverGun:FindFirstChild("Grip")
    if not grip then
        warn("Grip not found on gun: " .. arma.Name)
        serverGun:Destroy()
        return
    end

    local settings = require(arma.ACS_Modulo.Variaveis:WaitForChild("Settings"))
    arma.ACS_Modulo.Variaveis.BType.Value = settings.BulletType

    -- Create animation base
    local animBase = Instance.new("Part")
    animBase.FormFactor = "Custom"
    animBase.CanCollide = false
    animBase.Transparency = 1
    animBase.Anchored = false
    animBase.Name = "AnimBase"
    animBase.Size = Vector3.new(0.1, 0.1, 0.1)
    animBase.Parent = character

    local animBaseW = Instance.new("Motor6D")
    animBaseW.Part0 = animBase
    animBaseW.Part1 = head
    animBaseW.Parent = animBase
    animBaseW.Name = "AnimBaseW"

    -- Create fake arms
    local rightArm = character["Right Arm"]
    local leftArm = character["Left Arm"]
    local fakeRightArm = CreateFakeArm(character, rightArm)
    local fakeLeftArm = CreateFakeArm(character, leftArm)

    -- Setup arm welds
    local rightShoulder = character.Torso:WaitForChild("Right Shoulder")
    local leftShoulder = character.Torso:WaitForChild("Left Shoulder")

    local rightArmWeld = Instance.new("Motor6D")
    rightArmWeld.Name = "RAW"
    rightArmWeld.Part0 = animBase
    rightArmWeld.Part1 = rightArm
    rightArmWeld.Parent = animBase
    rightArmWeld.C1 = settings.SV_RightArmPos or settings.RightArmPos
    rightShoulder.Part1 = nil
    rightShoulder.Enabled = false

    local leftArmWeld = Instance.new("Motor6D")
    leftArmWeld.Name = "LAW"
    leftArmWeld.Part0 = animBase
    leftArmWeld.Part1 = leftArm
    leftArmWeld.Parent = animBase
    leftArmWeld.C1 = settings.SV_LeftArmPos or settings.LeftArmPos
    leftShoulder.Part1 = nil
    leftShoulder.Enabled = false

    serverGun.Parent = character

    -- OPTIMIZATION: Efficient gun part welding
    for _, part in pairs(serverGun:GetChildren()) do
        if part:IsA("BasePart") and part.Name ~= "Grip" then
            if part.Name == "Bolt" or part.Name == "Slide" then
                local boltHinge = serverGun:FindFirstChild("BoltHinge")
                if boltHinge then
                    if not (boltHinge:FindFirstChild("BoltOnly") and part.Name == "Slide") then
                        Utils.WeldComplex(boltHinge, part, grip)
                    end
                else
                    Utils.WeldComplex(grip, part, grip)
                end
            elseif part.Name == "Lid" then
                local lidHinge = serverGun:FindFirstChild('LidHinge')
                if lidHinge then
                    Utils.Weld(lidHinge, part, part)
                else
                    Utils.Weld(grip, part, part)
                end
            elseif part:FindFirstChild("HingeMotor") then
                local hinge = part.HingeMotor.Value
                Utils.Weld(hinge, part, part)
            else
                Utils.Weld(grip, part, part)
            end
        end
    end

    -- Create grip weld
    local gripW = Instance.new('Motor6D')
    gripW.Name = 'GripW'
    gripW.Parent = grip
    gripW.Part0 = fakeRightArm
    gripW.Part1 = grip
    gripW.C0 = settings.SV_GunPos or CFrame.new()
    gripW.C1 = CFrame.new()

    -- OPTIMIZATION: Batch property updates
    for _, part in pairs(serverGun:GetChildren()) do
        if part:IsA('BasePart') then
            part.Anchored = false
            part.CanCollide = false
        end
    end
end)

-- OPTIMIZATION: Memory-efficient fake arm destruction
local function DestroyFakeArm(char, armName)
    local fakeArm = char:FindFirstChild("Fake" .. armName)
    if fakeArm then
        fakeArm:Destroy()
    end
end