local stats={}
stats.__index=stats
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
local dataRef=nil
local isRunning=false
local autoAssignEnabled=false
local statPriority="Melee"
local statPoints=0
local level=0
local exp=0
local maxExp=100
local statNames={"Melee","Defense","Sword","Gun","Fruit"}
local statValues={Melee=0,Defense=0,Sword=0,Gun=0,Fruit=0}
local statHistory={}
local maxHistory=50
local totalStatsAssigned=0
local lastAssignTime=0
local assignInterval=1
local minStatPointsToAssign=1
local statBonusMultiplier=1
local function updatePlayerStats()
    for _,name in ipairs(statNames) do
        local stat=player:FindFirstChild(name)
        if stat and stat:IsA("NumberValue") then
            statValues[name]=stat.Value
        end
    end
    local sp=player:FindFirstChild("StatPoints")
    if sp and sp:IsA("NumberValue") then
        statPoints=sp.Value
    end
    local lvl=player:FindFirstChild("Level")
    if lvl and lvl:IsA("NumberValue") then
        level=lvl.Value
    end
    local expVal=player:FindFirstChild("Exp")
    if expVal and expVal:IsA("NumberValue") then
        exp=expVal.Value
    end
    local maxExpVal=player:FindFirstChild("MaxExp")
    if maxExpVal and maxExpVal:IsA("NumberValue") then
        maxExp=maxExpVal.Value
    end
end
local function setStatPoints(value)
    local sp=player:FindFirstChild("StatPoints")
    if sp and sp:IsA("NumberValue") then
        sp.Value=value
        statPoints=value
        return true
    end
    return false
end
local function addStatPoints(amount)
    local sp=player:FindFirstChild("StatPoints")
    if sp and sp:IsA("NumberValue") then
        sp.Value=sp.Value+amount
        statPoints=statPoints+amount
        return true
    end
    return false
end
local function assignStat(statName,amount)
    if statPoints<amount then return false end
    local stat=player:FindFirstChild(statName)
    if stat and stat:IsA("NumberValue") then
        stat.Value=stat.Value+amount
        statValues[statName]=stat.Value
        statPoints=statPoints-amount
        setStatPoints(statPoints)
        totalStatsAssigned=totalStatsAssigned+amount
        table.insert(statHistory,{stat=statName,amount=amount,time=os.time(),pointsLeft=statPoints})
        if #statHistory>maxHistory then table.remove(statHistory,1) end
        return true
    end
    return false
end
local function resetAllStats()
    local total=0
    for _,name in ipairs(statNames) do
        local stat=player:FindFirstChild(name)
        if stat and stat:IsA("NumberValue") then
            total=total+stat.Value
            stat.Value=0
            statValues[name]=0
        end
    end
    if total>0 then
        addStatPoints(total)
    end
    return true
end
local function getStatTotal()
    local total=0
    for _,name in ipairs(statNames) do
        total=total+statValues[name]
    end
    return total
end
local function getAvailablePoints()
    return statPoints
end
local function getStatValue(statName)
    return statValues[statName] or 0
end
local function getStatPriority()
    return statPriority
end
local function setStatPriority(priority)
    if table.find(statNames,priority) then
        statPriority=priority
        return true
    end
    return false
end
local function getLevel()
    return level
end
local function getExp()
    return exp
end
local function getMaxExp()
    return maxExp
end
local function getExpProgress()
    if maxExp==0 then return 0 end
    return exp/maxExp
end
local function getExpToNext()
    return maxExp-exp
end
local function getStatPercent(statName)
    local total=getStatTotal()
    if total==0 then return 0 end
    return statValues[statName]/total
end
local function getDominantStat()
    local maxVal=0
    local dominant="Melee"
    for name,val in pairs(statValues) do
        if val>maxVal then
            maxVal=val
            dominant=name
        end
    end
    return dominant
end
local function autoAssignStats()
    if not autoAssignEnabled then return false end
    if statPoints<minStatPointsToAssign then return false end
    if tick()-lastAssignTime<assignInterval then return false end
    local priority=statPriority
    local amount=math.min(statPoints,10)
    if assignStat(priority,amount) then
        lastAssignTime=tick()
        return true
    end
    for _,name in ipairs(statNames) do
        if name~=priority then
            if assignStat(name,amount) then
                lastAssignTime=tick()
                return true
            end
        end
    end
    return false
