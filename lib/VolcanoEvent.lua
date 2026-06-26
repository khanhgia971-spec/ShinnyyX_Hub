local volcanoEvent={}
volcanoEvent.__index=volcanoEvent
local player=game.Players.LocalPlayer
local runService=game:GetService("RunService")
local tweenService=game:GetService("TweenService")
local workspace=game:GetService("Workspace")
local players=game:GetService("Players")
local lighting=game:GetService("Lighting")
local virtualUser=game:GetService("VirtualUser")
local coreGui=game:GetService("CoreGui")
local userInput=game:GetService("UserInputService")
local teleportService=game:GetService("TeleportService")
local httpService=game:GetService("HttpService")
local debris=game:GetService("Debris")
local dataRef=nil
local isRunning=false
local character=nil local humanoid=nil local rootPart=nil
local volcanoIsland=nil local islandPosition=nil
local relicPosition=nil local skullPosition=nil
local volcanoCracks={} local lavaGolems={}
local eventActive=false local eventCompleted=false
local volcanoPressure=0 local relicHealth=100
local timeRemaining=300 local eventTimer=0
local bonesCollected=0 local eggsCollected=0
local golemsKilled=0 local cracksSealed=0
local isOnIsland=false local hasVolcanicMagnet=false
local searchingIsland=false local sailingTimer=0
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
local function findVolcanoIsland()
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Model") then
            local name=v.Name:lower()
            if name:find("prehistoric") or name:find("volcano") or name:find("dinosaur") then
                return v
            end
        end
    end
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Part") and v.Name:lower():find("volcano") then
            return v
        end
    end
    return nil
end
local function findRelic()
    for _,v in pairs(workspace:GetDescendants()) do
        if v:IsA("Part") and v.Name:lower():find("relic") then
            return v.Position
        end
        if v:IsA("Model") and v.Name:lower():find("relic") then
            return v.Position
        end
    end
    return nil
end
local function findSkull()
    for _,v in pairs(workspace:GetDescendants()) do
        if v:IsA("Part") and v.Name:lower():find("skull") then
            return v.Position
        end
        if v:IsA("Model") and v.Name:lower():find("skull") then
            return v.Position
        end
    end
    return nil
end
local function findVolcanoCracks()
    local cracks={}
    for _,v in pairs(workspace:GetDescendants()) do
        if v:IsA("Part") then
            local name=v.Name:lower()
            if name:find("crack") or name:find("hole") or name:find("vent") then
                table.insert(cracks,v)
            end
        end
    end
    return cracks
end
local function findLavaGolems()
    local golems={}
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") then
            local name=v.Name:lower()
            if name:find("golem") or name:find("lava") then
                if v:FindFirstChild("Humanoid").Health>0 then
                    table.insert(golems,v)
                end
            end
        end
    end
    return golems
end
local function findDragonEggs()
    local eggs={}
    for _,v in pairs(workspace:GetDescendants()) do
        if v:IsA("Part") and v.Name:lower():find("dragon") and v.Name:lower():find("egg") then
            table.insert(eggs,v)
        end
        if v:IsA("Model") and v.Name:lower():find("dragon") and v.Name:lower():find("egg") then
            table.insert(eggs,v)
        end
    end
    return eggs
end
local function findDinosaurBones()
    local bones={}
    for _,v in pairs(workspace:GetDescendants()) do
        if v:IsA("Part") and v.Name:lower():find("bone") then
            table.insert(bones,v)
        end
        if v:IsA("Model") and v.Name:lower():find("bone") then
            table.insert(bones,v)
        end
    end
    return bones
end
local function getVolcanoPressure()
    local pressure=0
    for _,v in pairs(workspace:GetDescendants()) do
        if v:IsA("NumberValue") and v.Name:lower():find("pressure") then
            pressure=v.Value
        end
        if v:IsA("IntValue") and v.Name:lower():find("pressure") then
            pressure=v.Value
        end
    end
    return pressure
end
local function getRelicHealth()
    local health=100
    for _,v in pairs(workspace:GetDescendants()) do
        if v:IsA("NumberValue") and v.Name:lower():find("relic") and v.Name:lower():find("health") then
            health=v.Value
        end
    end
    return health
end
local function getEventTimeRemaining()
    local time=300
    for _,v in pairs(workspace:GetDescendants()) do
        if v:IsA("NumberValue") and v.Name:lower():find("time") and v.Name:lower():find("remaining") then
            time=v.Value
        end
        if v:IsA("IntValue") and v.Name:lower():find("time") and v.Name:lower():find("remaining") then
            time=v.Value
        end
    end
    return time
end
local function startVolcanoEvent()
    if eventActive then return false end
    local skullPos=findSkull()
    if skullPos then
        moveToPosition(skullPos,3)
        wait(0.5)
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            wait(0.3)
        end
        eventActive=true
        eventTimer=0
        timeRemaining=300
        volcanoPressure=0
        relicHealth=100
        print("[VolcanoEvent] Event started!")
        return true
    end
    return false
