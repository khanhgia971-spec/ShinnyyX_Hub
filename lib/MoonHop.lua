local moonHop={}
moonHop.__index=moonHop
local player=game.Players.LocalPlayer
local runService=game:GetService("RunService")
local httpService=game:GetService("HttpService")
local teleportService=game:GetService("TeleportService")
local workspace=game:GetService("Workspace")
local lighting=game:GetService("Lighting")
local players=game:GetService("Players")
local virtualUser=game:GetService("VirtualUser")
local tweenService=game:GetService("TweenService")
local dataRef=nil
local isRunning=false
local isHoping=false
local currentPhase=-1
local targetPhases={}
local hopCount=0
local maxHops=50
local hopDelay=2
local checkInterval=1
local lastPhaseCheck=0
local serverHistory={}
local phaseNames={
    [0]="New Moon",
    [1]="Waxing Crescent",
    [2]="First Quarter",
    [3]="Waxing Gibbous",
    [4]="Full Moon",
    [5]="Waning Gibbous",
    [6]="Third Quarter",
    [7]="Waning Crescent"
}
local phaseValues={
    ["New Moon"]=0,
    ["Waxing Crescent"]=1,
    ["First Quarter"]=2,
    ["Waxing Gibbous"]=3,
    ["Full Moon"]=4,
    ["Waning Gibbous"]=5,
    ["Third Quarter"]=6,
    ["Waning Crescent"]=7
}
local phaseToTarget={
    ["Full Moon"]={4},
    ["Gần Full Moon"]={2,3,4,5},
    ["Trăng 1/5"]={0,1},
    ["Trăng 2/5"]={2},
    ["Trăng 3/5"]={3}
}
local function updateCharacter()
    local char=player.Character or player.CharacterAdded:Wait()
    if char then
        return char:FindFirstChild("HumanoidRootPart")
    end
    return nil
end
local function getMoonPhase()
    local timeOfDay=lighting.TimeOfDay
    local hour=tonumber(string.sub(timeOfDay,1,2)) or 0
    local minute=tonumber(string.sub(timeOfDay,4,5)) or 0
    local totalMinutes=hour*60+minute
    local dayCycle=80
    local nightStart=5
    local nightEnd=10
    local currentTime=totalMinutes/10
    local phase=math.floor(currentTime%8)
    if phase<0 then phase=0 end
    if phase>7 then phase=7 end
    local sky=workspace:FindFirstChild("Sky")
    if sky then
        local moon=sky:FindFirstChild("Moon")
        if moon then
            local rotation=moon.Rotation
            if rotation and rotation.Y then
                local rot=rotation.Y
                if rot>315 or rot<45 then phase=4 end
                if rot>45 and rot<135 then phase=2 end
                if rot>135 and rot<225 then phase=0 end
                if rot>225 and rot<315 then phase=6 end
            end
        end
    end
    return phase
end
local function getMoonPhaseName(phase)
    return phaseNames[phase] or "Unknown"
end
local function getPhaseFromName(name)
    return phaseValues[name] or -1
end
local function isTargetPhase(phase,target)
    if type(target)=="table" then
        for _,v in ipairs(target) do
            if phase==v then return true end
        end
        return false
    end
    return phase==target
end
local function getTargetPhases(targetType)
    return phaseToTarget[targetType] or {4}
end
local function checkCurrentMoon(targetType)
    local phase=getMoonPhase()
    local targets=getTargetPhases(targetType)
    return isTargetPhase(phase,targets),phase
end
local function hopServer()
    if isHoping then return false end
    isHoping=true
    hopCount=hopCount+1
    local placeId=game.PlaceId
    local jobId=game.JobId
    table.insert(serverHistory,{jobId=jobId,time=os.time(),phase=currentPhase})
    if #serverHistory>20 then table.remove(serverHistory,1) end
    local success,err=pcall(function()
        teleportService:Teleport(placeId,player,{},jobId)
    end)
    if not success then
        isHoping=false
        return false
    end
    return true
