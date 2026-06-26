lib/AutoFarm.lua
```lua
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
local teleportCooldown=0 local healCooldown=0
local autoBuyEnabled=false local autoBuyTimer=0
local autoStatsEnabled=false local statTimer=0
local raidAutoEnabled=false local raidTimer=0
local seaEventAutoEnabled=false local seaEventTimer=0
local fruitNotifierEnabled=false local fruitList={}
local autoBountyEnabled=false local bountyTimer=0
local autoPvpEnabled=false local pvpTimer=0
local antiAFKEnabled=true local antiAFKTimer=0
local autoCollectEnabled=true local collectTimer=0
local autoSkillEnabled=true local skillTimer=0
local autoHealEnabled=false local healThreshold=30
local autoTeleportToBoss=false
local mobKillCount=0 local bossKillCount=0
local expPerHour=0 local lastExpCheck=0 local lastExpValue=0
local SEA_1_QUESTS={
    {level=0,npc="Bandit Quest Giver",npcPos=Vector3.new(-100,10,0),target="Bandit",count=5,nextLevel=10,exp=350},
    {level=0,npc="Marine Quest Giver",npcPos=Vector3.new(100,10,0),target="Trainee",count=5,nextLevel=10,exp=350},
    {level=10,npc="Monkey Quest Giver",npcPos=Vector3.new(-300,20,200),target="Monkey",count=6,nextLevel=15,exp=800},
    {level=15,npc="Gorilla Quest Giver",npcPos=Vector3.new(-300,20,200),target="Gorilla",count=8,nextLevel=20,exp=1200},
    {level=20,npc="Gorilla King",npcPos=Vector3.new(-320,25,220),target="Gorilla King",count=1,nextLevel=30,exp=2000,isBoss=true},
    {level=30,npc="Pirate Quest Giver",npcPos=Vector3.new(200,10,-100),target="Pirate",count=8,nextLevel=40,exp=3000},
    {level=40,npc="Brute Quest Giver",npcPos=Vector3.new(250,15,-80),target="Brute",count=8,nextLevel=55,exp=3500},
    {level=55,npc="Bobby The Clown",npcPos=Vector3.new(250,15,-80),target="Bobby",count=1,nextLevel=60,exp=8000,isBoss=true},
    {level=60,npc="Galley Pirate Quest Giver",npcPos=Vector3.new(500,10,300),target="Galley Pirate",count=8,nextLevel=75,exp=4000},
    {level=75,npc="Galley Captain",npcPos=Vector3.new(520,15,320),target="Galley Captain",count=8,nextLevel=85,exp=5000},
    {level=85,npc="The Saw",npcPos=Vector3.new(0,10,500),target="The Saw",count=1,nextLevel=95,exp=10000,isBoss=true},
    {level=95,npc="Yeti Quest Giver",npcPos=Vector3.new(-200,15,600),target="Yeti",count=8,nextLevel=110,exp=6000},
    {level=110,npc="Mob Leader",npcPos=Vector3.new(-400,20,700),target="Mob Leader",count=1,nextLevel=120,exp=15000,isBoss=true},
    {level=120,npc="Chief Petty Officer",npcPos=Vector3.new(800,10,-200),target="Chief Petty Officer",count=8,nextLevel=130,exp=6000},
    {level=130,npc="Vice Admiral",npcPos=Vector3.new(800,10,-200),target="Vice Admiral",count=1,nextLevel=150,exp=18000,isBoss=true},
    {level=150,npc="Marine Soldier",npcPos=Vector3.new(850,15,-180),target="Marine Soldier",count=8,nextLevel=175,exp=7000},
    {level=175,npc="Saber Expert",npcPos=Vector3.new(-400,20,300),target="Saber Expert",count=1,nextLevel=190,exp=20000,isBoss=true},
    {level=190,npc="Warden",npcPos=Vector3.new(-500,30,400),target="Warden",count=1,nextLevel=200,exp=22000,isBoss=true},
    {level=200,npc="Chief Warden",npcPos=Vector3.new(-480,35,420),target="Chief Warden",count=1,nextLevel=210,exp=25000,isBoss=true},
    {level=210,npc="Swan",npcPos=Vector3.new(-450,40,380),target="Swan",count=1,nextLevel=225,exp=28000,isBoss=true},
    {level=225,npc="Toga Warrior",npcPos=Vector3.new(600,10,-400),target="Toga Warrior",count=7,nextLevel=250,exp=7000},
    {level=250,npc="Magma Ninja",npcPos=Vector3.new(620,15,-380),target="Magma Ninja",count=8,nextLevel=275,exp=8000},
    {level=275,npc="Magma Admiral",npcPos=Vector3.new(600,10,-400),target="Magma Admiral",count=1,nextLevel=300,exp=30000,isBoss=true},
    {level=300,npc="Fishman",npcPos=Vector3.new(0,-50,1000),target="Fishman",count=8,nextLevel=350,exp=9000},
    {level=350,npc="Fishman Lord",npcPos=Vector3.new(20,-40,1020),target="Fishman Lord",count=1,nextLevel=375,exp=35000,isBoss=true},
    {level=375,npc="Sky Bandit",npcPos=Vector3.new(200,200,0),target="Sky Bandit",count=8,nextLevel=425,exp=10000},
    {level=425,npc="Wysper",npcPos=Vector3.new(220,220,20),target="Wysper",count=1,nextLevel=450,exp=40000,isBoss=true},
    {level=450,npc="Sky Knight",npcPos=Vector3.new(180,250,0),target="Sky Knight",count=8,nextLevel=475,exp=11000},
    {level=475,npc="Thunder God",npcPos=Vector3.new(200,300,0),target="Thunder God",count=1,nextLevel=500,exp=45000,isBoss=true},
    {level=500,npc="Fountain Soldier",npcPos=Vector3.new(300,10,800),target="Fountain Soldier",count=8,nextLevel=550,exp=12000},
    {level=550,npc="Cyborg",npcPos=Vector3.new(320,15,820),target="Cyborg",count=1,nextLevel=600,exp=50000,isBoss=true},
    {level=600,npc="Ice Admiral",npcPos=Vector3.new(-200,15,600),target="Ice Admiral",count=1,nextLevel=700,exp=60000,isBoss=true,isSeaQuest=true,seaTarget=2}
}
local SEA_2_QUESTS={
    {level=700,npc="Experienced Captain",npcPos=Vector3.new(0,10,0),target="",count=0,nextLevel=700,isSeaQuest=true,seaTarget=2,isTransition=true},
    {level=700,npc="Diamond",npcPos=Vector3.new(200,20,300),target="Diamond",count=1,nextLevel=750,exp=100000,isBoss=true},
    {level=750,npc="Jeremy",npcPos=Vector3.new(320,25,420),target="Jeremy",count=1,nextLevel=800,exp=250000,isBoss=true},
    {level=800,npc="Swan Pirate",npcPos=Vector3.new(300,10,400),target="Swan Pirate",count=8,nextLevel=850,exp=20000},
    {level=850,npc="Orbitus",npcPos=Vector3.new(400,10,500),target="Orbitus",count=1,nextLevel=925,exp=300000,isBoss=true},
    {level=925,npc="Don Swan",npcPos=Vector3.new(450,30,550),target="Don Swan",count=1,nextLevel=1000,exp=800000,isBoss=true},
    {level=1000,npc="Pirate",npcPos=Vector3.new(500,10,600),target="Pirate",count=8,nextLevel=1050,exp=25000},
    {level=1050,npc="Bounty Hunter",npcPos=Vector3.new(550,10,650),target="Bounty Hunter",count=8,nextLevel=1100,exp=28000},
    {level=1100,npc="Smoke Admiral",npcPos=Vector3.new(600,20,700),target="Smoke Admiral",count=1,nextLevel=1150,exp=800000,isBoss=true},
    {level=1150,npc="Ice Soldier",npcPos=Vector3.new(700,15,800),target="Ice Soldier",count=8,nextLevel=1200,exp=30000},
    {level=1200,npc="Ice Commander",npcPos=Vector3.new(720,20,820),target="Ice Commander",count=8,nextLevel=1250,exp=32000},
    {level=1250,npc="Awakened Ice Admiral",npcPos=Vector3.new(800,30,900),target="Awakened Ice Admiral",count=1,nextLevel=1400,exp=900000,isBoss=true},
    {level=1400,npc="Tide Keeper",npcPos=Vector3.new(900,20,1000),target="Tide Keeper",count=1,nextLevel=1475,exp=900000,isBoss=true},
    {level=1475,npc="rip_indra",npcPos=Vector3.new(1000,40,1100),target="rip_indra",count=1,nextLevel=1500,exp=1,isBoss=true,isSeaQuest=true,seaTarget=3}
}
local SEA_3_QUESTS={
    {level=1500,npc="Experienced Captain",npcPos=Vector3.new(0,10,0),target="",count=0,nextLevel=1500,isSeaQuest=true,seaTarget=3,isTransition=true},
    {level=1500,npc="Bartilo",npcPos=Vector3.new(100,10,100),target="Swan Pirate",count=50,nextLevel=1500,isSeaQuest=true,seaTarget=3,questStage=1},
    {level=1500,npc="Bartilo",npcPos=Vector3.new(100,10,100),target="Jeremy",count=1,nextLevel=1500,isSeaQuest=true,seaTarget=3,questStage=2},
    {level=1500,npc="Bartilo",npcPos=Vector3.new(100,10,100),target="",count=0,nextLevel=1500,isSeaQuest=true,seaTarget=3,questStage=3},
    {level=1500,npc="Don Swan",npcPos=Vector3.new(450,30,550),target="Don Swan",count=1,nextLevel=1500,isSeaQuest=true,seaTarget=3,isBoss=true},
    {level=1500,npc="King Red Head",npcPos=Vector3.new(200,20,200),target="rip_indra",count=1,nextLevel=1500,isSeaQuest=true,seaTarget=3,isBoss=true},
    {level=1500,npc="Stone",npcPos=Vector3.new(200,10,300),target="Stone",count=1,nextLevel=1550,exp=900000,isBoss=true},
    {level=1550,npc="Pirate",npcPos=Vector3.new(300,10,400),target="Pirate",count=8,nextLevel=1600,exp=40000},
    {level=1600,npc="Hydra Leader",npcPos=Vector3.new(350,20,450),target="Hydra Leader",count=1,nextLevel=1675,exp=1000000,isBoss=true},
    {level=1675,npc="Kilo Admiral",npcPos=Vector3.new(400,30,500),target="Kilo Admiral",count=1,nextLevel=1750,exp=1000000,isBoss=true},
    {level=1750,npc="Marine",npcPos=Vector3.new(450,10,550),target="Marine",count=8,nextLevel=1825,exp=45000},
    {level=1825,npc="Captain Elephant",npcPos=Vector3.new(500,20,600),target="Captain Elephant",count=1,nextLevel=1875,exp=1135000,isBoss=true},
    {level=1875,npc="Beautiful Pirate",npcPos=Vector3.new(550,15,650),target="Beautiful Pirate",count=1,nextLevel=1950,exp=1400000,isBoss=true},
    {level=1950,npc="Longma",npcPos=Vector3.new(600,25,700),target="Longma",count=1,nextLevel=2000,exp=1500000,isBoss=true},
    {level=2000,npc="Cursed Skeleton",npcPos=Vector3.new(650,20,750),target="Cursed Skeleton",count=1,nextLevel=2050,exp=1600000,isBoss=true},
    {level=2050,npc="Elite Pirate",npcPos=Vector3.new(700,10,800),target="Elite Pirate",count=1,nextLevel=2100,exp=1700000,isBoss=true},
    {level=2100,npc="Cake Soldier",npcPos=Vector3.new(750,10,850),target="Cake Soldier",count=8,nextLevel=2175,exp=50000},
    {level=2175,npc="Cake Queen",npcPos=Vector3.new(800,20,900),target="Cake Queen",count=1,nextLevel=2250,exp=1800000,isBoss=true},
    {level=2250,npc="Cake Prince",npcPos=Vector3.new(850,30,950),target="Cake Prince",count=1,nextLevel=2300,exp=1900000,isBoss=true},
    {level=2300,npc="Dough King",npcPos=Vector3.new(900,40,1000),target="Dough King",count=1,nextLevel=2350,exp=2000000,isBoss=true},
    {level=2350,npc="Soul Reaper",npcPos=Vector3.new(950,50,1050),target="Soul Reaper",count=1,nextLevel=2400,exp=2100000,isBoss=true},
    {level=2400,npc="Terrorshark",npcPos=Vector3.new(1000,20,1100),target="Terrorshark",count=1,nextLevel=2450,exp=2200000,isBoss=true},
    {level=2450,npc="Leviathan",npcPos=Vector3.new(1100,30,1200),target="Leviathan",count=1,nextLevel=2500,exp=3000000,isBoss=true},
    {level=2500,npc="Raid Boss",npcPos=Vector3.new(1200,40,1300),target="Raid Boss",count=1,nextLevel=2550,exp=3500000,isBoss=true}
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
    if lvl and lvl:IsA("NumberValue") then return lvl.Value end
    return 0
end
local function getCurrentSea()
    local sea=player:FindFirstChild("CurrentSea")
    if sea and sea:IsA("NumberValue") then return sea.Value end
    return 1
end
local function getPlayerExp()
    local exp=player:FindFirstChild("Exp")
    if exp and exp:IsA("NumberValue") then return exp.Value end
    return 0
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
            mobKillCount=mobKillCount+1
            if target:FindFirstChild("IsBoss") then
                bossKillCount=bossKillCount+1
            end
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
local function useSkillCombo()
    if autoSkillEnabled then
        useSkill("Q")
        wait(0.1)
        useSkill("E")
        wait(0.1)
        useSkill("R")
        wait(0.1)
        useSkill("T")
        wait(0.1)
        useSkill("Y")
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
    if not autoCollectEnabled then return 0 end
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
local function autoHeal()
    if not autoHealEnabled then return end
    if healCooldown>tick() then return end
    if humanoid and humanoid.Health<humanoid.MaxHealth*(healThreshold/100) then
        local fruit=player:FindFirstChild("Fruit")
        if fruit and fruit:IsA("StringValue") and fruit.Value~="None" then
            userInput:SetKeyDown(Enum.KeyCode.Z)
            wait(0.05)
            userInput:SetKeyUp(Enum.KeyCode.Z)
            healCooldown=tick()+5
        end
    end
end
local function autoBuy()
    if not autoBuyEnabled then return end
    if autoBuyTimer>tick() then return end
    local money=player:FindFirstChild("Money")
    if money and money:IsA("NumberValue") and money.Value>1000 then
        local shop=workspace:FindFirstChild("Shop")
        if shop then
            moveToPosition(shop.Position+Vector3.new(0,2,0),3)
            wait(0.5)
            if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end
    autoBuyTimer=tick()+60
end
local function autoAssignStats()
    if not autoStatsEnabled then return end
    if statTimer>tick() then return end
    local sp=player:FindFirstChild("StatPoints")
    if sp and sp:IsA("NumberValue") and sp.Value>0 then
        local stats={"Melee","Defense","Sword","Gun","Fruit"}
        local minStat=stats[1]
        local minVal=math.huge
        for _,name in ipairs(stats) do
            local s=player:FindFirstChild(name)
            if s and s:IsA("NumberValue") and s.Value<minVal then
                minVal=s.Value
                minStat=name
            end
        end
        local stat=player:FindFirstChild(minStat)
        if stat and stat:IsA("NumberValue") then
            stat.Value=stat.Value+sp.Value
            sp.Value=0
        end
    end
    statTimer=tick()+1
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
                    useSkillCombo()
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
                useSkillCombo()
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
    autoHeal()
    autoCollectAll(data.radius or 500)
    if bossFarmEnabled and questData.isBoss then
        local boss=findBoss(questData.target)
        if boss then
            currentBoss=boss
            attackTarget(boss)
            useSkillCombo()
            wait(0.3)
            if boss:FindFirstChild("Humanoid") and boss.Humanoid.Health<=0 then
                currentBoss=nil
                bossKillCount=bossKillCount+1
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
                if data.useSkill or autoSkillEnabled then
                    useSkillCombo()
                end
                if data.collectItems or autoCollectEnabled then
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
    autoBuy()
    autoAssignStats()
    if autoCollectEnabled then
        autoCollectAll(200)
    end
end
local function startFarm(data)
    if isRunning then return end
    isRunning=true
    updateCharacter()
    targetSea=getCurrentSea()
    seaQuestCompleted=false
    isDoingSeaQuest=false
    lastExpValue=getPlayerExp()
    lastExpCheck=tick()
    task.spawn(function()
        while isRunning do
            wait(0.1)
            pcall(function()processFarm(data)end)
            local currentExp=getPlayerExp()
            local elapsed=(tick()-lastExpCheck)/3600
            if elapsed>0 then
                expPerHour=(currentExp-lastExpValue)/elapsed
            end
            if tick()-lastExpCheck>60 then
                lastExpValue=currentExp
                lastExpCheck=tick()
            end
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
    autoSkillEnabled=dataRef and dataRef.useSkill or false
    return autoSkillEnabled
end
function autoFarm.ToggleCollect()
    if dataRef then dataRef.collectItems=not dataRef.collectItems end
    autoCollectEnabled=dataRef and dataRef.collectItems or false
    return autoCollectEnabled
end
function autoFarm.ToggleQuest()
    if dataRef then dataRef.autoQuest=not dataRef.autoQuest end
    return dataRef and dataRef.autoQuest or false
end
function autoFarm.ToggleBossFarm()
    bossFarmEnabled=not bossFarmEnabled
    return bossFarmEnabled
end
function autoFarm.ToggleAutoHeal()
    autoHealEnabled=not autoHealEnabled
    return autoHealEnabled
end
function autoFarm.ToggleAutoBuy()
    autoBuyEnabled=not autoBuyEnabled
    return autoBuyEnabled
end
function autoFarm.ToggleAutoStats()
    autoStatsEnabled=not autoStatsEnabled
    return autoStatsEnabled
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
        mobKillCount=mobKillCount,
        bossKillCount=bossKillCount,
        expPerHour=expPerHour,
        questProgress=questProgress,
        autoHealEnabled=autoHealEnabled,
        autoBuyEnabled=autoBuyEnabled,
        autoStatsEnabled=autoStatsEnabled
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
function autoFarm.SetAutoHealThreshold(threshold)
    healThreshold=threshold
    return true
end
function autoFarm.GetExpPerHour()
    return expPerHour
end
function autoFarm.ResetStats()
    mobKillCount=0
    bossKillCount=0
    expPerHour=0
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
    autoHealEnabled=data and data.autoHealEnabled or false
    autoBuyEnabled=data and data.autoBuyEnabled or false
    autoStatsEnabled=data and data.autoStatsEnabled or false
    autoCollectEnabled=data and data.autoCollectEnabled or true
    autoSkillEnabled=data and data.autoSkillEnabled or true
    targetSea=getCurrentSea()
    if data and data.healThreshold then healThreshold=data.healThreshold end
    return true
end
return autoFarm
