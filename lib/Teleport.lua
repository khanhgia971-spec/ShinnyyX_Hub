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
local character=nil local humanoid=nil local rootPart=nil local dataRef=nil local isRunning=false local targetPosition=Vector3.new(0,0,0) local targetPlayer="" local islandName="" local savedLocations={} local hotkeys={} local teleportHistory={} local autoRejoin=false local serverId=""
local function updateCharacter()
    character=player.Character or player.CharacterAdded:Wait()
    if character then
        humanoid=character:FindFirstChild("Humanoid")
        rootPart=character:FindFirstChild("HumanoidRootPart")
    end
end
local function getDistance(pos1,pos2)
    return (pos1-pos2).Magnitude
end
local function moveTo(position,timeout)
    timeout=timeout or 5
    local startTime=tick()
    local success=false
    if rootPart then
        local tweenInfo=TweenInfo.new((getDistance(rootPart.Position,position)/60),Enum.EasingStyle.Linear)
        local tween=tweenService:Create(rootPart,tweenInfo,{CFrame=CFrame.new(position)})
        tween:Play()
        repeat wait(0.1) until not tween.PlaybackState==Enum.PlaybackState.Playing or tick()-startTime>timeout
        if getDistance(rootPart.Position,position)<5 then
            success=true
        end
    end
    return success
end
local function teleportToPosition(position)
    if rootPart then
        rootPart.CFrame=CFrame.new(position)
        return true
    end
    return false
end
local function findIslandPosition(islandName)
    local islands={
        Jungle=Vector3.new(-1000,50,0),
        Pirate=Vector3.new(0,50,1000),
        Marine=Vector3.new(1000,50,0),
        Sky=Vector3.new(0,500,0),
        Magma=Vector3.new(-500,50,-500),
        Ice=Vector3.new(500,50,-500),
        Desert=Vector3.new(0,50,-1000),
        Volcano=Vector3.new(-1000,100,-1000),
        Underwater=Vector3.new(0,-100,0),
        Kingdom=Vector3.new(2000,50,2000)
    }
    return islands[islandName] or nil
end
local function findNPCByName(npcName)
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Model") and v:FindFirstChild("Head") then
            if v.Name:lower()==npcName:lower() and v:FindFirstChild("IsNPC") then
                return v.Head.Position
            end
        end
    end
    return nil
end
local function findPlayerByName(playerName)
    for _,v in pairs(players:GetPlayers()) do
        if v.Name:lower()==playerName:lower() and v~=player then
            local char=v.Character
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
    for k,v in pairs(savedLocations) do
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
local function teleportToBoss(bossName,heightOffset)
    heightOffset=heightOffset or 10
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Model") and v:FindFirstChild("Head") and v:FindFirstChild("IsBoss") then
            if v.Name:lower()==bossName:lower() then
                local pos=v.Head.Position+Vector3.new(0,heightOffset,0)
                if teleportToPosition(pos) then
                    addToHistory(pos)
                    return true
                end
            end
        end
    end
    return false
end
local function teleportToFruit(fruitName,heightOffset)
    heightOffset=heightOffset or 2
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Part") and v:FindFirstChild("FruitTag") then
            local tag=v:FindFirstChild("FruitTag")
            if tag and tag.Value:lower()==fruitName:lower() then
                local pos=v.Position+Vector3.new(0,heightOffset,0)
                if teleportToPosition(pos) then
                    addToHistory(pos)
                    return true
                end
            end
        end
    end
    return false
end
local function teleportToNearestPlayer(heightOffset)
    heightOffset=heightOffset or 5
    local nearest=nil
    local minDist=math.huge
    for _,v in pairs(players:GetPlayers()) do
        if v~=player then
            local char=v.Character
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
                end
            elseif type(action)=="function" then
                action()
            end
        end
    end
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
local function autoRejoinEnabled()
    return autoRejoin
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
    local safe=Vector3.new(0,20,0)
    return teleportToPosition(safe)
end
local function teleportToSky()
    return teleportToPosition(Vector3.new(0,500,0))
end
local function teleportToUnderwater()
    return teleportToPosition(Vector3.new(0,-50,0))
end
local function teleportToSea()
    return teleportToPosition(Vector3.new(1000,0,1000))
end
local function getAllIslands()
    return {"Jungle","Pirate","Marine","Sky","Magma","Ice","Desert","Volcano","Underwater","Kingdom"}
end
local function getAllNPCs()
    local list={}
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Model") and v:FindFirstChild("Head") and v:FindFirstChild("IsNPC") then
            table.insert(list,v.Name)
        end
    end
    return list
end
local function getAllBosses()
    local list={}
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Model") and v:FindFirstChild("Head") and v:FindFirstChild("IsBoss") then
            table.insert(list,v.Name)
        end
    end
    return list
end
local function getAllFruits()
    local list={}
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Part") and v:FindFirstChild("FruitTag") then
            local tag=v:FindFirstChild("FruitTag")
            if tag then
                table.insert(list,tag.Value)
            end
        end
    end
    return list
end
local function teleportToRandomIsland()
    local islands=getAllIslands()
    if #islands>0 then
        return teleportToIsland(islands[math.random(1,#islands)])
    end
    return false
end
local function teleportToRandomPlayer()
    local playersList=players:GetPlayers()
    local others={}
    for _,p in pairs(playersList) do
        if p~=player then table.insert(others,p) end
    end
    if #others>0 then
        return teleportToPlayer(others[math.random(1,#others)].Name)
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
local function teleportToRandomBoss()
    local bosses=getAllBosses()
    if #bosses>0 then
        return teleportToBoss(bosses[math.random(1,#bosses)])
    end
    return false
end
local function teleportToRandomFruit()
    local fruits=getAllFruits()
    if #fruits>0 then
        return teleportToFruit(fruits[math.random(1,#fruits)])
    end
    return false
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
function teleport.TeleportToBoss(bossName,heightOffset)
    return teleportToBoss(bossName,heightOffset)
end
function teleport.TeleportToFruit(fruitName,heightOffset)
    return teleportToFruit(fruitName,heightOffset)
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
function teleport.TeleportToSea()
    return teleportToSea()
end
function teleport.TeleportToRandomIsland()
    return teleportToRandomIsland()
end
function teleport.TeleportToRandomPlayer()
    return teleportToRandomPlayer()
end
function teleport.TeleportToRandomNPC()
    return teleportToRandomNPC()
end
function teleport.TeleportToRandomBoss()
    return teleportToRandomBoss()
end
function teleport.TeleportToRandomFruit()
    return teleportToRandomFruit()
end
function teleport.GetAllIslands()
    return getAllIslands()
end
function teleport.GetAllNPCs()
    return getAllNPCs()
end
function teleport.GetAllBosses()
    return getAllBosses()
end
function teleport.GetAllFruits()
    return getAllFruits()
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