end
local function waitForRejoin()
    local timeout=30
    local start=tick()
    while tick()-start<timeout do
        if player.Parent and game:IsLoaded() then
            task.wait(2)
            return true
        end
        task.wait(0.5)
    end
    return false
end
local function processMoonHop(data)
    if not data or not data.enabled then
        if isRunning then moonHop.Stop() end
        return
    end
    local targetType=data.targetType or "Full Moon"
    local maxHops=data.maxHops or 50
    local delay=data.hopDelay or 2
    if hopCount>=maxHops then
        moonHop.Stop()
        return
    end
    local isMatch,phase=checkCurrentMoon(targetType)
    currentPhase=phase
    if isMatch then
        moonHop.Stop()
        return
    end
    if isHoping then return end
    hopServer()
end
local function startMoonHopLoop(data)
    if isRunning then return end
    isRunning=true
    hopCount=0
    isHoping=false
    task.spawn(function()
        while isRunning do
            wait(checkInterval)
            pcall(function()processMoonHop(data)end)
        end
    end)
end
function moonHop.Stop()
    isRunning=false
    isHoping=false
    return true
end
function moonHop.Run(data)
    if not data then return false end
    dataRef=data
    if not data.enabled then
        if isRunning then moonHop.Stop() end
        return false
    end
    if not isRunning then
        startMoonHopLoop(data)
    end
    return true
end
function moonHop.GetCurrentPhase()
    return currentPhase,getMoonPhaseName(currentPhase)
end
function moonHop.GetPhaseName(phase)
    return getMoonPhaseName(phase)
end
function moonHop.GetPhaseValue(name)
    return getPhaseFromName(name)
end
function moonHop.CheckTarget(targetType)
    return checkCurrentMoon(targetType)
end
function moonHop.HopServer()
    return hopServer()
end
function moonHop.SetTarget(targetType)
    if dataRef then
        dataRef.targetType=targetType
        return true
    end
    return false
end
function moonHop.SetMaxHops(max)
    if dataRef then
        dataRef.maxHops=max
        maxHops=max
        return true
    end
    return false
end
function moonHop.SetHopDelay(delay)
    if dataRef then
        dataRef.hopDelay=delay
        hopDelay=delay
        return true
    end
    return false
end
function moonHop.GetStatus()
    return{
        isRunning=isRunning,
        isHoping=isHoping,
        currentPhase=currentPhase,
        currentPhaseName=getMoonPhaseName(currentPhase),
        hopCount=hopCount,
        maxHops=maxHops,
        targetType=dataRef and dataRef.targetType or "Full Moon",
        serverHistorySize=#serverHistory
    }
end
function moonHop.GetServerHistory()
    return serverHistory
end
function moonHop.ClearHistory()
    serverHistory={}
    return true
end
function moonHop.GetAllPhases()
    local list={}
    for i=0,7 do
        table.insert(list,{phase=i,name=phaseNames[i]})
    end
    return list
end
function moonHop.GetTargetTypes()
    local types={}
    for k,_ in pairs(phaseToTarget) do
        table.insert(types,k)
    end
    return types
end
function moonHop.AddTargetType(name,phases)
    phaseToTarget[name]=phases
    return true
end
function moonHop.RemoveTargetType(name)
    phaseToTarget[name]=nil
    return true
end
function moonHop.Reset()
    hopCount=0
    isHoping=false
    serverHistory={}
    return true
end
function moonHop.Pause()
    isRunning=false
    return true
end
function moonHop.Resume()
    if dataRef and dataRef.enabled then
        isRunning=true
        startMoonHopLoop(dataRef)
        return true
    end
    return false
end
function moonHop.Destroy()
    isRunning=false
    isHoping=false
    dataRef=nil
    serverHistory={}
    hopCount=0
    return true
end
function moonHop.Initialize(data)
    dataRef=data
    if data then
        if data.targetType then
            if not phaseToTarget[data.targetType] then
                phaseToTarget[data.targetType]={4}
            end
        end
        if data.maxHops then maxHops=data.maxHops end
        if data.hopDelay then hopDelay=data.hopDelay end
        if data.checkInterval then checkInterval=data.checkInterval end
    end
    return true
end
return moonHop
