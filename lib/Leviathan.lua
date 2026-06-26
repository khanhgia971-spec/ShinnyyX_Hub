local leviathan={}
leviathan.__index=leviathan
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
local replicatedStorage=game:GetService("ReplicatedStorage")
local dataRef=nil
local isRunning=false
local character=nil local humanoid=nil local rootPart=nil
local currentBoat=nil
local spyBribed=false local frozenDimensionFound=false
local leviathanSpawned=false local leviathanDefeated=false
local leviathanHealth=1000000 local leviathanMaxHealth=1000000
local segmentsDestroyed=0 local totalSegments=4
local leviathanHeartCollected=false local heartHarpooned=false
local heartPosition=nil local boatPosition=nil
local leviathanCooldown=0 local spyCooldown=0
local leviathanKills=0 local leviathanScales=0
local seaEventsCompleted=0 local requiredSeaEvents=10
local explorationGroupSize=0 local requiredGroupSize=5
local beastHunterCrafted=false local beastHunterOwned=false
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
local function findSpy()
    for _,v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") then
            if v.Name:lower():find("spy") then
                return v
            end
        end
        if v:IsA("Model") and v:FindFirstChild("Head") then
            if v.Name:lower():find("spy") then
                return v
            end
        end
    end
    return nil
end
local function findFrozenDimension()
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Model") and v:FindFirstChild("Head") then
            if v.Name:lower():find("frozen") and v.Name:lower():find("dimension") then
                return v
            end
        end
        if v:IsA("Part") and v.Name:lower():find("frozen") then
            return v
        end
        if v:IsA("Model") and v.Name:lower():find("frozen") then
            return v
        end
    end
    for _,v in pairs(workspace:GetDescendants()) do
        if v:IsA("Part") and v.Name:lower():find("frozen") then
            return v
        end
    end
    return nil
end
local function findFrozenWatcher()
    for _,v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") then
            if v.Name:lower():find("frozen") and v.Name:lower():find("watcher") then
                return v
            end
        end
        if v:IsA("Model") and v:FindFirstChild("Head") then
            if v.Name:lower():find("frozen") and v.Name:lower():find("watcher") then
                return v
            end
        end
    end
    return nil
end
local function findLeviathan()
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") then
            if v.Name:lower():find("leviathan") then
                return v
            end
        end
        if v:IsA("Model") and v.Name:lower():find("leviathan") then
            return v
        end
    end
    return nil
end
local function findLeviathanHeart()
    for _,v in pairs(workspace:GetDescendants()) do
        if v:IsA("Part") and v.Name:lower():find("leviathan") and v.Name:lower():find("heart") then
            return v
        end
        if v:IsA("Model") and v.Name:lower():find("leviathan") and v.Name:lower():find("heart") then
            return v
        end
    end
    return nil
end
local function findBeastHunter()
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Model") and v:FindFirstChild("HumanoidRootPart") then
            if v.Name:lower():find("beast") and v.Name:lower():find("hunter") then
                return v
            end
        end
        if v:IsA("Model") and v.Name:lower():find("beast") then
            return v
        end
    end
    for _,v in pairs(workspace:GetDescendants()) do
        if v:IsA("Part") and v.Name:lower():find("beast") and v.Name:lower():find("hunter") then
            return v
        end
    end
    return nil
end
local function getLeviathanHealth()
    local levi=findLeviathan()
    if levi and levi:FindFirstChild("Humanoid") then
        return levi.Humanoid.Health
    end
    return 0
end
local function getLeviathanMaxHealth()
    local levi=findLeviathan()
    if levi and levi:FindFirstChild("Humanoid") then
        return levi.Humanoid.MaxHealth
    end
    return 1000000
end
local function getLeviathanSegments()
    local levi=findLeviathan()
    if levi then
        local count=0
        for _,v in pairs(levi:GetChildren()) do
            if v:IsA("Model") and v:FindFirstChild("Humanoid") then
                count=count+1
            end
        end
        return count
    end
    return 0
end
local function interactWithNPC(npc)
    if not npc or not rootPart then return false end
    local head=npc:FindFirstChild("Head")
    if head then
        rootPart.CFrame=CFrame.new(head.Position+Vector3.new(0,2,0))
        wait(0.3)
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            wait(0.1)
        end
        return true
    end
    return false
end
local function bribeSpy()
    if spyBribed then return true end
    local spy=findSpy()
    if not spy then return false end
    interactWithNPC(spy)
    wait(0.5)
    local chat=game:GetService("Chat")
    if chat then
        chat:SendMessage("/e bribe")
        wait(0.5)
    end
    spyBribed=true
    return true
