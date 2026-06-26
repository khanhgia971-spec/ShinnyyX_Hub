local combat={}
combat.__index=combat
local player=game.Players.LocalPlayer
local runService=game:GetService("RunService")
local userInput=game:GetService("UserInputService")
local workspace=game:GetService("Workspace")
local players=game:GetService("Players")
local tweenService=game:GetService("TweenService")
local debris=game:GetService("Debris")
local collectionService=game:GetService("CollectionService")
local replicatedStorage=game:GetService("ReplicatedStorage")
local character=nil local humanoid=nil local rootPart=nil
local dataRef=nil local isRunning=false
local currentTarget=nil local attackCooldown=0 local dodgeCooldown=0
local skillCooldowns={} local comboStep=0 local comboList={}
local lastAttackTime=0 local dodgeDirection=Vector3.new(1,0,0)
local targetList={} local damageDealt=0 local kills=0
local skills={
    Q={name="Q",cooldown=2,damage=50,range=15,type="melee"},
    E={name="E",cooldown=3,damage=80,range=20,type="melee"},
    R={name="R",cooldown=5,damage=120,range=25,type="aoe"},
    T={name="T",cooldown=4,damage=100,range=30,type="projectile"},
    Y={name="Y",cooldown=6,damage=150,range=20,type="aoe"}
}
local comboPresets={
    Basic={"Q","E","R"},
    Advanced={"Q","E","R","T","Y"},
    Burst={"R","T","Y","Q","E"},
    LongRange={"T","Y","R","Q","E"}
}
local function updateCharacter()
    character=player.Character or player.CharacterAdded:Wait()
    if character then
        humanoid=character:FindFirstChild("Humanoid")
        rootPart=character:FindFirstChild("HumanoidRootPart")
    end
end
local function getDistance(pos1,pos2)
    if not pos1 or not pos2 then return math.huge end
    return (pos1-pos2).Magnitude
end
local function findTargets(radius,priority)
    radius=radius or 100
    priority=priority or "LowestHealth"
    local targets={}
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("Head") then
            if v.Name~=player.Name then
                local human=v.Humanoid
                if human.Health>0 then
                    local dist=getDistance(rootPart.Position,v.Head.Position)
                    if dist<radius then
                        local level=1
                        local lvl=v:FindFirstChild("Level")
                        if lvl and lvl:IsA("NumberValue") then level=lvl.Value end
                        table.insert(targets,{model=v,health=human.Health,maxHealth=human.MaxHealth,dist=dist,level=level})
                    end
                end
            end
        end
    end
    if priority=="LowestHealth" then
        table.sort(targets,function(a,b)return a.health/a.maxHealth<b.health/b.maxHealth end)
    elseif priority=="Nearest" then
        table.sort(targets,function(a,b)return a.dist<b.dist end)
    elseif priority=="HighestLevel" then
        table.sort(targets,function(a,b)return a.level>b.level end)
    elseif priority=="LowestLevel" then
        table.sort(targets,function(a,b)return a.level<b.level end)
    elseif priority=="HighestHealth" then
        table.sort(targets,function(a,b)return a.health>b.health end)
    end
    return targets
end
local function getBestTarget(data)
    local priority=data.targetPriority or "LowestHealth"
    local radius=data.radius or 100
    local targets=findTargets(radius,priority)
    if #targets>0 then
        return targets[1].model
    end
    return nil
end
local function moveToTarget(target,heightOffset)
    heightOffset=heightOffset or 5
    if not target or not rootPart then return false end
    local head=target:FindFirstChild("Head")
    if not head then return false end
    local targetPos=head.Position+Vector3.new(0,heightOffset,0)
    local dist=getDistance(rootPart.Position,targetPos)
    if dist>10 then
        local tweenInfo=TweenInfo.new(dist/80,Enum.EasingStyle.Linear)
        local tween=tweenService:Create(rootPart,tweenInfo,{CFrame=CFrame.new(targetPos)})
        tween:Play()
        return true
    end
    return false
