local raid={}
raid.__index=raid
local player=game.Players.LocalPlayer
local runService=game:GetService("RunService")
local userInput=game:GetService("UserInputService")
local workspace=game:GetService("Workspace")
local players=game:GetService("Players")
local tweenService=game:GetService("TweenService")
local debris=game:GetService("Debris")
local collectionService=game:GetService("CollectionService")
local replicatedStorage=game:GetService("ReplicatedStorage")
local httpService=game:GetService("HttpService")
local character=nil local humanoid=nil local rootPart=nil
local dataRef=nil local isRunning=false
local raidActive=false local raidCompleted=false
local currentRaidBoss=nil local raidTimer=0
local raidDifficulty="Normal"
local raidTypes={"Normal","Hard","Expert","Legendary"}
local raidBosses={}
local raidRewards={}
local raidParticipants={}
local raidStartTime=0 local raidEndTime=0
local totalRaidsCompleted=0 local totalRaidsWon=0
local raidStats={kills=0,damage=0,time=0}
local raidObjectives={}
local currentObjective=1
local raidWave=0 local maxWaves=5
local autoStart=true local autoComplete=true
local autoTeleport=true local autoFight=true
local bossHealthThreshold=0.5
local raidCooldown=0
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
local function findRaidPortal()
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Model") and v:FindFirstChild("Head") then
            if v.Name:lower():match("raid") or v.Name:lower():match("portal") then
                return v
            end
        end
        if v:IsA("Part") and v.Name:lower():match("raid") then
            return v
        end
    end
    return nil
end
local function findRaidBoss()
    local nearest=nil
    local minDist=math.huge
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("Head") then
            if v.Name:lower():match("boss") or v.Name:lower():match("king") or v.Name:lower():match("guardian") then
                local dist=getDistance(rootPart.Position,v.Head.Position)
                if dist<minDist then
                    minDist=dist
                    nearest=v
                end
            end
        end
    end
    return nearest
end
local function findRaidEnemies()
    local enemies={}
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("Head") then
            if v.Name~=player.Name and v:FindFirstChild("Humanoid").Health>0 then
                if v.Name:lower():match("enemy") or v.Name:lower():match("mob") or v.Name:lower():match("minion") then
                    table.insert(enemies,v)
                end
            end
        end
    end
    return enemies
end
local function moveToPosition(pos)
    if not rootPart then return false end
    local dist=getDistance(rootPart.Position,pos)
    if dist>3 then
        local tweenInfo=TweenInfo.new(dist/30,Enum.EasingStyle.Linear)
        local tween=tweenService:Create(rootPart,tweenInfo,{CFrame=CFrame.new(pos)})
        tween:Play()
        return true
    end
    return true
end
local function attackTarget(target)
    if not target or not rootPart then return false end
    local head=target:FindFirstChild("Head")
    if head then
        rootPart.CFrame=CFrame.new(head.Position+Vector3.new(0,3,0))
        wait(0.1)
        if humanoid then
            humanoid:BreakJoints()
            return true
        end
    end
    return false
end
local function getBossHealth(boss)
    if boss and boss:FindFirstChild("Humanoid") then
        local hum=boss.Humanoid
        return hum.Health/hum.MaxHealth
    end
    return 0
end
local function getRaidDifficulty()
    return raidDifficulty
end
local function setRaidDifficulty(difficulty)
    if table.find(raidTypes,difficulty) then
        raidDifficulty=difficulty
        return true
    end
    return false
end
local function startRaid()
    if raidActive then return false end
    local portal=findRaidPortal()
    if portal then
        moveToPosition(portal.Position+Vector3.new(0,3,0))
        wait(0.5)
        raidActive=true
        raidCompleted=false
        raidStartTime=tick()
        raidWave=0
        currentObjective=1
        raidObjectives={}
        raidStats.kills=0
        raidStats.damage=0
        return true
    end
    return false
end
local function completeRaid()
    if not raidActive or raidCompleted then return false end
    raidActive=false
    raidCompleted=true
    raidEndTime=tick()
    totalRaidsCompleted=totalRaidsCompleted+1
    totalRaidsWon=totalRaidsWon+1
    raidStats.time=raidEndTime-raidStartTime
    local reward=raidRewards[raidDifficulty] or {exp=100,beli=500}
    return reward
end
local function failRaid()
    if not raidActive then return false end
    raidActive=false
    raidCompleted=false
    totalRaidsCompleted=totalRaidsCompleted+1
    return true
