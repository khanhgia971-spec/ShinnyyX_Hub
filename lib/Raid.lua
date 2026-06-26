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
local raidWave=0 local maxWaves=5
local autoStart=true local autoComplete=true
local autoTeleport=true local autoFight=true
local bossHealthThreshold=0.5
local raidCooldown=0
local raidBosses={}
local raidRewards={}
local totalRaidsCompleted=0 local totalRaidsWon=0
local raidStats={kills=0,damage=0,time=0}
local RAID_DATA={
    -- Sea 1 Raids
    {name="Flame", sea=1, boss="Flame Boss", pos=Vector3.new(-500,50,-400), reward={exp=150,beli=500,fragments=5}},
    {name="Ice", sea=1, boss="Ice Boss", pos=Vector3.new(500,50,-500), reward={exp=150,beli=500,fragments=5}},
    {name="Light", sea=1, boss="Light Boss", pos=Vector3.new(200,300,0), reward={exp=150,beli=500,fragments=5}},
    {name="Dark", sea=1, boss="Dark Boss", pos=Vector3.new(-200,15,600), reward={exp=150,beli=500,fragments=5}},
    {name="Magma", sea=1, boss="Magma Boss", pos=Vector3.new(600,10,-400), reward={exp=200,beli=700,fragments=8}},
    -- Sea 2 Raids
    {name="Quake", sea=2, boss="Quake Boss", pos=Vector3.new(400,10,500), reward={exp=300,beli=1000,fragments=15}},
    {name="String", sea=2, boss="String Boss", pos=Vector3.new(450,30,550), reward={exp=350,beli=1200,fragments=20}},
    {name="Dragon", sea=2, boss="Dragon Boss", pos=Vector3.new(200,20,300), reward={exp=400,beli=1500,fragments=25}},
    {name="Venom", sea=2, boss="Venom Boss", pos=Vector3.new(600,20,700), reward={exp=400,beli=1500,fragments=25}},
    {name="Dough", sea=2, boss="Dough Boss", pos=Vector3.new(800,30,900), reward={exp=450,beli=2000,fragments=30}},
    -- Sea 3 Raids
    {name="Leopard", sea=3, boss="Leopard Boss", pos=Vector3.new(500,20,600), reward={exp=600,beli=2500,fragments=50}},
    {name="Control", sea=3, boss="Control Boss", pos=Vector3.new(600,25,700), reward={exp=600,beli=2500,fragments=50}},
    {name="Shadow", sea=3, boss="Shadow Boss", pos=Vector3.new(650,20,750), reward={exp=650,beli=3000,fragments=60}},
    {name="Rumble", sea=3, boss="Rumble Boss", pos=Vector3.new(700,10,800), reward={exp=650,beli=3000,fragments=60}},
    {name="Blizzard", sea=3, boss="Blizzard Boss", pos=Vector3.new(750,10,850), reward={exp=700,beli=3500,fragments=70}},
    {name="Kitsune", sea=3, boss="Kitsune Boss", pos=Vector3.new(800,20,900), reward={exp=750,beli=4000,fragments=80}},
    {name="Mammoth", sea=3, boss="Mammoth Boss", pos=Vector3.new(850,30,950), reward={exp=750,beli=4000,fragments=80}},
    {name="T-Rex", sea=3, boss="T-Rex Boss", pos=Vector3.new(900,40,1000), reward={exp=800,beli=4500,fragments=90}},
    {name="Soul", sea=3, boss="Soul Boss", pos=Vector3.new(950,50,1050), reward={exp=800,beli=4500,fragments=90}},
    {name="Gas", sea=3, boss="Gas Boss", pos=Vector3.new(1000,20,1100), reward={exp=900,beli=5000,fragments=100}}
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
local function moveToPosition(pos,timeout)
    timeout=timeout or 10
    if not rootPart then return false end
    local dist=getDistance(rootPart.Position,pos)
    if dist<3 then return true end
    local tweenInfo=TweenInfo.new(dist/30,Enum.EasingStyle.Linear)
    local tween=tweenService:Create(rootPart,tweenInfo,{CFrame=CFrame.new(pos)})
    tween:Play()
    local start=tick()
    repeat wait(0.1) until not tween.PlaybackState==Enum.PlaybackState.Playing or tick()-start>timeout
    return getDistance(rootPart.Position,pos)<5
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
        return boss.Humanoid.Health/boss.Humanoid.MaxHealth
    end
    return 0
end
local function findRaidPortal(raidName)
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Model") and v:FindFirstChild("Head") then
            local name=v.Name:lower()
            if name:match("raid") or name:match("portal") then
                if raidName and name:match(raidName:lower()) then
                    return v
                end
                return v
            end
        end
        if v:IsA("Part") and v.Name:lower():match("raid") then
            return v
        end
    end
    return nil
end
local function findRaidBoss(raidName)
    local nearest=nil
    local minDist=math.huge
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("Head") then
            local name=v.Name:lower()
            if name:match("boss") or name:match("king") then
                if raidName and name:match(raidName:lower()) then
                    local dist=getDistance(rootPart.Position,v.Head.Position)
                    if dist<minDist then
                        minDist=dist
                        nearest=v
                    end
                elseif not raidName then
                    local dist=getDistance(rootPart.Position,v.Head.Position)
                    if dist<minDist then
                        minDist=dist
                        nearest=v
                    end
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
local function getAvailableRaids(sea)
    local available={}
    for _,r in ipairs(RAID_DATA) do
        if r.sea==sea or sea==nil then
            table.insert(available,r)
        end
    end
    return available
end
local function getRaidByName(name)
    for _,r in ipairs(RAID_DATA) do
        if r.name:lower()==name:lower() then
            return r
        end
    end
    return nil
end
local function startRaid(raidName)
    if raidActive then return false end
    if raidCooldown>tick() then return false end
    local raidData=getRaidByName(raidName)
    if not raidData then
        local available=getAvailableRaids(getCurrentSea())
        if #available>0 then
            raidData=available[math.random(1,#available)]
        else
            return false
        end
    end
    local portal=findRaidPortal(raidData.name)
    if portal then
        moveToPosition(portal.Position+Vector3.new(0,3,0))
        wait(0.5)
        raidActive=true
        raidCompleted=false
        raidWave=0
        raidTimer=tick()
        raidStats.kills=0
        raidStats.damage=0
        currentRaidBoss=nil
        print("[Raid] Đã bắt đầu raid: "..raidData.name)
        return true
    end
    return false
end
local function completeRaid()
    if not raidActive or raidCompleted then return false end
    raidActive=false
    raidCompleted=true
    totalRaidsCompleted=totalRaidsCompleted+1
    totalRaidsWon=totalRaidsWon+1
    raidStats.time=tick()-raidTimer
    local reward=raidRewards[raidDifficulty] or {exp=100,beli=500,fragments=10}
    print("[Raid] Hoàn thành raid! Phần thưởng: EXP "..reward.exp..", Beli "..reward.beli..", Fragments "..(reward.fragments or 0))
    return reward
end
local function failRaid()
    if not raidActive then return false end
    raidActive=false
    raidCompleted=false
    totalRaidsCompleted=totalRaidsCompleted+1
    print("[Raid] Raid thất bại!")
    return true
end
local function processRaid(data)
    if not rootPart or not humanoid then updateCharacter() end
    if not rootPart or not humanoid then return end
    if raidCooldown>tick() then return end
    if not raidActive then
        if autoStart and data.autoStart then
            local sea=getCurrentSea()
            local available=getAvailableRaids(sea)
            if #available>0 then
                local raidName=available[math.random(1,#available)].name
                startRaid(raidName)
            end
        end
        return
    end
    if raidCompleted then
        if autoComplete and data.autoComplete then
            completeRaid()
            raidCooldown=tick()+5
        end
        return
    end
    raidTimer=raidTimer+0.1
    local raidData=getRaidByName(data.raidName)
    if not raidData then
        local available=getAvailableRaids(getCurrentSea())
        if #available>0 then
            raidData=available[1]
        end
    end
    if autoFight and data.autoFight then
        local enemies=findRaidEnemies()
        if #enemies>0 then
            for _,enemy in ipairs(enemies) do
                attackTarget(enemy)
                wait(0.2)
                raidStats.kills=raidStats.kills+1
            end
        end
        local boss=findRaidBoss(raidData and raidData.name or nil)
        if boss then
            currentRaidBoss=boss
            local health=getBossHealth(boss)
            if health<bossHealthThreshold then
                attackTarget(boss)
                raidStats.kills=raidStats.kills+1
                raidWave=raidWave+1
                if raidWave>=maxWaves then
                    completeRaid()
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
    if autoTeleport and data.autoTeleport and raidWave>0 and raidWave%2==0 then
        local portal=findRaidPortal(raidData and raidData.name or nil)
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
    if data.raidName then
        local rd=getRaidByName(data.raidName)
        if not rd then
            local available=getAvailableRaids(getCurrentSea())
            if #available>0 then
                data.raidName=available[1].name
            end
        end
    end
    if not data.enabled then
        if isRunning then raid.Stop() end
        return false
    end
    if not isRunning then
        startRaidLoop(data)
    end
    return true
end
function raid.StartRaid(raidName)
    return startRaid(raidName)
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
function raid.FindRaidPortal(raidName)
    return findRaidPortal(raidName)
end
function raid.FindRaidBoss(raidName)
    return findRaidBoss(raidName)
end
function raid.FindRaidEnemies()
    return findRaidEnemies()
end
function raid.MoveToRaidPortal(raidName)
    local portal=findRaidPortal(raidName)
    if portal then
        return moveToPosition(portal.Position+Vector3.new(0,3,0))
    end
    return false
end
function raid.MoveToBoss(raidName)
    local boss=findRaidBoss(raidName)
    if boss and boss:FindFirstChild("Head") then
        return moveToPosition(boss.Head.Position+Vector3.new(0,5,0))
    end
    return false
end
function raid.AttackBoss(raidName)
    local boss=findRaidBoss(raidName)
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
        return tick()-raidTimer
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
function raid.GetAvailableRaids(sea)
    return getAvailableRaids(sea or getCurrentSea())
end
function raid.GetAllRaids()
    return RAID_DATA
end
function raid.GetRaidByName(name)
    return getRaidByName(name)
end
function raid.SetRaidCooldown(cooldown)
    raidCooldown=cooldown
    return true
end
function raid.GetRaidCooldown()
    return raidCooldown
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
        if data.raidName then
            local rd=getRaidByName(data.raidName)
            if not rd then
                local available=getAvailableRaids(getCurrentSea())
                if #available>0 then
                    data.raidName=available[1].name
                end
            end
        end
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
        raidRewards["Normal"]={exp=100,beli=500,fragments=10}
    end
    if not raidRewards["Hard"] then
        raidRewards["Hard"]={exp=200,beli=1000,fragments=20}
    end
    if not raidRewards["Expert"] then
        raidRewards["Expert"]={exp=400,beli=2000,fragments=40}
    end
    if not raidRewards["Legendary"] then
        raidRewards["Legendary"]={exp=800,beli=5000,fragments=80}
    end
    return true
end
return raid