end
local function sealCrack(crack)
    if not crack then return false end
    if not rootPart then return false end
    local dist=getDistance(rootPart.Position,crack.Position)
    if dist>10 then
        moveToPosition(crack.Position,3)
    end
    if humanoid then
        humanoid:BreakJoints()
        wait(0.2)
        cracksSealed=cracksSealed+1
        return true
    end
    return false
end
local function killGolem(golem)
    if not golem then return false end
    if not rootPart then return false end
    local head=golem:FindFirstChild("Head")
    if head then
        rootPart.CFrame=CFrame.new(head.Position+Vector3.new(0,5,0))
        wait(0.1)
        if humanoid then
            humanoid:BreakJoints()
            golemsKilled=golemsKilled+1
            return true
        end
    end
    return false
end
local function collectBone(bone)
    if not bone then return false end
    if not rootPart then return false end
    local dist=getDistance(rootPart.Position,bone.Position)
    if dist>5 then
        moveToPosition(bone.Position,3)
    end
    if dist<5 then
        bone:Destroy()
        bonesCollected=bonesCollected+1
        return true
    end
    return false
end
local function collectEgg(egg)
    if not egg then return false end
    if not rootPart then return false end
    local dist=getDistance(rootPart.Position,egg.Position)
    if dist>5 then
        moveToPosition(egg.Position,3)
    end
    if dist<5 then
        egg:Destroy()
        eggsCollected=eggsCollected+1
        return true
    end
    return false
end
local function collectAllBones()
    local bones=findDinosaurBones()
    local count=0
    for _,bone in ipairs(bones) do
        if collectBone(bone) then
            count=count+1
        end
        wait(0.1)
    end
    return count
end
local function collectAllEggs()
    local eggs=findDragonEggs()
    local count=0
    for _,egg in ipairs(eggs) do
        if collectEgg(egg) then
            count=count+1
        end
        wait(0.1)
    end
    return count
end
local function sealAllCracks()
    local cracks=findVolcanoCracks()
    local count=0
    for _,crack in ipairs(cracks) do
        if sealCrack(crack) then
            count=count+1
        end
        wait(0.2)
    end
    return count
end
local function killAllGolems()
    local golems=findLavaGolems()
    local count=0
    for _,golem in ipairs(golems) do
        if killGolem(golem) then
            count=count+1
        end
        wait(0.3)
    end
    return count
end
local function processVolcanoEvent(data)
    if not data or not data.enabled then
        if isRunning then volcanoEvent.Stop() end
        return
    end
    if not rootPart or not humanoid then updateCharacter() end
    if not rootPart or not humanoid then return end
    if not volcanoIsland or not volcanoIsland.Parent then
        volcanoIsland=findVolcanoIsland()
        if not volcanoIsland then
            if data.autoFind then
                print("[VolcanoEvent] Đang tìm đảo núi lửa...")
            end
            return
        end
        islandPosition=volcanoIsland.Position or volcanoIsland:FindFirstChild("Head").Position
        relicPosition=findRelic()
        skullPosition=findSkull()
        print("[VolcanoEvent] Đã tìm thấy đảo núi lửa!")
    end
    if data.autoMove and islandPosition then
        local dist=getDistance(rootPart.Position,islandPosition)
        if dist>50 then
            moveToPosition(islandPosition,5)
            return
        end
    end
    if data.autoStart and not eventActive then
        startVolcanoEvent()
        return
    end
    if eventActive and not eventCompleted then
        eventTimer=eventTimer+0.1
        volcanoPressure=getVolcanoPressure()
        relicHealth=getRelicHealth()
        timeRemaining=getEventTimeRemaining()
        if data.autoSealCracks then
            local cracks=findVolcanoCracks()
            for _,crack in ipairs(cracks) do
                sealCrack(crack)
                wait(0.1)
            end
        end
        if data.autoKillGolems then
            local golems=findLavaGolems()
            for _,golem in ipairs(golems) do
                killGolem(golem)
                wait(0.2)
            end
        end
        if timeRemaining<=0 or relicHealth<=0 then
            eventCompleted=true
            eventActive=false
            print("[VolcanoEvent] Event hoàn thành!")
            if data.autoCollectBones then
                collectAllBones()
            end
            if data.autoCollectEggs then
                collectAllEggs()
            end
        end
    end
end
local function startVolcanoLoop(data)
    if isRunning then return end
    isRunning=true
    eventActive=false
    eventCompleted=false
    bonesCollected=0
    eggsCollected=0
    golemsKilled=0
    cracksSealed=0
    task.spawn(function()
        while isRunning do
            wait(0.5)
            pcall(function()processVolcanoEvent(data)end)
        end
    end)
end
function volcanoEvent.Stop()
    isRunning=false
    return true