end
local function assignStatIntelligent(amount)
    if statPoints<amount then return false end
    local priority=statPriority
    local current=statValues[priority]
    local total=getStatTotal()
    local targetPercent=0.4
    if total==0 then targetPercent=0.5 end
    local desired=math.floor(total*targetPercent)
    if current<desired then
        local add=math.min(amount,desired-current)
        if add>0 then
            return assignStat(priority,add)
        end
    end
    local lowest=nil
    local minVal=math.huge
    for name,val in pairs(statValues) do
        if val<minVal then
            minVal=val
            lowest=name
        end
    end
    if lowest then
        return assignStat(lowest,amount)
    end
    return false
end
local function getRecommendedStat()
    local total=getStatTotal()
    if total==0 then return "Melee" end
    local lowest=nil
    local minVal=math.huge
    for name,val in pairs(statValues) do
        if val<minVal then
            minVal=val
            lowest=name
        end
    end
    return lowest or "Melee"
end
local function getStatDistribution()
    local total=getStatTotal()
    if total==0 then
        local empty={}
        for _,name in ipairs(statNames) do empty[name]=0 end
        return empty
    end
    local dist={}
    for name,val in pairs(statValues) do
        dist[name]=val/total
    end
    return dist
end
local function getStatRank(statName)
    local val=statValues[statName]
    local rank=1
    for name,v in pairs(statValues) do
        if v>val then rank=rank+1 end
    end
    return rank
end
local function getTotalStatsAssigned()
    return totalStatsAssigned
end
local function getStatHistory()
    return statHistory
end
local function clearStatHistory()
    statHistory={}
    return true
end
local function getStatBonus(statName)
    local base=statValues[statName]
    return base*statBonusMultiplier
end
local function setStatBonusMultiplier(mult)
    statBonusMultiplier=mult
    return true
end
local function getStatMultiplier()
    return statBonusMultiplier
end
local function getStatsJSON()
    local data={}
    for name,val in pairs(statValues) do
        data[name]=val
    end
    data.statPoints=statPoints
    data.level=level
    data.exp=exp
    data.maxExp=maxExp
    data.priority=statPriority
    data.totalAssigned=totalStatsAssigned
    data.multiplier=statBonusMultiplier
    return httpService:JSONEncode(data)
end
local function importStatsJSON(json)
    local success,data=pcall(function()return httpService:JSONDecode(json)end)
    if success and data then
        for name,val in pairs(data) do
            if table.find(statNames,name) then
                local stat=player:FindFirstChild(name)
                if stat and stat:IsA("NumberValue") then
                    stat.Value=val
                    statValues[name]=val
                end
            end
        end
        if data.statPoints then
            setStatPoints(data.statPoints)
        end
        if data.level then
            local lvl=player:FindFirstChild("Level")
            if lvl and lvl:IsA("NumberValue") then
                lvl.Value=data.level
                level=data.level
            end
        end
        if data.exp then
            local e=player:FindFirstChild("Exp")
            if e and e:IsA("NumberValue") then
                e.Value=data.exp
                exp=data.exp
            end
        end
        if data.maxExp then
            local me=player:FindFirstChild("MaxExp")
            if me and me:IsA("NumberValue") then
                me.Value=data.maxExp
                maxExp=data.maxExp
            end
        end
        if data.priority then statPriority=data.priority end
        if data.totalAssigned then totalStatsAssigned=data.totalAssigned end
        if data.multiplier then statBonusMultiplier=data.multiplier end
        return true
    end
    return false
end
local function processStats(data)
    if not player then return end
    updatePlayerStats()
    if data.autoAssign then
        autoAssignEnabled=true
        autoAssignStats()
    else
        autoAssignEnabled=false
    end
    if data.priority then
        setStatPriority(data.priority)
    end
    if data.reset then
        resetAllStats()
        data.reset=false
    end
    if data.minPoints then
        minStatPointsToAssign=data.minPoints
    end
    if data.interval then
        assignInterval=data.interval
    end
end
local function startStatsLoop(data)
    if isRunning then return end
    isRunning=true
    task.spawn(function()
        while isRunning do
            wait(0.5)
            pcall(function()processStats(data)end)
        end
    end)
end
function stats.Stop()
    isRunning=false
    return true
