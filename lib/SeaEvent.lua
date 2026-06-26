local seaEvent={}
seaEvent.__index=seaEvent
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
local virtualUser=game:GetService("VirtualUser")
local character=nil local humanoid=nil local rootPart=nil
local dataRef=nil local isRunning=false
local seaEventActive=false local seaEventCompleted=false
local currentSeaEvent=nil local seaEventTimer=0
local autoFind=true local autoFight=true local autoCollect=true
local autoTeleport=true local searchRadius=2000
local currentTarget=nil local targetType=nil
local eventCooldown=0 local totalEventsCompleted=0
local eventStats={kills=0,damage=0,events=0}
local SEA_EVENT_TYPES={
    "Sea Beast","Ship Raid","Leviathan","Tsunami","Storm","Whirlpool",
    "Mermaid","Pirate Ship","Marine Ship","Treasure","Kraken",
    "Submerged Island","Frozen Dimension","Prehistoric Island",
    "Sea of Treats","Castle on Sea","Tiki Outpost","Hydra Island"
}
local SEA_EVENT_DATA={
    ["Sea Beast"]={level=0, sea=1, reward={exp=100,beli=200,fragments=5}, health=5000, damage=50},
    ["Ship Raid"]={level=0, sea=1, reward={exp=80,beli=150,fragments=3}, health=3000, damage=30},
    ["Tsunami"]={level=0, sea=1, reward={exp=50,beli=100}, health=0, damage=0},
    ["Storm"]={level=0, sea=1, reward={exp=40,beli=80}, health=0, damage=0},
    ["Whirlpool"]={level=0, sea=1, reward={exp=60,beli=120}, health=0, damage=0},
    ["Mermaid"]={level=0, sea=1, reward={exp=70,beli=150}, health=100, damage=10},
    ["Pirate Ship"]={level=0, sea=1, reward={exp=90,beli=180}, health=2000, damage=20},
    ["Marine Ship"]={level=0, sea=1, reward={exp=90,beli=180}, health=2000, damage=20},
    ["Treasure"]={level=0, sea=1, reward={exp=50,beli=300}, health=0, damage=0},
    ["Kraken"]={level=0, sea=2, reward={exp=150,beli=300,fragments=10}, health=10000, damage=80},
    ["Sea Beast"]={level=0, sea=2, reward={exp=120,beli=250,fragments=8}, health=8000, damage=60},
    ["Ship Raid"]={level=0, sea=2, reward={exp=100,beli=200,fragments=5}, health=5000, damage=40},
    ["Leviathan"]={level=1500, sea=3, reward={exp=500,beli=1000,fragments=50}, health=100000, damage=200},
    ["Submerged Island"]={level=700, sea=2, reward={exp=200,beli=500,fragments=15}, health=0, damage=0},
    ["Frozen Dimension"]={level=700, sea=2, reward={exp=300,beli=700,fragments=25}, health=0, damage=0},
    ["Prehistoric Island"]={level=700, sea=2, reward={exp=250,beli=600,fragments=20}, health=0, damage=0},
    ["Sea of Treats"]={level=1500, sea=3, reward={exp=400,beli=800,fragments=35}, health=0, damage=0},
    ["Castle on Sea"]={level=1500, sea=3, reward={exp=400,beli=800,fragments=35}, health=0, damage=0},
    ["Tiki Outpost"]={level=1500, sea=3, reward={exp=350,beli=750,fragments=30}, health=0, damage=0},
    ["Hydra Island"]={level=1500, sea=3, reward={exp=350,beli=750,fragments=30}, health=0, damage=0}
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
local function findSeaEvents()
    local events={}
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("Head") then
            local name=v.Name:lower()
            for _,ev in ipairs(SEA_EVENT_TYPES) do
                if name:match(ev:lower()) then
                    local data=SEA_EVENT_DATA[ev]
                    local level=getPlayerLevel()
                    if not data or level>=data.level then
                        table.insert(events,{model=v,type=ev,pos=v.Head.Position})
                        break
                    end
                end
            end
        end
        if v:IsA("Part") then
            local name=v.Name:lower()
            for _,ev in ipairs(SEA_EVENT_TYPES) do
                if name:match(ev:lower()) then
                    local data=SEA_EVENT_DATA[ev]
                    local level=getPlayerLevel()
                    if not data or level>=data.level then
                        table.insert(events,{model=v,type=ev,pos=v.Position})
                        break
                    end
                end
            end
        end
    end
    return events
end
local function findNearestSeaEvent()
    local events=findSeaEvents()
    local nearest=nil
    local minDist=math.huge
    for _,ev in ipairs(events) do
        local dist=getDistance(rootPart.Position,ev.pos)
        if dist<searchRadius and dist<minDist then
            minDist=dist
            nearest=ev
        end
    end
    return nearest
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
    local head=target:FindFirstChild("Head")
    if head then
        rootPart.CFrame=CFrame.new(head.Position+Vector3.new(0,5,0))
        wait(0.1)
        if humanoid then
            humanoid:BreakJoints()
            return true
        end
    end
    return false
end
local function collectEventReward(event)
    if not event then return false end
    local data=SEA_EVENT_DATA[event.type]
    local reward=data and data.reward or {exp=50,beli=100}
    eventStats.events=eventStats.events+1
    totalEventsCompleted=totalEventsCompleted+1
    return reward
end
local function processSeaEvent(data)
    if not rootPart or not humanoid then updateCharacter() end
    if not rootPart or not humanoid then return end
    if eventCooldown>tick() then return end
    if autoFind then
        local nearest=findNearestSeaEvent()
        if nearest then
            currentTarget=nearest.model
            targetType=nearest.type
            seaEventActive=true
            if autoTeleport and getDistance(rootPart.Position,nearest.pos)>50 then
                moveToPosition(nearest.pos+Vector3.new(0,5,0))
            end
            if autoFight and currentTarget then
                if currentTarget:IsA("Model") and currentTarget:FindFirstChild("Humanoid") then
                    local health=currentTarget.Humanoid.Health
                    if health>0 then
                        attackTarget(currentTarget)
                        eventStats.damage=eventStats.damage+10
                        if health<50 then
                            eventStats.kills=eventStats.kills+1
                            if autoCollect then
                                local reward=collectEventReward(nearest)
                                if reward then
                                    seaEventCompleted=true
                                    seaEventActive=false
                                    eventCooldown=tick()+2
                                end
                            end
                        end
                    end
                end
                if currentTarget:IsA("Part") then
                    if getDistance(rootPart.Position,currentTarget.Position)<5 then
                        local reward=collectEventReward(nearest)
                        if reward then
                            seaEventCompleted=true
                            seaEventActive=false
                            eventCooldown=tick()+2
                        end
                    end
                end
            end
        else
            seaEventActive=false
            seaEventCompleted=false
            currentTarget=nil
        end
    end
    seaEventTimer=seaEventTimer+0.1
end
local function startSeaEventLoop(data)
    if isRunning then return end
    isRunning=true
    task.spawn(function()
        while isRunning do
            wait(0.1)
            pcall(function()processSeaEvent(data)end)
        end
    end)
end
function seaEvent.Stop()
    isRunning=false
    return true
end
function seaEvent.Run(data)
    if not data then return false end
    dataRef=data
    if data.autoFind~=nil then autoFind=data.autoFind end
    if data.autoFight~=nil then autoFight=data.autoFight end
    if data.autoCollect~=nil then autoCollect=data.autoCollect end
    if data.autoTeleport~=nil then autoTeleport=data.autoTeleport end
    if data.searchRadius then searchRadius=data.searchRadius end
    if data.eventTypes then
        for _,t in ipairs(data.eventTypes) do
            if not table.find(SEA_EVENT_TYPES,t) then
                table.insert(SEA_EVENT_TYPES,t)
            end
        end
    end
    if data.rewards then
        for ev,rew in pairs(data.rewards) do
            if SEA_EVENT_DATA[ev] then
                SEA_EVENT_DATA[ev].reward=rew
            end
        end
    end
    if not data.enabled then
        if isRunning then seaEvent.Stop() end
        return false
    end
    if not isRunning then
        startSeaEventLoop(data)
    end
    return true
end
function seaEvent.ToggleAutoFind()
    autoFind=not autoFind
    if dataRef then dataRef.autoFind=autoFind end
    return autoFind
end
function seaEvent.ToggleAutoFight()
    autoFight=not autoFight
    if dataRef then dataRef.autoFight=autoFight end
    return autoFight
end
function seaEvent.ToggleAutoCollect()
    autoCollect=not autoCollect
    if dataRef then dataRef.autoCollect=autoCollect end
    return autoCollect
end
function seaEvent.ToggleAutoTeleport()
    autoTeleport=not autoTeleport
    if dataRef then dataRef.autoTeleport=autoTeleport end
    return autoTeleport
end
function seaEvent.GetStatus()
    return{
        isRunning=isRunning,
        seaEventActive=seaEventActive,
        seaEventCompleted=seaEventCompleted,
        currentEvent=currentTarget and currentTarget.Name or "None",
        eventType=targetType or "None",
        totalEventsCompleted=totalEventsCompleted,
        kills=eventStats.kills,
        damage=eventStats.damage,
        events=eventStats.events,
        cooldown=eventCooldown-tick()
    }
end
function seaEvent.GetEventTypes()
    return SEA_EVENT_TYPES
end
function seaEvent.AddEventType(name)
    table.insert(SEA_EVENT_TYPES,name)
    return true
end
function seaEvent.RemoveEventType(name)
    for i,v in ipairs(SEA_EVENT_TYPES) do
        if v==name then
            table.remove(SEA_EVENT_TYPES,i)
            return true
        end
    end
    return false
end
function seaEvent.FindAllEvents()
    return findSeaEvents()
end
function seaEvent.FindNearestEvent()
    return findNearestSeaEvent()
end
function seaEvent.SetSearchRadius(radius)
    searchRadius=radius
    if dataRef then dataRef.searchRadius=radius end
    return true
end
function seaEvent.GetSearchRadius()
    return searchRadius
end
function seaEvent.SetEventReward(eventType,reward)
    if SEA_EVENT_DATA[eventType] then
        SEA_EVENT_DATA[eventType].reward=reward
        return true
    end
    return false
end
function seaEvent.GetEventReward(eventType)
    if SEA_EVENT_DATA[eventType] then
        return SEA_EVENT_DATA[eventType].reward
    end
    return nil
end
function seaEvent.MoveToNearestEvent()
    local ev=findNearestSeaEvent()
    if ev then
        return moveToPosition(ev.pos+Vector3.new(0,5,0))
    end
    return false
end
function seaEvent.FightCurrentEvent()
    if currentTarget then
        return attackTarget(currentTarget)
    end
    return false
end
function seaEvent.CollectCurrentEvent()
    if currentTarget then
        local ev={model=currentTarget,type=targetType}
        return collectEventReward(ev)
    end
    return false
end
function seaEvent.GetStats()
    return eventStats
end
function seaEvent.ResetStats()
    eventStats={kills=0,damage=0,events=0}
    totalEventsCompleted=0
    return true
end
function seaEvent.GetTotalEventsCompleted()
    return totalEventsCompleted
end
function seaEvent.SetCooldown(cooldown)
    eventCooldown=cooldown
    if dataRef then dataRef.cooldown=cooldown end
    return true
end
function seaEvent.GetCooldown()
    return eventCooldown
end
function seaEvent.GetEventData(eventType)
    return SEA_EVENT_DATA[eventType]
end
function seaEvent.SetEventData(eventType,data)
    SEA_EVENT_DATA[eventType]=data
    return true
end
function seaEvent.GetAvailableEvents(sea)
    local available={}
    local level=getPlayerLevel()
    for ev,data in pairs(SEA_EVENT_DATA) do
        if data.sea==sea and level>=data.level then
            table.insert(available,ev)
        end
    end
    return available
end
function seaEvent.ExportEventData()
    return httpService:JSONEncode({
        totalCompleted=totalEventsCompleted,
        stats=eventStats,
        eventTypes=SEA_EVENT_TYPES
    })
end
function seaEvent.ImportEventData(json)
    local success,data=pcall(function()return httpService:JSONDecode(json)end)
    if success and data then
        if data.totalCompleted then totalEventsCompleted=data.totalCompleted end
        if data.stats then eventStats=data.stats end
        if data.eventTypes then
            for _,t in ipairs(data.eventTypes) do
                if not table.find(SEA_EVENT_TYPES,t) then
                    table.insert(SEA_EVENT_TYPES,t)
                end
            end
        end
        return true
    end
    return false
end
function seaEvent.Pause()
    isRunning=false
    return true
end
function seaEvent.Resume()
    if dataRef and dataRef.enabled then
        isRunning=true
        startSeaEventLoop(dataRef)
        return true
    end
    return false
end
function seaEvent.Destroy()
    isRunning=false
    seaEventActive=false
    seaEventCompleted=false
    currentTarget=nil
    targetType=nil
    eventStats={kills=0,damage=0,events=0}
    dataRef=nil
    return true
end
function seaEvent.Initialize(data)
    dataRef=data
    updateCharacter()
    if data then
        if data.autoFind~=nil then autoFind=data.autoFind end
        if data.autoFight~=nil then autoFight=data.autoFight end
        if data.autoCollect~=nil then autoCollect=data.autoCollect end
        if data.autoTeleport~=nil then autoTeleport=data.autoTeleport end
        if data.searchRadius then searchRadius=data.searchRadius end
        if data.eventTypes then
            for _,t in ipairs(data.eventTypes) do
                if not table.find(SEA_EVENT_TYPES,t) then
                    table.insert(SEA_EVENT_TYPES,t)
                end
            end
        end
        if data.rewards then
            for ev,rew in pairs(data.rewards) do
                if SEA_EVENT_DATA[ev] then
                    SEA_EVENT_DATA[ev].reward=rew
                end
            end
        end
        if data.cooldown then eventCooldown=data.cooldown end
        if data.eventData then
            for ev,evData in pairs(data.eventData) do
                SEA_EVENT_DATA[ev]=evData
            end
        end
    end
    -- Đảm bảo dữ liệu mặc định cho các sự kiện mới
    if not SEA_EVENT_DATA["Sea Beast"] then
        SEA_EVENT_DATA["Sea Beast"]={level=0,sea=1,reward={exp=100,beli=200,fragments=5},health=5000,damage=50}
    end
    if not SEA_EVENT_DATA["Ship Raid"] then
        SEA_EVENT_DATA["Ship Raid"]={level=0,sea=1,reward={exp=80,beli=150,fragments=3},health=3000,damage=30}
    end
    if not SEA_EVENT_DATA["Leviathan"] then
        SEA_EVENT_DATA["Leviathan"]={level=1500,sea=3,reward={exp=500,beli=1000,fragments=50},health=100000,damage=200}
    end
    if not SEA_EVENT_DATA["Kraken"] then
        SEA_EVENT_DATA["Kraken"]={level=0,sea=2,reward={exp=150,beli=300,fragments=10},health=10000,damage=80}
    end
    if not SEA_EVENT_DATA["Submerged Island"] then
        SEA_EVENT_DATA["Submerged Island"]={level=700,sea=2,reward={exp=200,beli=500,fragments=15},health=0,damage=0}
    end
    if not SEA_EVENT_DATA["Frozen Dimension"] then
        SEA_EVENT_DATA["Frozen Dimension"]={level=700,sea=2,reward={exp=300,beli=700,fragments=25},health=0,damage=0}
    end
    if not SEA_EVENT_DATA["Prehistoric Island"] then
        SEA_EVENT_DATA["Prehistoric Island"]={level=700,sea=2,reward={exp=250,beli=600,fragments=20},health=0,damage=0}
    end
    if not SEA_EVENT_DATA["Sea of Treats"] then
        SEA_EVENT_DATA["Sea of Treats"]={level=1500,sea=3,reward={exp=400,beli=800,fragments=35},health=0,damage=0}
    end
    if not SEA_EVENT_DATA["Castle on Sea"] then
        SEA_EVENT_DATA["Castle on Sea"]={level=1500,sea=3,reward={exp=400,beli=800,fragments=35},health=0,damage=0}
    end
    if not SEA_EVENT_DATA["Tiki Outpost"] then
        SEA_EVENT_DATA["Tiki Outpost"]={level=1500,sea=3,reward={exp=350,beli=750,fragments=30},health=0,damage=0}
    end
    if not SEA_EVENT_DATA["Hydra Island"] then
        SEA_EVENT_DATA["Hydra Island"]={level=1500,sea=3,reward={exp=350,beli=750,fragments=30},health=0,damage=0}
    end
    return true
end
return seaEvent
