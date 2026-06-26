local teleport={}
teleport.__index=teleport
local player=game.Players.LocalPlayer
local runService=game:GetService("RunService")
local userInput=game:GetService("UserInputService")
local tweenService=game:GetService("TweenService")
local workspace=game:GetService("Workspace")
local replicatedStorage=game:GetService("ReplicatedStorage")
local players=game:GetService("Players")
local collectionService=game:GetService("CollectionService")
local debris=game:GetService("Debris")
local httpService=game:GetService("HttpService")
local teleportService=game:GetService("TeleportService")
local guiService=game:GetService("GuiService")
local character=nil local humanoid=nil local rootPart=nil
local dataRef=nil local isRunning=false
local targetPosition=Vector3.new(0,0,0) local targetPlayer="" local islandName=""
local savedLocations={} local hotkeys={} local teleportHistory={} local autoRejoin=false
local ISLANDS_SEA1={
    {name="Jungle",pos=Vector3.new(-1000,50,0),level=0},
    {name="Pirate Village",pos=Vector3.new(0,50,1000),level=0},
    {name="Marine Fort",pos=Vector3.new(1000,50,0),level=0},
    {name="Sky",pos=Vector3.new(0,500,0),level=200},
    {name="Magma",pos=Vector3.new(-500,50,-500),level=250},
    {name="Ice",pos=Vector3.new(500,50,-500),level=300},
    {name="Desert",pos=Vector3.new(0,50,-1000),level=400},
    {name="Fountain",pos=Vector3.new(300,10,800),level=600},
    {name="Prison",pos=Vector3.new(-500,30,400),level=200},
    {name="Colosseum",pos=Vector3.new(-400,40,500),level=0}
}
local ISLANDS_SEA2={
    {name="Kingdom of Rose",pos=Vector3.new(0,10,0),level=700},
    {name="Hydra Island",pos=Vector3.new(200,20,300),level=700},
    {name="Tiki Outpost",pos=Vector3.new(400,15,500),level=700},
    {name="Submerged Island",pos=Vector3.new(600,0,700),level=700},
    {name="Sea of Treats",pos=Vector3.new(800,10,900),level=700},
    {name="Castle on Sea",pos=Vector3.new(1000,20,1100),level=700},
    {name="Frozen Dimension",pos=Vector3.new(200,10,200),level=700,isFrozen=true},
    {name="Prehistoric Island",pos=Vector3.new(300,10,400),level=700,isVolcano=true}
}
local ISLANDS_SEA3={
    {name="Hydra Island",pos=Vector3.new(200,20,300),level=1500},
    {name="Tiki Outpost",pos=Vector3.new(400,15,500),level=1500},
    {name="Sea of Treats",pos=Vector3.new(800,10,900),level=1500},
    {name="Castle on Sea",pos=Vector3.new(1000,20,1100),level=1500},
    {name="Prehistoric Island",pos=Vector3.new(300,10,400),level=1500},
    {name="Frozen Dimension",pos=Vector3.new(200,10,200),level=1500}
}
local NPCS={
    {name="Bandit",pos=Vector3.new(-100,10,0),sea=1},
    {name="Gorilla",pos=Vector3.new(-300,20,200),sea=1},
    {name="Gorilla King",pos=Vector3.new(-320,25,220),sea=1},
    {name="Pirate",pos=Vector3.new(200,10,-100),sea=1},
    {name="Bobby",pos=Vector3.new(250,15,-80),sea=1},
    {name="Galley Pirate",pos=Vector3.new(500,10,300),sea=1},
    {name="Galley Captain",pos=Vector3.new(520,15,320),sea=1},
    {name="The Saw",pos=Vector3.new(0,10,500),sea=1},
    {name="Yeti",pos=Vector3.new(-200,15,600),sea=1},
    {name="Mob Leader",pos=Vector3.new(-400,20,700),sea=1},
    {name="Vice Admiral",pos=Vector3.new(800,10,-200),sea=1},
    {name="Marine Soldier",pos=Vector3.new(850,15,-180),sea=1},
    {name="Saber Expert",pos=Vector3.new(-400,20,300),sea=1},
    {name="Warden",pos=Vector3.new(-500,30,400),sea=1},
    {name="Chief Warden",pos=Vector3.new(-480,35,420),sea=1},
    {name="Swan",pos=Vector3.new(-450,40,380),sea=1},
    {name="Magma Admiral",pos=Vector3.new(600,10,-400),sea=1},
    {name="Magma Ninja",pos=Vector3.new(620,15,-380),sea=1},
    {name="Fishman",pos=Vector3.new(0,-50,1000),sea=1},
    {name="Fishman Lord",pos=Vector3.new(20,-40,1020),sea=1},
    {name="Sky Bandit",pos=Vector3.new(200,200,0),sea=1},
    {name="Wysper",pos=Vector3.new(220,220,20),sea=1},
    {name="Sky Knight",pos=Vector3.new(180,250,0),sea=1},
    {name="Thunder God",pos=Vector3.new(200,300,0),sea=1},
    {name="Fountain Soldier",pos=Vector3.new(300,10,800),sea=1},
    {name="Cyborg",pos=Vector3.new(320,15,820),sea=1},
    {name="Ice Admiral",pos=Vector3.new(-200,15,600),sea=1},
    {name="Experienced Captain",pos=Vector3.new(0,10,0),sea=2},
    {name="Diamond",pos=Vector3.new(200,20,300),sea=2},
    {name="Swan Pirate",pos=Vector3.new(300,10,400),sea=2},
    {name="Jeremy",pos=Vector3.new(320,25,420),sea=2},
    {name="Orbitus",pos=Vector3.new(400,10,500),sea=2},
    {name="Don Swan",pos=Vector3.new(450,30,550),sea=2},
    {name="Bounty Hunter",pos=Vector3.new(550,10,650),sea=2},
    {name="Smoke Admiral",pos=Vector3.new(600,20,700),sea=2},
    {name="Ice Soldier",pos=Vector3.new(700,15,800),sea=2},
    {name="Ice Commander",pos=Vector3.new(720,20,820),sea=2},
    {name="Awakened Ice Admiral",pos=Vector3.new(800,30,900),sea=2},
    {name="Tide Keeper",pos=Vector3.new(900,20,1000),sea=2},
    {name="rip_indra",pos=Vector3.new(1000,40,1100),sea=2},
    {name="Bartilo",pos=Vector3.new(100,10,100),sea=3},
    {name="King Red Head",pos=Vector3.new(200,20,200),sea=3},
    {name="Stone",pos=Vector3.new(200,10,300),sea=3},
    {name="Island Empress",pos=Vector3.new(350,20,450),sea=3},
    {name="Kilo Admiral",pos=Vector3.new(400,30,500),sea=3},
    {name="Captain Elephant",pos=Vector3.new(500,20,600),sea=3},
    {name="Beautiful Pirate",pos=Vector3.new(550,15,650),sea=3},
    {name="Longma",pos=Vector3.new(600,25,700),sea=3},
    {name="Cursed Skeleton",pos=Vector3.new(650,20,750),sea=3},
    {name="Elite Pirate",pos=Vector3.new(700,10,800),sea=3},
    {name="Cake Soldier",pos=Vector3.new(750,10,850),sea=3},
    {name="Cake Queen",pos=Vector3.new(800,20,900),sea=3},
    {name="Cake Prince",pos=Vector3.new(850,30,950),sea=3},
    {name="Dough King",pos=Vector3.new(900,40,1000),sea=3},
    {name="Soul Reaper",pos=Vector3.new(950,50,1050),sea=3},
    {name="Terrorshark",pos=Vector3.new(1000,20,1100),sea=3},
    {name="Leviathan",pos=Vector3.new(1100,30,1200),sea=3},
    {name="Raid Boss",pos=Vector3.new(1200,40,1300),sea=3}
}
local BOSSES={
    {name="Gorilla King",pos=Vector3.new(-320,25,220),sea=1},
    {name="Bobby",pos=Vector3.new(250,15,-80),sea=1},
    {name="The Saw",pos=Vector3.new(0,10,500),sea=1},
    {name="Mob Leader",pos=Vector3.new(-400,20,700),sea=1},
    {name="Vice Admiral",pos=Vector3.new(800,10,-200),sea=1},
    {name="Saber Expert",pos=Vector3.new(-400,20,300),sea=1},
    {name="Warden",pos=Vector3.new(-500,30,400),sea=1},
    {name="Chief Warden",pos=Vector3.new(-480,35,420),sea=1},
    {name="Swan",pos=Vector3.new(-450,40,380),sea=1},
    {name="Magma Admiral",pos=Vector3.new(600,10,-400),sea=1},
    {name="Fishman Lord",pos=Vector3.new(20,-40,1020),sea=1},
    {name="Wysper",pos=Vector3.new(220,220,20),sea=1},
    {name="Thunder God",pos=Vector3.new(200,300,0),sea=1},
    {name="Cyborg",pos=Vector3.new(320,15,820),sea=1},
    {name="Ice Admiral",pos=Vector3.new(-200,15,600),sea=1},
    {name="Diamond",pos=Vector3.new(200,20,300),sea=2},
    {name="Jeremy",pos=Vector3.new(320,25,420),sea=2},
    {name="Orbitus",pos=Vector3.new(400,10,500),sea=2},
    {name="Don Swan",pos=Vector3.new(450,30,550),sea=2},
    {name="Smoke Admiral",pos=Vector3.new(600,20,700),sea=2},
    {name="Ice Commander",pos=Vector3.new(720,20,820),sea=2},
    {name="Awakened Ice Admiral",pos=Vector3.new(800,30,900),sea=2},
    {name="Tide Keeper",pos=Vector3.new(900,20,1000),sea=2},
    {name="rip_indra",pos=Vector3.new(1000,40,1100),sea=2},
    {name="Stone",pos=Vector3.new(200,10,300),sea=3},
    {name="Island Empress",pos=Vector3.new(350,20,450),sea=3},
    {name="Kilo Admiral",pos=Vector3.new(400,30,500),sea=3},
    {name="Captain Elephant",pos=Vector3.new(500,20,600),sea=3},
    {name="Beautiful Pirate",pos=Vector3.new(550,15,650),sea=3},
    {name="Longma",pos=Vector3.new(600,25,700),sea=3},
    {name="Cursed Skeleton",pos=Vector3.new(650,20,750),sea=3},
    {name="Elite Pirate",pos=Vector3.new(700,10,800),sea=3},
    {name="Cake Queen",pos=Vector3.new(800,20,900),sea=3},
    {name="Cake Prince",pos=Vector3.new(850,30,950),sea=3},
    {name="Dough King",pos=Vector3.new(900,40,1000),sea=3},
    {name="Soul Reaper",pos=Vector3.new(950,50,1050),sea=3},
    {name="Terrorshark",pos=Vector3.new(1000,20,1100),sea=3},
    {name="Leviathan",pos=Vector3.new(1100,30,1200),sea=3},
    {name="Raid Boss",pos=Vector3.new(1200,40,1300),sea=3}
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
local function moveToPosition(position,timeout)
    timeout=timeout or 5
    if not rootPart then return false end
    local dist=getDistance(rootPart.Position,position)
    if dist<5 then return true end
    local tweenInfo=TweenInfo.new(dist/60,Enum.EasingStyle.Linear)
    local tween=tweenService:Create(rootPart,tweenInfo,{CFrame=CFrame.new(position)})
    tween:Play()
    local start=tick()
    repeat wait(0.1) until not tween.PlaybackState==Enum.PlaybackState.Playing or tick()-start>timeout
    return getDistance(rootPart.Position,position)<10
end
local function teleportToPosition(position)
    if rootPart then
        rootPart.CFrame=CFrame.new(position)
        return true
    end
    return false
end
local function findIslandPosition(islandName)
    for _,island in ipairs(ISLANDS_SEA1) do
        if island.name:lower()==islandName:lower() then return island.pos end
    end
    for _,island in ipairs(ISLANDS_SEA2) do
        if island.name:lower()==islandName:lower() then return island.pos end
    end
    for _,island in ipairs(ISLANDS_SEA3) do
        if island.name:lower()==islandName:lower() then return island.pos end
    end
    return nil
end
local function findNPCByName(npcName)
    for _,npc in ipairs(NPCS) do
        if npc.name:lower()==npcName:lower() then
            for _,v in pairs(workspace:GetChildren()) do
                if v:IsA("Model") and v:FindFirstChild("Head") then
                    if v.Name:lower():find(npcName:lower()) then
                        return v.Head.Position
                    end
                end
            end
            return npc.pos
        end
    end
    return nil
end
local function findBossByName(bossName)
    for _,boss in ipairs(BOSSES) do
        if boss.name:lower()==bossName:lower() then
            for _,v in pairs(workspace:GetChildren()) do
                if v:IsA("Model") and v:FindFirstChild("Head") then
                    if v.Name:lower():find(bossName:lower()) then
                        return v.Head.Position
                    end
                end
            end
            return boss.pos
        end
    end
    return nil
end
local function findPlayerByName(playerName)
    for _,p in pairs(players:GetPlayers()) do
        if p.Name:lower()==playerName:lower() and p~=player then
            local char=p.Character
            if char and char:FindFirstChild("Head") then
                return char.Head.Position
            end
        end
    end
    return nil
end
local function saveLocation(name,position)
    savedLocations[name]=position
    return true
end
local function loadLocation(name)
    return savedLocations[name] or nil
end
local function deleteLocation(name)
    savedLocations[name]=nil
    return true
end
local function listLocations()
    local list={}
    for k,_ in pairs(savedLocations) do
        table.insert(list,k)
    end
    return list
end
local function addToHistory(position)
    table.insert(teleportHistory,{position=position,time=os.time()})
    if #teleportHistory>50 then table.remove(teleportHistory,1) end
end
local function getHistory()
    return teleportHistory
end
local function clearHistory()
    teleportHistory={}
    return true
end
local function teleportToIsland(islandName,heightOffset)
    heightOffset=heightOffset or 10
    local pos=findIslandPosition(islandName)
    if pos then
        pos=pos+Vector3.new(0,heightOffset,0)
        if teleportToPosition(pos) then
            addToHistory(pos)
            return true
        end
    end
    return false
end
local function teleportToNPC(npcName,heightOffset)
    heightOffset=heightOffset or 5
    local pos=findNPCByName(npcName)
    if pos then
        pos=pos+Vector3.new(0,heightOffset,0)
        if teleportToPosition(pos) then
            addToHistory(pos)
            return true
        end
    end
    return false
end
local function teleportToBoss(bossName,heightOffset)
    heightOffset=heightOffset or 10
    local pos=findBossByName(bossName)
    if pos then
        pos=pos+Vector3.new(0,heightOffset,0)
        if teleportToPosition(pos) then
            addToHistory(pos)
            return true
        end
    end
    return false
end
local function teleportToPlayer(playerName,heightOffset)
    heightOffset=heightOffset or 5
    local pos=findPlayerByName(playerName)
    if pos then
        pos=pos+Vector3.new(0,heightOffset,0)
        if teleportToPosition(pos) then
            addToHistory(pos)
            return true
        end
    end
    return false
end
local function teleportToSaved(name,heightOffset)
    heightOffset=heightOffset or 0
    local pos=loadLocation(name)
    if pos then
        pos=pos+Vector3.new(0,heightOffset,0)
        if teleportToPosition(pos) then
            addToHistory(pos)
            return true
        end
    end
    return false
end
local function teleportHome()
    local home=Vector3.new(0,10,0)
    if teleportToPosition(home) then
        addToHistory(home)
        return true
    end
    return false
end
local function randomTeleport(min,max)
    min=min or -2000
    max=max or 2000
    local pos=Vector3.new(math.random(min,max),math.random(10,500),math.random(min,max))
    if teleportToPosition(pos) then
        addToHistory(pos)
        return true
    end
    return false
end
local function teleportToNearestPlayer(heightOffset)
    heightOffset=heightOffset or 5
    local nearest=nil
    local minDist=math.huge
    for _,p in pairs(players:GetPlayers()) do
        if p~=player then
            local char=p.Character
            if char and char:FindFirstChild("Head") then
                local dist=getDistance(rootPart.Position,char.Head.Position)
                if dist<minDist then
                    minDist=dist
                    nearest=char.Head.Position
                end
            end
        end
    end
    if nearest then
        nearest=nearest+Vector3.new(0,heightOffset,0)
        if teleportToPosition(nearest) then
            addToHistory(nearest)
            return true
        end
    end
    return false
end
local function teleportToNearestNPC(heightOffset)
    heightOffset=heightOffset or 5
    local nearest=nil
    local minDist=math.huge
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Model") and v:FindFirstChild("Head") and v:FindFirstChild("IsNPC") then
            local dist=getDistance(rootPart.Position,v.Head.Position)
            if dist<minDist then
                minDist=dist
                nearest=v.Head.Position
            end
        end
    end
    if nearest then
        nearest=nearest+Vector3.new(0,heightOffset,0)
        if teleportToPosition(nearest) then
            addToHistory(nearest)
            return true
        end
    end
    return false
end
local function teleportToNearestBoss(heightOffset)
    heightOffset=heightOffset or 10
    local nearest=nil
    local minDist=math.huge
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Model") and v:FindFirstChild("Head") and v:FindFirstChild("IsBoss") then
            local dist=getDistance(rootPart.Position,v.Head.Position)
            if dist<minDist then
                minDist=dist
                nearest=v.Head.Position
            end
        end
    end
    if nearest then
        nearest=nearest+Vector3.new(0,heightOffset,0)
        if teleportToPosition(nearest) then
            addToHistory(nearest)
            return true
        end
    end
    return false
end
local function teleportToNearestFruit(heightOffset)
    heightOffset=heightOffset or 2
    local nearest=nil
    local minDist=math.huge
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Part") and v:FindFirstChild("FruitTag") then
            local dist=getDistance(rootPart.Position,v.Position)
            if dist<minDist then
                minDist=dist
                nearest=v.Position
            end
        end
    end
    if nearest then
        nearest=nearest+Vector3.new(0,heightOffset,0)
        if teleportToPosition(nearest) then
            addToHistory(nearest)
            return true
        end
    end
    return false
end
local function teleportToSea(seaNumber)
    if seaNumber==1 then return teleportHome()
    elseif seaNumber==2 then
        local pos=Vector3.new(0,10,0)
        return teleportToPosition(pos)
    elseif seaNumber==3 then
        local pos=Vector3.new(200,20,200)
        return teleportToPosition(pos)
    end
    return false
end
local function getCurrentSea()
    local sea=player:FindFirstChild("CurrentSea")
    if sea and sea:IsA("NumberValue") then
        return sea.Value
    end
    return 1
end
local function getAllIslands(sea)
    if sea==1 then return ISLANDS_SEA1
    elseif sea==2 then return ISLANDS_SEA2
    elseif sea==3 then return ISLANDS_SEA3
    else
        local all={}
        for _,v in ipairs(ISLANDS_SEA1) do table.insert(all,v) end
        for _,v in ipairs(ISLANDS_SEA2) do table.insert(all,v) end
        for _,v in ipairs(ISLANDS_SEA3) do table.insert(all,v) end
        return all
    end
end
local function getAllNPCs()
    local list={}
    for _,v in ipairs(NPCS) do
        table.insert(list,v.name)
    end
    return list
end
local function getAllBosses()
    local list={}
    for _,v in ipairs(BOSSES) do
        table.insert(list,v.name)
    end
    return list
end
local function getIslandLevel(islandName)
    for _,island in ipairs(ISLANDS_SEA1) do
        if island.name:lower()==islandName:lower() then return island.level end
    end
    for _,island in ipairs(ISLANDS_SEA2) do
        if island.name:lower()==islandName:lower() then return island.level end
    end
    for _,island in ipairs(ISLANDS_SEA3) do
        if island.name:lower()==islandName:lower() then return island.level end
    end
    return 0
end
local function rejoinServer()
    if teleportService then
        local placeId=game.PlaceId
        local jobId=game.JobId
        teleportService:Teleport(placeId,player,{},jobId)
        return true
    end
    return false
end
local function setAutoRejoin(value)
    autoRejoin=value
    return true
end
local function getServerId()
    return game.JobId
end
local function checkRejoin()
    if autoRejoin then
        if not player.Parent then
            rejoinServer()
        end
    end
end
local function startRejoinLoop()
    task.spawn(function()
        while true do
            wait(10)
            checkRejoin()
        end
    end)
end
local function teleportToCoordinates(x,y,z)
    return teleportToPosition(Vector3.new(x,y,z))
end
local function teleportToSafeZone()
    return teleportToPosition(Vector3.new(0,20,0))
end
local function teleportToSky()
    return teleportToPosition(Vector3.new(0,500,0))
end
local function teleportToUnderwater()
    return teleportToPosition(Vector3.new(0,-50,0))
end
local function teleportToPrehistoricIsland()
    return teleportToIsland("Prehistoric Island",10)
end
local function teleportToFrozenDimension()
    return teleportToIsland("Frozen Dimension",10)
end
local function teleportToSeaOfTreats()
    return teleportToIsland("Sea of Treats",10)
end
local function teleportToCastleOnSea()
    return teleportToIsland("Castle on Sea",10)
end
local function teleportToTikiOutpost()
    return teleportToIsland("Tiki Outpost",10)
end
local function teleportToHydraIsland()
    return teleportToIsland("Hydra Island",10)
end
local function teleportToRandomIsland()
    local islands=getAllIslands()
    if #islands>0 then
        local island=islands[math.random(1,#islands)]
        return teleportToIsland(island.name)
    end
    return false
end
local function teleportToRandomPlayer()
    local others={}
    for _,p in pairs(players:GetPlayers()) do
        if p~=player then table.insert(others,p) end
    end
    if #others>0 then
        return teleportToPlayer(others[math.random(1,#others)].Name)
    end
    return false
end
local function teleportToRandomBoss()
    local bosses=getAllBosses()
    if #bosses>0 then
        return teleportToBoss(bosses[math.random(1,#bosses)])
    end
    return false
end
local function teleportToRandomNPC()
    local npcs=getAllNPCs()
    if #npcs>0 then
        return teleportToNPC(npcs[math.random(1,#npcs)])
    end
    return false
end
local function setTargetPosition(position)
    targetPosition=position
    return true
end
local function setTargetPlayer(playerName)
    targetPlayer=playerName
    return true
end
local function setIsland(island)
    islandName=island
    return true
end
local function getTargetPosition()
    return targetPosition
end
local function getTargetPlayer()
    return targetPlayer
end
local function getIsland()
    return islandName
end
local function teleportToTarget()
    if targetPosition~=Vector3.new(0,0,0) then
        return teleportToPosition(targetPosition)
    elseif targetPlayer~="" then
        return teleportToPlayer(targetPlayer)
    elseif islandName~="" then
        return teleportToIsland(islandName)
    end
    return false
end
local function addHotkey(key,action)
    hotkeys[key]=action
    return true
end
local function removeHotkey(key)
    hotkeys[key]=nil
    return true
end
local function getHotkeys()
    return hotkeys
end
local function handleHotkeys(input)
    if input.UserInputType==Enum.UserInputType.Keyboard then
        local key=input.KeyCode
        if hotkeys[key] then
            local action=hotkeys[key]
            if type(action)=="string" then
                if action=="Home" then teleportHome()
                elseif action=="Random" then randomTeleport()
                elseif action=="NearestPlayer" then teleportToNearestPlayer()
                elseif action=="NearestNPC" then teleportToNearestNPC()
                elseif action=="NearestBoss" then teleportToNearestBoss()
                elseif action=="NearestFruit" then teleportToNearestFruit()
                elseif action=="Sea1" then teleportToSea(1)
                elseif action=="Sea2" then teleportToSea(2)
                elseif action=="Sea3" then teleportToSea(3)
                elseif action=="Frozen" then teleportToFrozenDimension()
                elseif action=="Prehistoric" then teleportToPrehistoricIsland()
                end
            elseif type(action)=="function" then
                action()
            end
        end
    end
end
local function startTeleportLoop()
    isRunning=true
    task.spawn(function()
        while isRunning do
            wait(0.5)
            if targetPosition~=Vector3.new(0,0,0) then
                teleportToTarget()
            end
        end
    end)
end
function teleport.Stop()
    isRunning=false
    return true
end
function teleport.Run(data)
    if not data then return false end
    dataRef=data
    if not isRunning then
        startTeleportLoop()
    end
    return true
end
function teleport.TeleportTo(position)
    return teleportToPosition(position)
end
function teleport.TeleportToIsland(islandName,heightOffset)
    return teleportToIsland(islandName,heightOffset)
end
function teleport.TeleportToNPC(npcName,heightOffset)
    return teleportToNPC(npcName,heightOffset)
end
function teleport.TeleportToBoss(bossName,heightOffset)
    return teleportToBoss(bossName,heightOffset)
end
function teleport.TeleportToPlayer(playerName,heightOffset)
    return teleportToPlayer(playerName,heightOffset)
end
function teleport.TeleportToSaved(name,heightOffset)
    return teleportToSaved(name,heightOffset)
end
function teleport.TeleportHome()
    return teleportHome()
end
function teleport.TeleportRandom(min,max)
    return randomTeleport(min,max)
end
function teleport.TeleportToNearestPlayer(heightOffset)
    return teleportToNearestPlayer(heightOffset)
end
function teleport.TeleportToNearestNPC(heightOffset)
    return teleportToNearestNPC(heightOffset)
end
function teleport.TeleportToNearestBoss(heightOffset)
    return teleportToNearestBoss(heightOffset)
end
function teleport.TeleportToNearestFruit(heightOffset)
    return teleportToNearestFruit(heightOffset)
end
function teleport.TeleportToSea(seaNumber)
    return teleportToSea(seaNumber)
end
function teleport.TeleportToCoordinates(x,y,z)
    return teleportToCoordinates(x,y,z)
end
function teleport.TeleportToSafeZone()
    return teleportToSafeZone()
end
function teleport.TeleportToSky()
    return teleportToSky()
end
function teleport.TeleportToUnderwater()
    return teleportToUnderwater()
end
function teleport.TeleportToPrehistoricIsland()
    return teleportToPrehistoricIsland()
end
function teleport.TeleportToFrozenDimension()
    return teleportToFrozenDimension()
end
function teleport.TeleportToSeaOfTreats()
    return teleportToSeaOfTreats()
end
function teleport.TeleportToCastleOnSea()
    return teleportToCastleOnSea()
end
function teleport.TeleportToTikiOutpost()
    return teleportToTikiOutpost()
end
function teleport.TeleportToHydraIsland()
    return teleportToHydraIsland()
end
function teleport.TeleportToRandomIsland()
    return teleportToRandomIsland()
end
function teleport.TeleportToRandomPlayer()
    return teleportToRandomPlayer()
end
function teleport.TeleportToRandomBoss()
    return teleportToRandomBoss()
end
function teleport.TeleportToRandomNPC()
    return teleportToRandomNPC()
end
function teleport.SaveLocation(name,position)
    return saveLocation(name,position)
end
function teleport.LoadLocation(name)
    return loadLocation(name)
end
function teleport.DeleteLocation(name)
    return deleteLocation(name)
end
function teleport.ListLocations()
    return listLocations()
end
function teleport.SetTarget(position)
    return setTargetPosition(position)
end
function teleport.SetTargetPlayer(playerName)
    return setTargetPlayer(playerName)
end
function teleport.SetIsland(island)
    return setIsland(island)
end
function teleport.GetTarget()
    return getTargetPosition()
end
function teleport.GetTargetPlayer()
    return getTargetPlayer()
end
function teleport.GetIsland()
    return getIsland()
end
function teleport.TeleportToTarget()
    return teleportToTarget()
end
function teleport.AddHotkey(key,action)
    return addHotkey(key,action)
end
function teleport.RemoveHotkey(key)
    return removeHotkey(key)
end
function teleport.GetHotkeys()
    return getHotkeys()
end
function teleport.RejoinServer()
    return rejoinServer()
end
function teleport.SetAutoRejoin(value)
    return setAutoRejoin(value)
end
function teleport.GetServerId()
    return getServerId()
end
function teleport.GetHistory()
    return getHistory()
end
function teleport.ClearHistory()
    return clearHistory()
end
function teleport.GetAllIslands(sea)
    return getAllIslands(sea)
end
function teleport.GetAllNPCs()
    return getAllNPCs()
end
function teleport.GetAllBosses()
    return getAllBosses()
end
function teleport.GetIslandLevel(islandName)
    return getIslandLevel(islandName)
end
function teleport.GetCurrentSea()
    return getCurrentSea()
end
function teleport.IsRunning()
    return isRunning
end
function teleport.Pause()
    isRunning=false
    return true
end
function teleport.Resume()
    if dataRef then
        isRunning=true
        startTeleportLoop()
        return true
    end
    return false
end
function teleport.Destroy()
    isRunning=false
    dataRef=nil
    targetPosition=Vector3.new(0,0,0)
    targetPlayer=""
    islandName=""
    savedLocations={}
    hotkeys={}
    teleportHistory={}
    return true
end
function teleport.Initialize(data)
    dataRef=data
    updateCharacter()
    startRejoinLoop()
    userInput.InputBegan:Connect(function(input,gameProcessed)
        if not gameProcessed then handleHotkeys(input) end
    end)
    return true
end
return teleport