end
function volcanoEvent.Run(data)
    if not data then return false end
    dataRef=data
    if not data.enabled then
        if isRunning then volcanoEvent.Stop() end
        return false
    end
    if not isRunning then
        updateCharacter()
        startVolcanoLoop(data)
    end
    return true
end
function volcanoEvent.FindIsland()
    local island=findVolcanoIsland()
    if island then
        volcanoIsland=island
        islandPosition=island.Position or island:FindFirstChild("Head").Position
        relicPosition=findRelic()
        skullPosition=findSkull()
        return true
    end
    return false
end
function volcanoEvent.StartEvent()
    return startVolcanoEvent()
end
function volcanoEvent.SealCrack(crack)
    return sealCrack(crack)
end
function volcanoEvent.SealAllCracks()
    return sealAllCracks()
end
function volcanoEvent.KillGolem(golem)
    return killGolem(golem)
end
function volcanoEvent.KillAllGolems()
    return killAllGolems()
end
function volcanoEvent.CollectBone(bone)
    return collectBone(bone)
end
function volcanoEvent.CollectAllBones()
    return collectAllBones()
end
function volcanoEvent.CollectEgg(egg)
    return collectEgg(egg)
end
function volcanoEvent.CollectAllEggs()
    return collectAllEggs()
end
function volcanoEvent.GetStatus()
    return{
        isRunning=isRunning,
        islandFound=volcanoIsland~=nil,
        eventActive=eventActive,
        eventCompleted=eventCompleted,
        volcanoPressure=volcanoPressure,
        relicHealth=relicHealth,
        timeRemaining=timeRemaining,
        bonesCollected=bonesCollected,
        eggsCollected=eggsCollected,
        golemsKilled=golemsKilled,
        cracksSealed=cracksSealed
    }
end
function volcanoEvent.GetCracks()
    return findVolcanoCracks()
end
function volcanoEvent.GetGolems()
    return findLavaGolems()
end
function volcanoEvent.GetBones()
    return findDinosaurBones()
end
function volcanoEvent.GetEggs()
    return findDragonEggs()
end
function volcanoEvent.MoveToIsland()
    if islandPosition then
        return moveToPosition(islandPosition,10)
    end
    return false
end
function volcanoEvent.MoveToRelic()
    if relicPosition then
        return moveToPosition(relicPosition,5)
    end
    return false
end
function volcanoEvent.MoveToSkull()
    if skullPosition then
        return moveToPosition(skullPosition,5)
    end
    return false
end
function volcanoEvent.ToggleAutoFind()
    if dataRef then
        dataRef.autoFind=not dataRef.autoFind
        return dataRef.autoFind
    end
    return false
end
function volcanoEvent.ToggleAutoStart()
    if dataRef then
        dataRef.autoStart=not dataRef.autoStart
        return dataRef.autoStart
    end
    return false
end
function volcanoEvent.ToggleAutoSealCracks()
    if dataRef then
        dataRef.autoSealCracks=not dataRef.autoSealCracks
        return dataRef.autoSealCracks
    end
    return false
end
function volcanoEvent.ToggleAutoKillGolems()
    if dataRef then
        dataRef.autoKillGolems=not dataRef.autoKillGolems
        return dataRef.autoKillGolems
    end
    return false
end
function volcanoEvent.ToggleAutoCollectBones()
    if dataRef then
        dataRef.autoCollectBones=not dataRef.autoCollectBones
        return dataRef.autoCollectBones
    end
    return false
end
function volcanoEvent.ToggleAutoCollectEggs()
    if dataRef then
        dataRef.autoCollectEggs=not dataRef.autoCollectEggs
        return dataRef.autoCollectEggs
    end
    return false
end
function volcanoEvent.ResetStats()
    bonesCollected=0
    eggsCollected=0
    golemsKilled=0
    cracksSealed=0
    eventActive=false
    eventCompleted=false
    return true
end
function volcanoEvent.Pause()
    isRunning=false
    return true
end
function volcanoEvent.Resume()
    if dataRef and dataRef.enabled then
        isRunning=true
        startVolcanoLoop(dataRef)
        return true
    end
    return false
end
function volcanoEvent.Destroy()
    volcanoEvent.Stop()
    volcanoIsland=nil
    islandPosition=nil
    relicPosition=nil
    skullPosition=nil
    dataRef=nil
    return true
end
function volcanoEvent.Initialize(data)
    dataRef=data
    updateCharacter()
    if data then
        if data.autoFind==nil then data.autoFind=true end
        if data.autoStart==nil then data.autoStart=true end
        if data.autoSealCracks==nil then data.autoSealCracks=true end
        if data.autoKillGolems==nil then data.autoKillGolems=true end
        if data.autoCollectBones==nil then data.autoCollectBones=true end
        if data.autoCollectEggs==nil then data.autoCollectEggs=true end
    end
    return true
end
return volcanoEvent