end
local function processRaid(data)
    if not rootPart or not humanoid then updateCharacter() end
    if not rootPart or not humanoid then return end
    if raidCooldown>tick() then return end
    if not raidActive then
        if autoStart then
            startRaid()
        end
        return
    end
    if raidCompleted then
        if autoComplete then
            local reward=completeRaid()
            if reward then
                raidCooldown=tick()+5
            end
        end
        return
    end
    raidTimer=raidTimer+0.1
    if autoFight then
        local enemies=findRaidEnemies()
        if #enemies>0 then
            for _,enemy in ipairs(enemies) do
                attackTarget(enemy)
                wait(0.2)
                raidStats.kills=raidStats.kills+1
            end
        end
        local boss=findRaidBoss()
        if boss then
            currentRaidBoss=boss
            local health=getBossHealth(boss)
            if health<bossHealthThreshold then
                if humanoid then
                    humanoid:BreakJoints()
                    raidStats.kills=raidStats.kills+1
                    raidWave=raidWave+1
                    if raidWave>=maxWaves then
                        completeRaid()
                    end
                end
            else
                attackTarget(boss)
                raidStats.damage=raidStats.damage+10
            end
        else
            if raidWave>=maxWaves then
                completeRaid()
            end
        end
    end
    if autoTeleport and raidWave>0 and raidWave%2==0 then
        local portal=findRaidPortal()
        if portal then
            moveToPosition(portal.Position+Vector3.new(0,3,0))
        end
    end
end
local function startRaidLoop(data)
    if isRunning then return end
    isRunning=true
    task.spawn(function()
        while isRunning do
            wait(0.1)
            pcall(function()processRaid(data)end)
        end
    end)
end
function raid.Stop()
    isRunning=false
    return true
end
function raid.Run(data)
    if not data then return false end
    dataRef=data
    if data.difficulty then setRaidDifficulty(data.difficulty) end
    if data.autoStart~=nil then autoStart=data.autoStart end
    if data.autoComplete~=nil then autoComplete=data.autoComplete end
    if data.autoTeleport~=nil then autoTeleport=data.autoTeleport end
    if data.autoFight~=nil then autoFight=data.autoFight end
    if data.maxWaves then maxWaves=data.maxWaves end
    if data.bossHealthThreshold then bossHealthThreshold=data.bossHealthThreshold end
    if not data.enabled then
        if isRunning then raid.Stop() end
        return false
    end
    if not isRunning then
        startRaidLoop(data)
    end
    return true
end
function raid.StartRaid()
    return startRaid()
end
function raid.CompleteRaid()
    return completeRaid()
end
function raid.FailRaid()
    return failRaid()
end
function raid.SetDifficulty(difficulty)
    return setRaidDifficulty(difficulty)
end
function raid.GetDifficulty()
    return getRaidDifficulty()
end
function raid.GetStatus()
    return{
        isRunning=isRunning,
        raidActive=raidActive,
        raidCompleted=raidCompleted,
        raidWave=raidWave,
        maxWaves=maxWaves,
        currentBoss=currentRaidBoss and currentRaidBoss.Name or "None",
        bossHealth=currentRaidBoss and getBossHealth(currentRaidBoss) or 0,
        kills=raidStats.kills,
        damage=raidStats.damage,
        time=raidStats.time,
        totalCompleted=totalRaidsCompleted,
        totalWon=totalRaidsWon,
        difficulty=raidDifficulty,
        cooldown=raidCooldown-tick()
    }
end
function raid.GetRaidTypes()
    return raidTypes
end
function raid.SetRaidTypes(types)
    raidTypes=types
    return true
end
function raid.AddRaidType(name)
    table.insert(raidTypes,name)
    return true
end
function raid.RemoveRaidType(name)
    for i,v in ipairs(raidTypes) do
        if v==name then
            table.remove(raidTypes,i)
            return true
        end
    end
    return false
end
function raid.GetRaidBosses()
    return raidBosses
end
function raid.AddRaidBoss(name,health,damage)
    raidBosses[name]={health=health or 1000,damage=damage or 50}
    return true
end
function raid.RemoveRaidBoss(name)
    raidBosses[name]=nil
    return true
end
function raid.SetRaidReward(difficulty,reward)
    raidRewards[difficulty]=reward
    return true
end
function raid.GetRaidReward(difficulty)
    return raidRewards[difficulty]
end
function raid.SetMaxWaves(waves)
    maxWaves=waves
    return true
end
function raid.GetMaxWaves()
    return maxWaves
end
function raid.SetBossHealthThreshold(threshold)
    bossHealthThreshold=threshold
    return true
end
function raid.GetBossHealthThreshold()
    return bossHealthThreshold
end
function raid.ToggleAutoStart()
    autoStart=not autoStart
    return autoStart
end
function raid.ToggleAutoComplete()
    autoComplete=not autoComplete
    return autoComplete
end
function raid.ToggleAutoTeleport()
    autoTeleport=not autoTeleport
    return autoTeleport
end
function raid.ToggleAutoFight()
    autoFight=not autoFight
    return autoFight
end
function raid.FindRaidPortal()
    return findRaidPortal()
end
function raid.FindRaidBoss()
    return findRaidBoss()
end
function raid.FindRaidEnemies()
    return findRaidEnemies()