end
local function checkSpyDialogue()
    local spy=findSpy()
    if not spy then return "unknown" end
    local dialogue=spy:FindFirstChild("Dialogue")
    if dialogue and dialogue:IsA("StringValue") then
        local text=dialogue.Value:lower()
        if text:find("leviathan is out there") then
            return "ready"
        elseif text:find("don't know anything") then
            return "cooldown"
        else
            return "unknown"
        end
    end
    return "unknown"
end
local function findSeaDangerLevel6()
    for _,v in pairs(workspace:GetDescendants()) do
        if v:IsA("Part") and v.Name:lower():find("danger") and v.Name:lower():find("level") then
            if v:FindFirstChild("Level") and v.Level:IsA("NumberValue") and v.Level.Value==6 then
                return v
            end
        end
        if v:IsA("Model") and v.Name:lower():find("danger") then
            return v
        end
    end
    return nil
end
local function spawnLeviathan()
    if leviathanSpawned then return true end
    if leviathanCooldown>tick() then return false end
    if not spyBribed then
        bribeSpy()
        wait(1)
    end
    local frozenDim=findFrozenDimension()
    if not frozenDim then
        print("[Leviathan] Frozen Dimension not found, searching...")
        return false
    end
    local watcher=findFrozenWatcher()
    if not watcher then
        print("[Leviathan] Frozen Watcher not found")
        return false
    end
    local groupSize=#players:GetPlayers()
    if groupSize<5 then
        print("[Leviathan] Need 5+ players in group, current: "..groupSize)
        return false
    end
    interactWithNPC(watcher)
    wait(0.5)
    leviathanSpawned=true
    leviathanCooldown=tick()+1800
    return true
end
local function attackLeviathanSegment(segment)
    if not segment or not rootPart then return false end
    local head=segment:FindFirstChild("Head")
    if head then
        rootPart.CFrame=CFrame.new(head.Position+Vector3.new(0,5,0))
        wait(0.1)
        if humanoid then
            humanoid:BreakJoints()
            segmentsDestroyed=segmentsDestroyed+1
            return true
        end
    end
    return false