end
local function attackTarget(target,data)
    if not target or not rootPart then return false end
    if attackCooldown>tick() then return false end
    local head=target:FindFirstChild("Head")
    if not head then return false end
    local dist=getDistance(rootPart.Position,head.Position)
    if dist>data.attackRange or data.attackRange==nil then
        if dist>15 then
            moveToTarget(target,5)
            return false
        end
    end
    rootPart.CFrame=CFrame.new(head.Position+Vector3.new(0,3,0))
    wait(0.05)
    if humanoid then
        humanoid:BreakJoints()
        attackCooldown=tick()+0.3
        lastAttackTime=tick()
        damageDealt=damageDealt+data.damageMultiplier or 1
        return true
    end
    return false
end
local function useSkill(skillName,data)
    if skillCooldowns[skillName] and skillCooldowns[skillName]>tick() then return false end
    local skill=skills[skillName]
    if not skill then return false end
    if currentTarget then
        local head=currentTarget:FindFirstChild("Head")
        if head then
            local dist=getDistance(rootPart.Position,head.Position)
            if dist<skill.range then
                rootPart.CFrame=CFrame.new(head.Position+Vector3.new(0,5,0))
            end
        end
    end
    local key=Enum.KeyCode[skillName]
    if key then
        userInput:SetKeyDown(key)
        wait(0.05)
        userInput:SetKeyUp(key)
        skillCooldowns[skillName]=tick()+skill.cooldown
        return true
    end
    return false