end
function raid.MoveToRaidPortal()
    local portal=findRaidPortal()
    if portal then
        return moveToPosition(portal.Position+Vector3.new(0,3,0))
    end
    return false
end
function raid.MoveToBoss()
    local boss=findRaidBoss()
    if boss and boss:FindFirstChild("Head") then
        return moveToPosition(boss.Head.Position+Vector3.new(0,5,0))
    end
    return false
end
function raid.AttackBoss()
    local boss=findRaidBoss()
    if boss then
        return attackTarget(boss)
    end
    return false
end
function raid.ClearEnemies()
    local enemies=findRaidEnemies()
    local count=0
    for _,enemy in ipairs(enemies) do
        if attackTarget(enemy) then
            count=count+1
        end
        wait(0.1)
    end
    return count
end
function raid.GetRaidStats()
    return raidStats
end
function raid.ResetRaidStats()
    raidStats={kills=0,damage=0,time=0}
    totalRaidsCompleted=0
    totalRaidsWon=0
    return true
end
function raid.GetTotalRaidsCompleted()
    return totalRaidsCompleted
end
function raid.GetTotalRaidsWon()
    return totalRaidsWon
end
function raid.GetWinRate()
    if totalRaidsCompleted==0 then return 0 end
    return totalRaidsWon/totalRaidsCompleted
end
function raid.GetRaidTime()
    if raidActive then
        return tick()-raidStartTime
    end
    return raidStats.time
end
function raid.IsRaidActive()
    return raidActive
end
function raid.IsRaidCompleted()
    return raidCompleted
end
function raid.GetRaidWave()
    return raidWave
end
function raid.SetRaidWave(wave)
    raidWave=wave
    return true
end
function raid.IncrementWave()
    raidWave=raidWave+1
    return raidWave
end
function raid.ResetRaid()
    raidActive=false
    raidCompleted=false
    raidWave=0
    currentRaidBoss=nil
    raidStats.kills=0
    raidStats.damage=0
    raidStats.time=0
    return true
end
function raid.ExportRaidData()
    return httpService:JSONEncode({
        totalCompleted=totalRaidsCompleted,
        totalWon=totalRaidsWon,
        stats=raidStats,
        difficulty=raidDifficulty,
        maxWaves=maxWaves
    })
end
function raid.ImportRaidData(json)
    local success,data=pcall(function()return httpService:JSONDecode(json)end)
    if success and data then
        if data.totalCompleted then totalRaidsCompleted=data.totalCompleted end
        if data.totalWon then totalRaidsWon=data.totalWon end
        if data.stats then raidStats=data.stats end
        if data.difficulty then raidDifficulty=data.difficulty end
        if data.maxWaves then maxWaves=data.maxWaves end
        return true
    end
    return false
end
function raid.SetCooldown(cooldown)
    raidCooldown=cooldown
    return true
end
function raid.GetCooldown()
    return raidCooldown
end
function raid.Pause()
    isRunning=false
    return true
end
function raid.Resume()
    if dataRef and dataRef.enabled then
        isRunning=true
        startRaidLoop(dataRef)
        return true
    end
    return false
end
function raid.Destroy()
    isRunning=false
    raidActive=false
    raidCompleted=false
    raidWave=0
    currentRaidBoss=nil
    raidStats={kills=0,damage=0,time=0}
    dataRef=nil
    return true
end
function raid.Initialize(data)
    dataRef=data
    updateCharacter()
    if data then
        if data.difficulty then setRaidDifficulty(data.difficulty) end
        if data.autoStart~=nil then autoStart=data.autoStart end
        if data.autoComplete~=nil then autoComplete=data.autoComplete end
        if data.autoTeleport~=nil then autoTeleport=data.autoTeleport end
        if data.autoFight~=nil then autoFight=data.autoFight end
        if data.maxWaves then maxWaves=data.maxWaves end
        if data.bossHealthThreshold then bossHealthThreshold=data.bossHealthThreshold end
        if data.raidTypes then
            for _,t in ipairs(data.raidTypes) do
                if not table.find(raidTypes,t) then
                    table.insert(raidTypes,t)
                end
            end
        end
        if data.raidBosses then
            for name,info in pairs(data.raidBosses) do
                raidBosses[name]=info
            end
        end
        if data.raidRewards then
            for diff,reward in pairs(data.raidRewards) do
                raidRewards[diff]=reward
            end
        end
    end
    if not raidRewards["Normal"] then
        raidRewards["Normal"]={exp=100,beli=500}
    end
    if not raidRewards["Hard"] then
        raidRewards["Hard"]={exp=200,beli=1000}
    end
    if not raidRewards["Expert"] then
        raidRewards["Expert"]={exp=400,beli=2000}
    end
    if not raidRewards["Legendary"] then
        raidRewards["Legendary"]={exp=800,beli=5000}
    end
    return true
end
return raid