end
local function destroyAllSegments()
    local levi=findLeviathan()
    if not levi then return false end
    local count=0
    for _,v in pairs(levi:GetChildren()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") then
            if attackLeviathanSegment(v) then
                count=count+1
            end
            wait(0.2)
        end
    end
    segmentsDestroyed=count
    return count==totalSegments
end
local function damageMainBody()
    local levi=findLeviathan()
    if not levi then return false end
    if segmentsDestroyed<totalSegments then
        destroyAllSegments()
        wait(0.5)
    end
    local head=levi:FindFirstChild("Head")
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
local function defeatLeviathan()
    if leviathanDefeated then return true end
    local levi=findLeviathan()
    if not levi then return false end
    local health=getLeviathanHealth()
    if health<=0 then
        leviathanDefeated=true
        leviathanKills=leviathanKills+1
        leviathanScales=leviathanScales+math.random(1,5)
        print("[Leviathan] Defeated!")
        return true
    end
    if segmentsDestroyed<totalSegments then
        destroyAllSegments()
        wait(0.5)
    end
    damageMainBody()
    return false
end
local function harpoonHeart()
    if heartHarpooned then return true end
    local heart=findLeviathanHeart()
    if not heart then return false end
    local boat=findBeastHunter()
    if not boat then
        print("[Leviathan] Need Beast Hunter boat!")
        return false
    end
    local heartPos=heart.Position
    local boatPos=boat.Position or boat:FindFirstChild("HumanoidRootPart").Position
    if getDistance(rootPart.Position,heartPos)>20 then
        moveToPosition(heartPos+Vector3.new(0,3,0),5)
    end
    wait(0.3)
    local harpoon=Instance.new("Part")
    harpoon.Size=Vector3.new(0.5,0.5,3)
    harpoon.Position=rootPart.Position+Vector3.new(0,3,0)
    harpoon.Anchored=true
    harpoon.BrickColor=BrickColor.new("Bright blue")
    harpoon.Parent=workspace
    debris:AddItem(harpoon,3)
    heart:Destroy()
    heartHarpooned=true
    leviathanHeartCollected=true
    return true
end
local function collectLeviathanHeart()
    if leviathanHeartCollected then return true end
    if not leviathanDefeated then
        defeatLeviathan()
        wait(1)
    end
    return harpoonHeart()
end
local function checkFrozenDimensionSpawn()
    local frozen=findFrozenDimension()
    if frozen then
        frozenDimensionFound=true
        return true
    end
    return false
end
local function sailToFrozenDimension()
    local frozen=findFrozenDimension()
    if not frozen then
        if not frozenDimensionFound then
            print("[Leviathan] Searching for Frozen Dimension...")
        end
        return false
    end
    local pos=frozen.Position or frozen:FindFirstChild("Head").Position
    if pos then
        moveToPosition(pos+Vector3.new(0,5,0),10)
        return true
    end
    return false
end
local function checkLeviathanCooldown()
    return leviathanCooldown>tick()
end
local function getLeviathanCooldownTime()
    return math.max(0,leviathanCooldown-tick())
end
local function checkSpyCooldown()
    return spyCooldown>tick()
end
local function getSpyCooldownTime()
    return math.max(0,spyCooldown-tick())
end
local function completeSeaEvents(count)
    count=count or 1
    seaEventsCompleted=seaEventsCompleted+count
    return seaEventsCompleted
end
local function resetSeaEvents()
    seaEventsCompleted=0
    return true
end
local function getRequiredSeaEvents()
    return requiredSeaEvents
end
local function isLeviathanReady()
    local spyReady=checkSpyDialogue()=="ready"
    local groupReady=#players:GetPlayers()>=5
    local cooldownReady=not checkLeviathanCooldown()
    return spyReady and groupReady and cooldownReady
end
local function getLeviathanStatus()
    return{
        spawned=leviathanSpawned,
        defeated=leviathanDefeated,
        health=getLeviathanHealth(),
        maxHealth=getLeviathanMaxHealth(),
        segments=segmentsDestroyed.."/"..totalSegments,
        heartCollected=leviathanHeartCollected,
        heartHarpooned=heartHarpooned,
        kills=leviathanKills,
        scales=leviathanScales,
        cooldown=getLeviathanCooldownTime(),
        spyReady=checkSpyDialogue()=="ready",
        frozenDimensionFound=frozenDimensionFound
    }
end
local function processLeviathan(data)
    if not data or not data.enabled then
        if isRunning then leviathan.Stop() end
        return
    end
    if not rootPart or not humanoid then updateCharacter() end
    if not rootPart or not humanoid then return end
    if leviathanCooldown>tick() then
        return
    end
    if data.autoBribe and not spyBribed then
        bribeSpy()
        wait(0.5)
    end
    if data.autoFindFrozen then
        if not frozenDimensionFound then
            frozenDimensionFound=checkFrozenDimensionSpawn()
        end
        if frozenDimensionFound and data.autoSail then
            sailToFrozenDimension()
        end
    end
    if data.autoSpawn and frozenDimensionFound and not leviathanSpawned then
        if #players:GetPlayers()>=5 then
            spawnLeviathan()
            wait(1)
        end
    end
    if data.autoFight and leviathanSpawned and not leviathanDefeated then
        defeatLeviathan()
        wait(0.5)
    end
    if data.autoCollectHeart and leviathanDefeated and not leviathanHeartCollected then
        collectLeviathanHeart()
        wait(0.5)
    end
    if data.autoReset and leviathanDefeated and leviathanHeartCollected then
        leviathanSpawned=false
        leviathanDefeated=false
        leviathanHeartCollected=false
        heartHarpooned=false
        segmentsDestroyed=0
        spyBribed=false
    end
end
local function startLeviathanLoop(data)
    if isRunning then return end
    isRunning=true
    leviathanSpawned=false
    leviathanDefeated=false
    leviathanHeartCollected=false
    heartHarpooned=false
    segmentsDestroyed=0
    task.spawn(function()
        while isRunning do
            wait(0.5)
            pcall(function()processLeviathan(data)end)
        end
    end)
end
function leviathan.Stop()
    isRunning=false
    return true
end
function leviathan.Run(data)
    if not data then return false end
    dataRef=data
    if not data.enabled then
        if isRunning then leviathan.Stop() end
        return false
    end
    if not isRunning then
        updateCharacter()
        startLeviathanLoop(data)
    end
    return true
end
function leviathan.FindSpy()
    return findSpy()
end
function leviathan.BribeSpy()
    return bribeSpy()
end
function leviathan.CheckSpyDialogue()
    return checkSpyDialogue()
end
function leviathan.FindFrozenDimension()
    return findFrozenDimension()
end
function leviathan.FindFrozenWatcher()
    return findFrozenWatcher()
end
function leviathan.SailToFrozenDimension()
    return sailToFrozenDimension()
end
function leviathan.SpawnLeviathan()
    return spawnLeviathan()
end
function leviathan.FindLeviathan()
    return findLeviathan()
end
function leviathan.GetLeviathanHealth()
    return getLeviathanHealth()
end
function leviathan.GetLeviathanMaxHealth()
    return getLeviathanMaxHealth()
end
function leviathan.DestroySegments()
    return destroyAllSegments()
end
function leviathan.DamageMainBody()
    return damageMainBody()
end
function leviathan.DefeatLeviathan()
    return defeatLeviathan()
end
function leviathan.FindLeviathanHeart()
    return findLeviathanHeart()
end
function leviathan.HarpoonHeart()
    return harpoonHeart()
end
function leviathan.CollectLeviathanHeart()
    return collectLeviathanHeart()
end
function leviathan.FindBeastHunter()
    return findBeastHunter()
end
function leviathan.GetLeviathanCooldown()
    return getLeviathanCooldownTime()
end
function leviathan.IsLeviathanReady()
    return isLeviathanReady()
end
function leviathan.GetStatus()
    return getLeviathanStatus()
end
function leviathan.SetRequiredGroupSize(size)
    requiredGroupSize=size
    if dataRef then dataRef.requiredGroupSize=size end
    return true
end
function leviathan.SetRequiredSeaEvents(count)
    requiredSeaEvents=count
    if dataRef then dataRef.requiredSeaEvents=count end
    return true
end
function leviathan.CompleteSeaEvents(count)
    return completeSeaEvents(count)
end
function leviathan.ResetSeaEvents()
    return resetSeaEvents()
end
function leviathan.GetSeaEventsCompleted()
    return seaEventsCompleted
end
function leviathan.GetRequiredSeaEvents()
    return requiredSeaEvents
end
function leviathan.IsLeviathanSpawned()
    return leviathanSpawned
end
function leviathan.IsLeviathanDefeated()
    return leviathanDefeated
end
function leviathan.IsHeartCollected()
    return leviathanHeartCollected
end
function leviathan.GetLeviathanKills()
    return leviathanKills
end
function leviathan.GetLeviathanScales()
    return leviathanScales
end
function leviathan.ResetLeviathanState()
    leviathanSpawned=false
    leviathanDefeated=false
    leviathanHeartCollected=false
    heartHarpooned=false
    segmentsDestroyed=0
    spyBribed=false
    frozenDimensionFound=false
    return true
end
function leviathan.ToggleAutoBribe()
    if dataRef then
        dataRef.autoBribe=not dataRef.autoBribe
        return dataRef.autoBribe
    end
    return false
end
function leviathan.ToggleAutoFindFrozen()
    if dataRef then
        dataRef.autoFindFrozen=not dataRef.autoFindFrozen
        return dataRef.autoFindFrozen
    end
    return false
end
function leviathan.ToggleAutoSail()
    if dataRef then
        dataRef.autoSail=not dataRef.autoSail
        return dataRef.autoSail
    end
    return false
end
function leviathan.ToggleAutoSpawn()
    if dataRef then
        dataRef.autoSpawn=not dataRef.autoSpawn
        return dataRef.autoSpawn
    end
    return false
end
function leviathan.ToggleAutoFight()
    if dataRef then
        dataRef.autoFight=not dataRef.autoFight
        return dataRef.autoFight
    end
    return false
end
function leviathan.ToggleAutoCollectHeart()
    if dataRef then
        dataRef.autoCollectHeart=not dataRef.autoCollectHeart
        return dataRef.autoCollectHeart
    end
    return false
end
function leviathan.ToggleAutoReset()
    if dataRef then
        dataRef.autoReset=not dataRef.autoReset
        return dataRef.autoReset
    end
    return false
end
function leviathan.SetCooldown(cooldown)
    leviathanCooldown=cooldown
    if dataRef then dataRef.cooldown=cooldown end
    return true
end
function leviathan.Pause()
    isRunning=false
    return true
end
function leviathan.Resume()
    if dataRef and dataRef.enabled then
        isRunning=true
        startLeviathanLoop(dataRef)
        return true
    end
    return false
end
function leviathan.Destroy()
    leviathan.Stop()
    leviathanSpawned=false
    leviathanDefeated=false
    leviathanHeartCollected=false
    heartHarpooned=false
    segmentsDestroyed=0
    spyBribed=false
    frozenDimensionFound=false
    dataRef=nil
    return true
end
function leviathan.Initialize(data)
    dataRef=data
    updateCharacter()
    if data then
        if data.autoBribe==nil then data.autoBribe=true end
        if data.autoFindFrozen==nil then data.autoFindFrozen=true end
        if data.autoSail==nil then data.autoSail=true end
        if data.autoSpawn==nil then data.autoSpawn=true end
        if data.autoFight==nil then data.autoFight=true end
        if data.autoCollectHeart==nil then data.autoCollectHeart=true end
        if data.autoReset==nil then data.autoReset=true end
        if data.requiredGroupSize then requiredGroupSize=data.requiredGroupSize end
        if data.requiredSeaEvents then requiredSeaEvents=data.requiredSeaEvents end
        if data.cooldown then leviathanCooldown=data.cooldown end
    end
    return true
end
return leviathan
