local autoFarm={}
autoFarm.__index=autoFarm
local player=game.Players.LocalPlayer
local runService=game:GetService("RunService")
local userInput=game:GetService("UserInputService")
local virtualUser=game:GetService("VirtualUser")
local tweenService=game:GetService("TweenService")
local workspace=game:GetService("Workspace")
local replicatedStorage=game:GetService("ReplicatedStorage")
local players=game:GetService("Players")
local collectionService=game:GetService("CollectionService")
local pathfindingService=game:GetService("PathfindingService")
local debris=game:GetService("Debris")
local httpService=game:GetService("HttpService")
local teleportService=game:GetService("TeleportService")
local character=nil local humanoid=nil local rootPart=nil local dataRef=nil
local isRunning=false local currentTarget=nil local targetList={} local collectedItems={}
local skillCooldowns={} local attackCooldown=0 local dodgeCooldown=0 local farmTimer=0
local questProgress=0 local currentSea=1 local targetSea=1
local isDoingSeaQuest=false local seaQuestCompleted=false
local questNPCs={} local currentQuestNPC=nil local questTargets={}
local bossFarmEnabled=false local currentBoss=nil local bossList={}
local SEA_1_QUESTS={
    {level=0,npc="Bandit",npcPos=Vector3.new(-100,10,0),target="Bandit",count=10,nextLevel=15},
    {level=15,npc="Gorilla",npcPos=Vector3.new(-300,20,200),target="Gorilla",count=10,nextLevel=25},
    {level=25,npc="Gorilla King",npcPos=Vector3.new(-320,25,220),target="Gorilla King",count=1,nextLevel=35,isBoss=true},
    {level=35,npc="Pirate",npcPos=Vector3.new(200,10,-100),target="Pirate",count=10,nextLevel=55},
    {level=55,npc="Bobby",npcPos=Vector3.new(250,15,-80),target="Bobby",count=1,nextLevel=65,isBoss=true},
    {level=65,npc="Galley Pirate",npcPos=Vector3.new(500,10,300),target="Galley Pirate",count=10,nextLevel=85},
    {level=85,npc="Galley Captain",npcPos=Vector3.new(520,15,320),target="Galley Captain",count=8,nextLevel=100},
    {level=100,npc="The Saw",npcPos=Vector3.new(0,10,500),target="The Saw",count=1,nextLevel=110,isBoss=true},
    {level=110,npc="Yeti",npcPos=Vector3.new(-200,15,600),target="Yeti",count=8,nextLevel=120},
    {level=120,npc="Mob Leader",npcPos=Vector3.new(-400,20,700),target="Mob Leader",count=1,nextLevel=130,isBoss=true},
    {level=130,npc="Vice Admiral",npcPos=Vector3.new(800,10,-200),target="Vice Admiral",count=1,nextLevel=150,isBoss=true},
    {level=150,npc="Marine Soldier",npcPos=Vector3.new(850,15,-180),target="Marine Soldier",count=15,nextLevel=200},
    {level=200,npc="Saber Expert",npcPos=Vector3.new(-400,20,300),target="Saber Expert",count=1,nextLevel=220,isBoss=true},
    {level=220,npc="Warden",npcPos=Vector3.new(-500,30,400),target="Warden",count=1,nextLevel=230,isBoss=true},
    {level=230,npc="Chief Warden",npcPos=Vector3.new(-480,35,420),target="Chief Warden",count=1,nextLevel=240,isBoss=true},
    {level=240,npc="Swan",npcPos=Vector3.new(-450,40,380),target="Swan",count=1,nextLevel=250,isBoss=true},
    {level=250,npc="Magma Admiral",npcPos=Vector3.new(600,10,-400),target="Magma Admiral",count=1,nextLevel=300,isBoss=true},
    {level=300,npc="Magma Ninja",npcPos=Vector3.new(620,15,-380),target="Magma Ninja",count=12,nextLevel=350},
    {level=350,npc="Magma Admiral",npcPos=Vector3.new(600,10,-400),target="Magma Admiral",count=1,nextLevel=375,isBoss=true},
    {level=375,npc="Fishman",npcPos=Vector3.new(0,-50,1000),target="Fishman",count=15,nextLevel=425},
    {level=425,npc="Fishman Lord",npcPos=Vector3.new(20,-40,1020),target="Fishman Lord",count=1,nextLevel=450,isBoss=true},
    {level=450,npc="Sky Bandit",npcPos=Vector3.new(200,200,0),target="Sky Bandit",count=15,nextLevel=500},
    {level=500,npc="Wysper",npcPos=Vector3.new(220,220,20),target="Wysper",count=1,nextLevel=550,isBoss=true},
    {level=550,npc="Sky Knight",npcPos=Vector3.new(180,250,0),target="Sky Knight",count=12,nextLevel=575},
    {level=575,npc="Thunder God",npcPos=Vector3.new(200,300,0),target="Thunder God",count=1,nextLevel=600,isBoss=true},
    {level=600,npc="Fountain Soldier",npcPos=Vector3.new(300,10,800),target="Fountain Soldier",count=15,nextLevel=675},
    {level=675,npc="Cyborg",npcPos=Vector3.new(320,15,820),target="Cyborg",count=1,nextLevel=700,isBoss=true},
    {level=700,npc="Ice Admiral",npcPos=Vector3.new(-200,15,600),target="Ice Admiral",count=1,nextLevel=700,isBoss=true,isSeaQuest=true,seaTarget=2}
}
local SEA_2_QUESTS={
    {level=700,npc="Experienced Captain",npcPos=Vector3.new(0,10,0),target="",count=0,nextLevel=700,isSeaQuest=true,seaTarget=2,isTransition=true},
    {level=725,npc="Cyborg",npcPos=Vector3.new(100,10,200),target="Cyborg",count=1,nextLevel=750,isBoss=true},
    {level=750,npc="Diamond",npcPos=Vector3.new(200,20,300),target="Diamond",count=1,nextLevel=800,isBoss=true},
    {level=800,npc="Swan Pirate",npcPos=Vector3.new(300,10,400),target="Swan Pirate",count=15,nextLevel=850},
    {level=850,npc="Jeremy",npcPos=Vector3.new(320,25,420),target="Jeremy",count=1,nextLevel=925,isBoss=true},
    {level=925,npc="Orbitus",npcPos=Vector3.new(400,10,500),target="Orbitus",count=1,nextLevel=1000,isBoss=true},
    {level=1000,npc="Don Swan",npcPos=Vector3.new(450,30,550),target="Don Swan",count=1,nextLevel=1050,isBoss=true},
    {level=1050,npc="Pirate",npcPos=Vector3.new(500,10,600),target="Pirate",count=15,nextLevel=1100},
    {level=1100,npc="Bounty Hunter",npcPos=Vector3.new(550,10,650),target="Bounty Hunter",count=15,nextLevel=1150},
    {level=1150,npc="Smoke Admiral",npcPos=Vector3.new(600,20,700),target="Smoke Admiral",count=1,nextLevel=1200,isBoss=true},
    {level=1200,npc="Ice Soldier",npcPos=Vector3.new(700,15,800),target="Ice Soldier",count=15,nextLevel=1250},
    {level=1250,npc="Ice Commander",npcPos=Vector3.new(720,20,820),target="Ice Commander",count=12,nextLevel=1300},
    {level=1300,npc="Ice Admiral",npcPos=Vector3.new(750,25,850),target="Ice Admiral",count=1,nextLevel=1400,isBoss=true},
    {level=1400,npc="Awakened Ice Admiral",npcPos=Vector3.new(800,30,900),target="Awakened Ice Admiral",count=1,nextLevel=1450,isBoss=true},
    {level=1450,npc="Tide Keeper",npcPos=Vector3.new(900,20,1000),target="Tide Keeper",count=1,nextLevel=1500,isBoss=true},
    {level=1500,npc="rip_indra",npcPos=Vector3.new(1000,40,1100),target="rip_indra",count=1,nextLevel=1500,isBoss=true,isSeaQuest=true,seaTarget=3}
}
local SEA_3_QUESTS={
    {level=1500,npc="Experienced Captain",npcPos=Vector3.new(0,10,0),target="",count=0,nextLevel=1500,isSeaQuest=true,seaTarget=3,isTransition=true},
    {level=1500,npc="Bartilo",npcPos=Vector3.new(100,10,100),target="Swan Pirate",count=50,nextLevel=1500,isSeaQuest=true,seaTarget=3,questStage=1},
    {level=1500,npc="Bartilo",npcPos=Vector3.new(100,10,100),target="Jeremy",count=1,nextLevel=1500,isSeaQuest=true,seaTarget=3,questStage=2},
    {level=1500,npc="Bartilo",npcPos=Vector3.new(100,10,100),target="",count=0,nextLevel=1500,isSeaQuest=true,seaTarget=3,questStage=3},
    {level=1500,npc="Don Swan",npcPos=Vector3.new(450,30,550),target="Don Swan",count=1,nextLevel=1500,isSeaQuest=true,seaTarget=3,isBoss=true},
    {level=1500,npc="King Red Head",npcPos=Vector3.new(200,20,200),target="rip_indra",count=1,nextLevel=1500,isSeaQuest=true,seaTarget=3,isBoss=true},
    {level=1550,npc="Stone",npcPos=Vector3.new(200,10,300),target="Stone",count=1,nextLevel=1600,isBoss=true},
    {level=1600,npc="Pirate",npcPos=Vector3.new(300,10,400),target="Pirate",count=15,nextLevel=1675},
    {level=1675,npc="Island Empress",npcPos=Vector3.new(350,20,450),target="Island Empress",count=1,nextLevel=1750,isBoss=true},
    {level=1750,npc="Kilo Admiral",npcPos=Vector3.new(400,30,500),target="Kilo Admiral",count=1,nextLevel=1800,isBoss=true},
    {level=1800,npc="Marine",npcPos=Vector3.new(450,10,550),target="Marine",count=15,nextLevel=1875},
    {level=1875,npc="Captain Elephant",npcPos=Vector3.new(500,20,600),target="Captain Elephant",count=1,nextLevel=1950,isBoss=true},
    {level=1950,npc="Beautiful Pirate",npcPos=Vector3.new(550,15,650),target="Beautiful Pirate",count=1,nextLevel=2000,isBoss=true},
    {level=2000,npc="Longma",npcPos=Vector3.new(600,25,700),target="Longma",count=1,nextLevel=2025,isBoss=true},
    {level=2025,npc="Cursed Skeleton",npcPos=Vector3.new(650,20,750),target="Cursed Skeleton",count=1,nextLevel=2050,isBoss=true},
    {level=2050,npc="Elite Pirate",npcPos=Vector3.new(700,10,800),target="Elite Pirate",count=1,nextLevel=2100,isBoss=true},
    {level=2100,npc="Cake Soldier",npcPos=Vector3.new(750,10,850),target="Cake Soldier",count=15,nextLevel=2175},
    {level=2175,npc="Cake Queen",npcPos=Vector3.new(800,20,900),target="Cake Queen",count=1,nextLevel=2250,isBoss=true},
    {level=2250,npc="Cake Prince",npcPos=Vector3.new(850,30,950),target="Cake Prince",count=1,nextLevel=2300,isBoss=true},
    {level=2300,npc="Dough King",npcPos=Vector3.new(900,40,1000),target="Dough King",count=1,nextLevel=2350,isBoss=true},
    {level=2350,npc="Soul Reaper",npcPos=Vector3.new(950,50,1050),target="Soul Reaper",count=1,nextLevel=2400,isBoss=true},
    {level=2400,npc="Terrorshark",npcPos=Vector3.new(1000,20,1100),target="Terrorshark",count=1,nextLevel=2450,isBoss=true},
    {level=2450,npc="Leviathan",npcPos=Vector3.new(1100,30,1200),target="Leviathan",count=1,nextLevel=2500,isBoss=true},
    {level=2500,npc="Raid Boss",npcPos=Vector3.new(1200,40,1300),target="Raid Boss",count=1,nextLevel=2550,isBoss=true}
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
local function getPlayerLevel()
    local lvl=player:FindFirstChild("Level")
    if lvl and lvl:IsA("NumberValue") then
        return lvl.Value
    end
    return 0
end
local function getCurrentSea()
    local sea=player:FindFirstChild("CurrentSea")
    if sea and sea:IsA("NumberValue") then
        return sea.Value
    end
    return 1
end
local function findQuestNPC(npcName)
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("Head") then
            if v.Name:lower():find(npcName:lower()) then
                return v
            end
        end
    end
    return nil
end
local function findTargets(targetName,radius)
    local targets={}
    radius=radius or 500
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("Head") then
            if v.Name~=player.Name then
                local hum=v:FindFirstChild("Humanoid")
                if hum and hum.Health>0 then
                    local dist=getDistance(rootPart.Position,v.Head.Position)
                    if dist<radius then
                        if targetName=="any" or v.Name:lower():find(targetName:lower()) then
                            table.insert(targets,{model=v,health=hum.Health,dist=dist})
                        end
                    end
                end
            end
        end
    end
    table.sort(targets,function(a,b)return a.dist<b.dist end)
    return targets
end
local function findBoss(bossName)
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("Head") then
            if v.Name~=player.Name then
                if bossName=="any" or v.Name:lower():find(bossName:lower()) then
                    if v:FindFirstChild("Humanoid").Health>0 then
                        return v
                    end
                end
            end
        end
    end
    return nil
end
local function moveToPosition(pos,timeout)
    timeout=timeout or 10
    if not rootPart then return false end
    local dist=getDistance(rootPart.Position,pos)
    if dist<5 then return true end
    local tweenInfo=TweenInfo.new(dist/40,Enum.EasingStyle.Linear)
    local tween=tweenService:Create(rootPart,tweenInfo,{CFrame=CFrame.new(pos)})
    tween:Play()
    local start=tick()
    repeat wait(0.1) until not tween.PlaybackState==Enum.PlaybackState.Playing or tick()-start>timeout
    return getDistance(rootPart.Position,pos)<10
end
local function attackTarget(target)
    if not target or not rootPart then return false end
    if attackCooldown>tick() then return false end
    local head=target:FindFirstChild("Head")
    if head then
        rootPart.CFrame=CFrame.new(head.Position+Vector3.new(0,3,0))
        wait(0.1)
        if humanoid then
            humanoid:BreakJoints()
            attackCooldown=tick()+0.3
            return true
        end
    end
    return false
end
local function useSkill(skillName)
    if skillCooldowns[skillName] and skillCooldowns[skillName]>tick() then return end
    local key=Enum.KeyCode[skillName] or Enum.KeyCode.Q
    if key then
        userInput:SetKeyDown(key)
        wait(0.05)
        userInput:SetKeyUp(key)
        skillCooldowns[skillName]=tick()+2
    end
end
local function collectItem(part)
    if not part or not rootPart then return false end
    if table.find(collectedItems,part) then return false end
    local dist=getDistance(rootPart.Position,part.Position)
    if dist<10 then
        rootPart.CFrame=CFrame.new(part.Position)
        wait(0.2)
        table.insert(collectedItems,part)
        debris:AddItem(part,0.5)
        return true
    else
        moveToPosition(part.Position,2)
        return false
    end
end
local function autoCollectAll(radius)
    local count=0
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Part") and v:FindFirstChild("TouchInterest") then
            local dist=getDistance(rootPart.Position,v.Position)
            if dist<radius then
                if collectItem(v) then count=count+1 end
            end
        end
    end
    return count
end
local function getQuestNPCForLevel(level,sea)
    if sea==1 then
        for _,q in ipairs(SEA_1_QUESTS) do
            if level>=q.level and level<q.nextLevel then
                return q
            end
        end
        return SEA_1_QUESTS[#SEA_1_QUESTS]
    elseif sea==2 then
        for _,q in ipairs(SEA_2_QUESTS) do
            if level>=q.level and level<q.nextLevel then
                return q
            end
        end
        return SEA_2_QUESTS[#SEA_2_QUESTS]
    elseif sea==3 then
        for _,q in ipairs(SEA_3_QUESTS) do
            if level>=q.level and level<q.nextLevel then
                return q
            end
        end
        return SEA_3_QUESTS[#SEA_3_QUESTS]
    end
    return nil
end
local function processSeaQuest(questData)
    if not questData then return end
    if questData.isSeaQuest then
        if questData.isTransition then
            local npc=findQuestNPC(questData.npc)
            if npc then
                moveToPosition(npc.Head.Position+Vector3.new(0,3,0),5)
                wait(0.5)
                if humanoid then
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    wait(0.3)
                end
                if questData.seaTarget==2 then
                    targetSea=2
                    print("[AutoFarm] Đang chuyển sang Sea 2...")
                elseif questData.seaTarget==3 then
                    targetSea=3
                    print("[AutoFarm] Đang chuyển sang Sea 3...")
                end
            end
            return
        end
        if questData.questStage==1 then
            local targets=findTargets("Swan Pirate",500)
            local count=0
            for _,t in ipairs(targets) do
                if attackTarget(t.model) then
                    count=count+1
                    wait(0.2)
                end
                if count>=50 then break end
            end
            if count>=50 then
                local npc=findQuestNPC("Bartilo")
                if npc then
                    moveToPosition(npc.Head.Position+Vector3.new(0,3,0),5)
                    wait(0.5)
                    if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
                end
            end
        elseif questData.questStage==2 then
            local jeremy=findBoss("Jeremy")
            if jeremy then
                attackTarget(jeremy)
            else
                local npc=findQuestNPC("Bartilo")
                if npc then
                    moveToPosition(npc.Head.Position+Vector3.new(0,3,0),5)
                end
            end
        elseif questData.questStage==3 then
            local npc=findQuestNPC("Bartilo")
            if npc then
                moveToPosition(npc.Head.Position+Vector3.new(0,3,0),5)
                wait(0.5)
                if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
                isDoingSeaQuest=false
                seaQuestCompleted=true
                print("[AutoFarm] Đã hoàn thành Colosseum Quest!")
            end
        end
    end
end
local function processFarm(data)
    if not rootPart or not humanoid then updateCharacter() end
    if not rootPart or not humanoid then return end
    local currentLevel=getPlayerLevel()
    local currentSea=getCurrentSea()
    if targetSea>currentSea and currentSea<targetSea then
        local questData=getQuestNPCForLevel(currentLevel,currentSea)
        if questData and questData.isSeaQuest then
            processSeaQuest(questData)
        end
        return
    end
    local questData=getQuestNPCForLevel(currentLevel,currentSea)
    if not questData then return end
    if questData.isSeaQuest and not seaQuestCompleted then
        processSeaQuest(questData)
        return
    end
    if bossFarmEnabled and questData.isBoss then
        local boss=findBoss(questData.target)
        if boss then
            currentBoss=boss
            attackTarget(boss)
            wait(0.3)
            if boss:FindFirstChild("Humanoid") and boss.Humanoid.Health<=0 then
                currentBoss=nil
                print("[AutoFarm] Đã tiêu diệt boss: "..questData.target)
            end
        else
            local npc=findQuestNPC(questData.npc)
            if npc then
                moveToPosition(npc.Head.Position+Vector3.new(0,3,0),5)
                wait(0.5)
                if humanoid then
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    wait(0.3)
                end
            end
        end
        return
    end
    local targets=findTargets(questData.target,data.radius or 500)
    if #targets>0 then
        for _,t in ipairs(targets) do
            if attackTarget(t.model) then
                wait(0.2)
                if data.useSkill then
                    useSkill("Q")
                    useSkill("E")
                    useSkill("R")
                end
                if data.collectItems then
                    autoCollectAll(100)
                end
                break
            end
        end
    else
        local npc=findQuestNPC(questData.npc)
        if npc then
            moveToPosition(npc.Head.Position+Vector3.new(0,3,0),5)
            wait(0.5)
            if humanoid then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                wait(0.3)
            end
        end
    end
    if data.autoQuest and not isDoingSeaQuest then
        local npc=findQuestNPC(questData.npc)
        if npc then
            moveToPosition(npc.Head.Position+Vector3.new(0,3,0),5)
            wait(0.5)
        end
    end
end
local function startFarm(data)
    if isRunning then return end
    isRunning=true
    updateCharacter()
    targetSea=getCurrentSea()
    seaQuestCompleted=false
    isDoingSeaQuest=false
    task.spawn(function()
        while isRunning do
            wait(0.1)
            pcall(function()processFarm(data)end)
        end
    end)
    return true
end
function autoFarm.Stop()
    isRunning=false
    currentTarget=nil
    currentBoss=nil
    return true
end
function autoFarm.Run(data)
    if not data then return false end
    dataRef=data
    if not data.enabled then
        if isRunning then autoFarm.Stop() end
        return false
    end
    if not isRunning then
        return startFarm(data)
    else
        dataRef=data
        return true
    end
end
function autoFarm.SetTargetType(targetType)
    if dataRef then dataRef.targetType=targetType end
    return true
end
function autoFarm.SetRadius(radius)
    if dataRef then dataRef.radius=radius end
    return true
end
function autoFarm.SetSpeed(speed)
    if dataRef then dataRef.speed=speed end
    return true
end
function autoFarm.ToggleSkill()
    if dataRef then dataRef.useSkill=not dataRef.useSkill end
    return dataRef and dataRef.useSkill or false
end
function autoFarm.ToggleCollect()
    if dataRef then dataRef.collectItems=not dataRef.collectItems end
    return dataRef and dataRef.collectItems or false
end
function autoFarm.ToggleQuest()
    if dataRef then dataRef.autoQuest=not dataRef.autoQuest end
    return dataRef and dataRef.autoQuest or false
end
function autoFarm.ToggleBossFarm()
    bossFarmEnabled=not bossFarmEnabled
    return bossFarmEnabled
end
function autoFarm.GetStatus()
    return{
        isRunning=isRunning,
        currentTarget=currentTarget and currentTarget.Name or "None",
        currentBoss=currentBoss and currentBoss.Name or "None",
        currentLevel=getPlayerLevel(),
        currentSea=getCurrentSea(),
        targetSea=targetSea,
        seaQuestCompleted=seaQuestCompleted,
        bossFarmEnabled=bossFarmEnabled,
        questProgress=questProgress
    }
end
function autoFarm.GetQuestsForSea(sea)
    if sea==1 then return SEA_1_QUESTS
    elseif sea==2 then return SEA_2_QUESTS
    elseif sea==3 then return SEA_3_QUESTS end
    return {}
end
function autoFarm.FindBoss(bossName)
    return findBoss(bossName)
end
function autoFarm.FindNPC(npcName)
    return findQuestNPC(npcName)
end
function autoFarm.MoveToNPC(npcName)
    local npc=findQuestNPC(npcName)
    if npc then
        return moveToPosition(npc.Head.Position+Vector3.new(0,3,0),5)
    end
    return false
end
function autoFarm.MoveToBoss(bossName)
    local boss=findBoss(bossName)
    if boss then
        return moveToPosition(boss.Head.Position+Vector3.new(0,5,0),5)
    end
    return false
end
function autoFarm.GetAllBosses()
    local bosses={}
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("Head") then
            if v.Name~=player.Name and v:FindFirstChild("IsBoss") then
                table.insert(bosses,v.Name)
            end
        end
    end
    return bosses
end
function autoFarm.GetAllNPCs()
    local npcs={}
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("Head") then
            if v.Name~=player.Name and v:FindFirstChild("IsNPC") then
                table.insert(npcs,v.Name)
            end
        end
    end
    return npcs
end
function autoFarm.SetBossFarmTarget(bossName)
    if dataRef then dataRef.bossTarget=bossName end
    return true
end
function autoFarm.Pause()
    isRunning=false
    return true
end
function autoFarm.Resume()
    if dataRef and dataRef.enabled then
        isRunning=true
        startFarm(dataRef)
        return true
    end
    return false
end
function autoFarm.Destroy()
    autoFarm.Stop()
    dataRef=nil
    currentBoss=nil
    collectedItems={}
    return true
end
function autoFarm.Initialize(data)
    dataRef=data
    updateCharacter()
    bossFarmEnabled=data and data.bossFarmEnabled or false
    targetSea=getCurrentSea()
    return true
end
return autoFarm