end
function stats.Run(data)
    if not data then return false end
    dataRef=data
    if not data.enabled then
        if isRunning then stats.Stop() end
        return false
    end
    if not isRunning then
        startStatsLoop(data)
    end
    return true
end
function stats.ToggleAutoAssign()
    if dataRef then
        dataRef.autoAssign=not dataRef.autoAssign
        autoAssignEnabled=dataRef.autoAssign
        return autoAssignEnabled
    end
    autoAssignEnabled=not autoAssignEnabled
    return autoAssignEnabled
end
function stats.SetPriority(priority)
    if setStatPriority(priority) then
        if dataRef then dataRef.priority=priority end
        return true
    end
    return false
end
function stats.GetPriority()
    return getStatPriority()
end
function stats.AssignStat(statName,amount)
    return assignStat(statName,amount)
end
function stats.ResetStats()
    return resetAllStats()
end
function stats.GetStats()
    return statValues
end
function stats.GetStatPoints()
    return getAvailablePoints()
end
function stats.SetStatPoints(value)
    return setStatPoints(value)
end
function stats.AddStatPoints(amount)
    return addStatPoints(amount)
end
function stats.GetLevel()
    return getLevel()
end
function stats.GetExp()
    return getExp()
end
function stats.GetMaxExp()
    return getMaxExp()
end
function stats.GetExpProgress()
    return getExpProgress()
end
function stats.GetExpToNext()
    return getExpToNext()
end
function stats.GetStatPercent(statName)
    return getStatPercent(statName)
end
function stats.GetDominantStat()
    return getDominantStat()
end
function stats.GetRecommendedStat()
    return getRecommendedStat()
end
function stats.GetStatDistribution()
    return getStatDistribution()
end
function stats.GetStatRank(statName)
    return getStatRank(statName)
end
function stats.GetTotalAssigned()
    return getTotalStatsAssigned()
end
function stats.GetHistory()
    return getStatHistory()
end
function stats.ClearHistory()
    return clearStatHistory()
end
function stats.SetBonusMultiplier(mult)
    return setStatBonusMultiplier(mult)
end
function stats.GetBonusMultiplier()
    return getStatMultiplier()
end
function stats.ExportData()
    return getStatsJSON()
end
function stats.ImportData(json)
    return importStatsJSON(json)
end
function stats.SetMinPoints(minPoints)
    minStatPointsToAssign=minPoints
    if dataRef then dataRef.minPoints=minPoints end
    return true
end
function stats.GetMinPoints()
    return minStatPointsToAssign
end
function stats.SetAssignInterval(interval)
    assignInterval=interval
    if dataRef then dataRef.interval=interval end
    return true
end
function stats.GetAssignInterval()
    return assignInterval
end
function stats.AssignIntelligent(amount)
    return assignStatIntelligent(amount)
end
function stats.GetStatus()
    return{
        isRunning=isRunning,
        autoAssignEnabled=autoAssignEnabled,
        statPriority=statPriority,
        statPoints=statPoints,
        level=level,
        exp=exp,
        maxExp=maxExp,
        totalAssigned=totalStatsAssigned,
        stats=statValues,
        dominant=getDominantStat(),
        recommended=getRecommendedStat(),
        historySize=#statHistory
    }
end
function stats.UpdateStats()
    updatePlayerStats()
    return statValues
end
function stats.GetStatValue(statName)
    return getStatValue(statName)
end
function stats.GetStatTotal()
    return getStatTotal()
end
function stats.ResetAll()
    resetAllStats()
    statHistory={}
    totalStatsAssigned=0
    return true
end
function stats.Pause()
    isRunning=false
    return true
end
function stats.Resume()
    if dataRef and dataRef.enabled then
        isRunning=true
        startStatsLoop(dataRef)
        return true
    end
    return false
end
function stats.Destroy()
    isRunning=false
    statHistory={}
    totalStatsAssigned=0
    dataRef=nil
    return true
end
function stats.Initialize(data)
    dataRef=data
    updatePlayerStats()
    if data then
        if data.autoAssign~=nil then autoAssignEnabled=data.autoAssign end
        if data.priority then setStatPriority(data.priority) end
        if data.minPoints then minStatPointsToAssign=data.minPoints end
        if data.interval then assignInterval=data.interval end
        if data.multiplier then statBonusMultiplier=data.multiplier end
        if data.reset then resetAllStats() end
    end
    if not dataRef then dataRef={enabled=false} end
    return true
end
return stats