end
local function dodgeAttack(data)
    if dodgeCooldown>tick() then return false end
    if not rootPart then return false end
    local dodgeSpeed=data.dodgeSpeed or 50
    local directions={Vector3.new(1,0,0),Vector3.new(-1,0,0),Vector3.new(0,0,1),Vector3.new(0,0,-1)}
    local dir=directions[math.random(1,#directions)]
    rootPart.Velocity=dir*dodgeSpeed
    dodgeCooldown=tick()+0.5
    return true
end
local function performCombo(data)
    if not data.comboEnabled then return end
    local comboType=data.comboType or "Basic"
    local combo=comboPresets[comboType] or comboPresets.Basic
    if comboStep>#combo then
        comboStep=1
    end
    local skillName=combo[comboStep]
    if useSkill(skillName,data) then
        comboStep=comboStep+1
    end
end
local function checkEnemyAttack()
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v.Name~=player.Name then
            if v:FindFirstChild("AttackPart") then
                local dist=getDistance(rootPart.Position,v.AttackPart.Position)
                if dist<10 then
                    return true
                end
            end
        end
    end
    return false
end
local function processCombat(data)
    if not rootPart or not humanoid then updateCharacter() end
    if not rootPart or not humanoid then return end
    local autoAttack=data.autoAttack or false
    local autoDodge=data.autoDodge or false
    local spamSkill=data.spamSkill or false
    local skillKey=data.skillKey or "Q"
    local hitboxMultiplier=data.hitboxMultiplier or 1
    local damageMultiplier=data.damageMultiplier or 1
    local targetPriority=data.targetPriority or "LowestHealth"
    local radius=data.radius or 100
    if not currentTarget or not currentTarget.Parent then
        currentTarget=getBestTarget(data)
        if not currentTarget then return end
    end
    if currentTarget and currentTarget:FindFirstChild("Humanoid") then
        local health=currentTarget.Humanoid.Health
        if health<=0 then
            kills=kills+1
            currentTarget=getBestTarget(data)
            if not currentTarget then return end
        end
    else
        currentTarget=getBestTarget(data)
        if not currentTarget then return end
    end
    if autoDodge then
        if checkEnemyAttack() then
            dodgeAttack(data)
        end
    end
    if spamSkill then
        if data.comboEnabled then
            performCombo(data)
        else
            useSkill(skillKey,data)
        end
    end
    if autoAttack then
        attackTarget(currentTarget,data)
    end
end
local function startCombatLoop(data)
    if isRunning then return end
    isRunning=true
    task.spawn(function()
        while isRunning do
            wait(0.1)
            pcall(function()processCombat(data)end)
        end
    end)
end
function combat.Stop()
    isRunning=false
    currentTarget=nil
    comboStep=0
    return true
end
function combat.Run(data)
    if not data then return false end
    dataRef=data
    if not data.autoAttack and not data.spamSkill then
        if isRunning then combat.Stop() end
        return false
    end
    if not isRunning then
        startCombatLoop(data)
    end
    return true
end
function combat.SetTarget(target)
    currentTarget=target
    return true
end
function combat.SetPriority(priority)
    if dataRef then dataRef.targetPriority=priority return true end
    return false
end
function combat.SetRadius(radius)
    if dataRef then dataRef.radius=radius return true end
    return false
end
function combat.ToggleAutoAttack()
    if dataRef then dataRef.autoAttack=not dataRef.autoAttack return dataRef.autoAttack end
    return false
end
function combat.ToggleAutoDodge()
    if dataRef then dataRef.autoDodge=not dataRef.autoDodge return dataRef.autoDodge end
    return false
end
function combat.ToggleSpamSkill()
    if dataRef then dataRef.spamSkill=not dataRef.spamSkill return dataRef.spamSkill end
    return false
end
function combat.SetSkillKey(key)
    if dataRef then dataRef.skillKey=key return true end
    return false
end
function combat.SetDamageMultiplier(mult)
    if dataRef then dataRef.damageMultiplier=mult return true end
    return false
end
function combat.SetHitboxMultiplier(mult)
    if dataRef then dataRef.hitboxMultiplier=mult return true end
    return false
end
function combat.GetStatus()
    return{
        isRunning=isRunning,
        currentTarget=currentTarget and currentTarget.Name or "None",
        attackCooldown=attackCooldown-tick(),
        dodgeCooldown=dodgeCooldown-tick(),
        damageDealt=damageDealt,
        kills=kills,
        comboStep=comboStep
    }
end
function combat.GetTargets(radius,priority)
    return findTargets(radius,priority)
end
function combat.GetBestTarget()
    if dataRef then return getBestTarget(dataRef) end
    return nil
end
function combat.UseSkill(skillName)
    if dataRef then return useSkill(skillName,dataRef) end
    return false
end
function combat.Dodge()
    if dataRef then return dodgeAttack(dataRef) end
    return false
end
function combat.SetComboType(comboType)
    if dataRef then
        dataRef.comboType=comboType
        dataRef.comboEnabled=true
        comboStep=0
        return true
    end
    return false
end
function combat.ToggleCombo()
    if dataRef then
        dataRef.comboEnabled=not dataRef.comboEnabled
        return dataRef.comboEnabled
    end
    return false
end
function combat.GetComboList()
    return comboPresets
end
function combat.CreateCustomCombo(skills)
    comboPresets.Custom=skills
    return true
end
function combat.GetSkillInfo(skillName)
    return skills[skillName]
end
function combat.SetSkillCooldown(skillName,cooldown)
    if skills[skillName] then
        skills[skillName].cooldown=cooldown
        return true
    end
    return false
end
function combat.GetNearestEnemy()
    local targets=findTargets(1000,"Nearest")
    if #targets>0 then return targets[1].model end
    return nil
end
function combat.GetLowestHealthEnemy()
    local targets=findTargets(1000,"LowestHealth")
    if #targets>0 then return targets[1].model end
    return nil
end
function combat.GetHighestLevelEnemy()
    local targets=findTargets(1000,"HighestLevel")
    if #targets>0 then return targets[1].model end
    return nil
end
function combat.ResetStats()
    damageDealt=0
    kills=0
    return true
end
function combat.SetAutoAim(bool)
    if dataRef then
        dataRef.autoAim=bool
        return true
    end
    return false
end
function combat.Pause()
    isRunning=false
    return true
end
function combat.Resume()
    if dataRef and (dataRef.autoAttack or dataRef.spamSkill) then
        isRunning=true
        startCombatLoop(dataRef)
        return true
    end
    return false
end
function combat.Destroy()
    isRunning=false
    currentTarget=nil
    dataRef=nil
    comboStep=0
    damageDealt=0
    kills=0
    return true
end
function combat.Initialize(data)
    dataRef=data
    updateCharacter()
    userInput.InputBegan:Connect(function(input,gameProcessed)
        if gameProcessed then return end
        if input.KeyCode==Enum.KeyCode.G then
            if dataRef then dataRef.autoAttack=not dataRef.autoAttack end
        end
        if input.KeyCode==Enum.KeyCode.H then
            if dataRef then dataRef.autoDodge=not dataRef.autoDodge end
        end
        if input.KeyCode==Enum.KeyCode.J then
            if dataRef then dataRef.spamSkill=not dataRef.spamSkill end
        end
    end)
    return true
end
return combat
