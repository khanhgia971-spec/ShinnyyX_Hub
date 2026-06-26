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
local character=nil local humanoid=nil local rootPart=nil
local dataRef=nil local isRunning=false
local seaEventActive=false local seaEventCompleted=false
local currentSeaEvent=nil local seaEventTimer=0
local seaEventTypes={"Ship","Kraken","SeaBeast","Tsunami","Storm","Whirlpool","Mermaid","PirateShip","MarineShip","Treasure"}
local seaEventLocations={}
local seaEventRewards={}
local totalEventsCompleted=0 local totalEventsFound=0
local eventStats={kills=0,damage=0,events=0}
local autoFind=true local autoFight=true local autoCollect=true
local autoTeleport=true local searchRadius=2000
local currentTarget=nil local targetType=nil
local eventCooldown=0 local lastEventTime=0
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
local function findSeaEvents()
    local events={}
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("Head") then
            local name=v.Name:lower()
            for _,ev in ipairs(seaEventTypes) do
                if name:match(ev:lower()) then
                    table.insert(events,{model=v,type=ev,pos=v.Head.Position})
                    break
                end
            end
        end
        if v:IsA("Part") then
            local name=v.Name:lower()
            for _,ev in ipairs(seaEventTypes) do
                if name:match(ev:lower()) then
                    table.insert(events,{model=v,type=ev,pos=v.Position})
                    break
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
        if dist<minDist and dist<searchRadius then
            minDist=dist
            nearest=ev
        end
    end
    return nearest
end
local function moveToPosition(pos)
    if not rootPart then return false end
    local dist=getDistance(rootPart.Position,pos)
    if dist>5 then
        local tweenInfo=TweenInfo.new(dist/40,Enum.EasingStyle.Linear)
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
    local reward=seaEventRewards[event.type] or {exp=50,beli=100}
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
            if not table.find(seaEventTypes,t) then
                table.insert(seaEventTypes,t)
            end
        end
    end
    if data.rewards then
        for ev,rew in pairs(data.rewards) do
            seaEventRewards[ev]=rew
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
    return autoFind
end
function seaEvent.ToggleAutoFight()
    autoFight=not autoFight
    return autoFight
end
function seaEvent.ToggleAutoCollect()
    autoCollect=not autoCollect
    return autoCollect
end
function seaEvent.ToggleAutoTeleport()
    autoTeleport=not autoTeleport
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
        totalEventsFound=totalEventsFound,
        kills=eventStats.kills,
        damage=eventStats.damage,
        events=eventStats.events,
        cooldown=eventCooldown-tick()
    }
end
function seaEvent.GetEventTypes()
    return seaEventTypes
end
function seaEvent.AddEventType(name)
    table.insert(seaEventTypes,name)
    return true
end
function seaEvent.RemoveEventType(name)
    for i,v in ipairs(seaEventTypes) do
        if v==name then
            table.remove(seaEventTypes,i)
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
    return true
end
function seaEvent.GetSearchRadius()
    return searchRadius
end
function seaEvent.SetEventReward(eventType,reward)
    seaEventRewards[eventType]=reward
    return true
end
function seaEvent.GetEventReward(eventType)
    return seaEventRewards[eventType]
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
        return collectEventReward({model=currentTarget,type=targetType})
    end
    return false
end
function seaEvent.GetStats()
    return eventStats
end
function seaEvent.ResetStats()
    eventStats={kills=0,damage=0,events=0}
    totalEventsCompleted=0
    totalEventsFound=0
    return true
end
function seaEvent.GetTotalEventsCompleted()
    return totalEventsCompleted
end
function seaEvent.GetTotalEventsFound()
    return totalEventsFound
end
function seaEvent.SetCooldown(cooldown)
    eventCooldown=cooldown
    return true
end
function seaEvent.GetCooldown()
    return eventCooldown
end
function seaEvent.ExportEventData()
    return httpService:JSONEncode({
        totalCompleted=totalEventsCompleted,
        totalFound=totalEventsFound,
        stats=eventStats,
        eventTypes=seaEventTypes
    })
end
function seaEvent.ImportEventData(json)
    local success,data=pcall(function()return httpService:JSONDecode(json)end)
    if success and data then
        if data.totalCompleted then totalEventsCompleted=data.totalCompleted end
        if data.totalFound then totalEventsFound=data.totalFound end
        if data.stats then eventStats=data.stats end
        if data.eventTypes then
            for _,t in ipairs(data.eventTypes) do
                if not table.find(seaEventTypes,t) then
                    table.insert(seaEventTypes,t)
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
                if not table.find(seaEventTypes,t) then
                    table.insert(seaEventTypes,t)
                end
            end
        end
        if data.rewards then
            for ev,rew in pairs(data.rewards) do
                seaEventRewards[ev]=rew
            end
        end
        if data.cooldown then eventCooldown=data.cooldown end
    end
    if not seaEventRewards["Ship"] then
        seaEventRewards["Ship"]={exp=50,beli=100}
    end
    if not seaEventRewards["Kraken"] then
        seaEventRewards["Kraken"]={exp=150,beli=300}
    end
    if not seaEventRewards["SeaBeast"] then
        seaEventRewards["SeaBeast"]={exp=100,beli=200}
    end
    if not seaEventRewards["Tsunami"] then
        seaEventRewards["Tsunami"]={exp=200,beli=500}
    end
    if not seaEventRewards["Storm"] then
        seaEventRewards["Storm"]={exp=80,beli=150}
    end
    if not seaEventRewards["Whirlpool"] then
        seaEventRewards["Whirlpool"]={exp=120,beli=250}
    end
    if not seaEventRewards["Mermaid"] then
        seaEventRewards["Mermaid"]={exp=60,beli=120}
    end
    if not seaEventRewards["PirateShip"] then
        seaEventRewards["PirateShip"]={exp=90,beli=180}
    end
    if not seaEventRewards["MarineShip"] then
        seaEventRewards["MarineShip"]={exp=90,beli=180}
    end
    if not seaEventRewards["Treasure"] then
        seaEventRewards["Treasure"]={exp=50,beli=300}
    end
    return true
end
return seaEvent
