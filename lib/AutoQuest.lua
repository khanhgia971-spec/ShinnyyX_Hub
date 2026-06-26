local autoQuest={}
autoQuest.__index=autoQuest
local player=game.Players.LocalPlayer
local runService=game:GetService("RunService")
local userInput=game:GetService("UserInputService")
local virtualUser=game:GetService("VirtualUser")
local tweenService=game:GetService("TweenService")
local workspace=game:GetService("Workspace")
local replicatedStorage=game:GetService("ReplicatedStorage")
local players=game:GetService("Players")
local collectionService=game:GetService("CollectionService")
local pathfindingService=game:GetService("PathfindingService")
local debris=game:GetService("Debris")
local httpService=game:GetService("HttpService")
local character=nil local humanoid=nil local rootPart=nil local dataRef=nil local isRunning=false local currentNPC=nil local questList={} local completedQuests={} local currentQuest=nil local questProgress=0 local questTimer=0 local npcPositions={} local questTypes={"Normal","Daily","Weekly","Event"} local rewardList={}
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
local function findNearestNPC(npcName)
    local nearest=nil
    local minDist=math.huge
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Model") and v:FindFirstChild("Head") then
            local name=v.Name
            if name==npcName or (npcName=="" and v:FindFirstChild("IsNPC")) then
                local dist=getDistance(rootPart.Position,v.Head.Position)
                if dist<minDist then
                    nearest=v
                    minDist=dist
                end
            end
        end
    end
    return nearest
end
local function moveTo(position,timeout)
    timeout=timeout or 5
    local startTime=tick()
    local success=false
    if rootPart then
        local tweenInfo=TweenInfo.new((getDistance(rootPart.Position,position)/40),Enum.EasingStyle.Linear)
        local tween=tweenService:Create(rootPart,tweenInfo,{CFrame=CFrame.new(position)})
        tween:Play()
        repeat wait(0.1) until not tween.PlaybackState==Enum.PlaybackState.Playing or tick()-startTime>timeout
        if getDistance(rootPart.Position,position)<5 then
            success=true
        end
    end
    return success
end
local function interactWithNPC(npc)
    if not npc or not rootPart then return false end
    local head=npc:FindFirstChild("Head")
    if head then
        rootPart.CFrame=CFrame.new(head.Position+Vector3.new(0,2,0))
        wait(0.3)
        local click=Instance.new("Part")
        click.Size=Vector3.new(1,1,1)
        click.Position=head.Position+Vector3.new(0,2,0)
        click.Anchored=true
        click.Transparency=0.5
        click.Parent=workspace
        debris:AddItem(click,0.2)
        return true
    end
    return false
end
local function getAvailableQuests()
    local quests={}
    local questFolder=player:FindFirstChild("Quests")
    if questFolder then
        for _,v in pairs(questFolder:GetChildren()) do
            if v:IsA("IntValue") then
                table.insert(quests,{name=v.Name,progress=v.Value,type=v:FindFirstChild("Type") and v.Type.Value or "Normal"})
            end
        end
    end
    return quests
end
local function acceptQuest(npcName)
    local npc=findNearestNPC(npcName)
    if npc then
        interactWithNPC(npc)
        wait(0.5)
        local quests=getAvailableQuests()
        if #quests>0 then
            currentQuest=quests[1]
            return true
        end
    end
    return false
end
local function completeQuestByKill()
    if not currentQuest then return false end
    local needed=currentQuest.progress
    if needed<=0 then
        return true
    end
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("Head") and v.Name~=player.Name then
            if v:FindFirstChild("Humanoid").Health>0 then
                rootPart.CFrame=CFrame.new(v.Head.Position+Vector3.new(0,5,0))
                if humanoid then
                    humanoid:BreakJoints()
                end
                wait(0.2)
                return true
            end
        end
    end
    return false
end
local function completeQuestByCollect()
    if not currentQuest then return false end
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Part") and v:FindFirstChild("QuestItem") then
            local dist=getDistance(rootPart.Position,v.Position)
            if dist<10 then
                v:Destroy()
                return true
            else
                moveTo(v.Position,3)
            end
        end
    end
    return false
end
local function turnInQuest(npcName)
    local npc=findNearestNPC(npcName)
    if npc then
        interactWithNPC(npc)
        wait(0.5)
        local quests=getAvailableQuests()
        for _,q in pairs(quests) do
            if q.progress<=0 then
                table.insert(completedQuests,q)
            end
        end
        return true
    end
    return false
end
local function getQuestReward()
    local rewards={}
    local rewardFolder=player:FindFirstChild("Rewards")
    if rewardFolder then
        for _,v in pairs(rewardFolder:GetChildren()) do
            if v:IsA("NumberValue") or v:IsA("StringValue") then
                table.insert(rewards,{name=v.Name,value=v.Value})
            end
        end
    end
    return rewards
end
local function checkQuestCompletion()
    if not currentQuest then return false end
    local progress=0
    local questFolder=player:FindFirstChild("Quests")
    if questFolder then
        for _,v in pairs(questFolder:GetChildren()) do
            if v:IsA("IntValue") and v.Name==currentQuest.name then
                progress=v.Value
                break
            end
        end
    end
    return progress<=0
end
local function processQuest(data)
    if not rootPart or not humanoid then updateCharacter() end
    if not rootPart or not humanoid then return end
    local npcName=data.npcName or "NPC"
    local questType=data.questType or "Daily"
    local autoTurnIn=data.autoTurnIn or true
    questTimer=questTimer+0.1
    if not currentQuest then
        local quests=getAvailableQuests()
        if #quests==0 then
            acceptQuest(npcName)
        else
            currentQuest=quests[1]
        end
        return
    end
    if checkQuestCompletion() then
        if autoTurnIn then
            turnInQuest(npcName)
            currentQuest=nil
            return
        end
    end
    if questType=="Normal" or questType=="Daily" then
        completeQuestByKill()
    elseif questType=="Weekly" then
        completeQuestByKill()
        completeQuestByCollect()
    elseif questType=="Event" then
        completeQuestByKill()
        completeQuestByCollect()
        for _,v in pairs(workspace:GetChildren()) do
            if v:IsA("Part") and v:FindFirstChild("EventItem") then
                moveTo(v.Position,3)
            end
        end
    end
end
local function startQuest(data)
    if isRunning then return end
    isRunning=true
    dataRef=data
    updateCharacter()
    currentQuest=nil
    task.spawn(function()
        while isRunning do
            wait(0.5)
            pcall(function()processQuest(data)end)
        end
    end)
    return true
end
function autoQuest.Stop()
    isRunning=false
    currentQuest=nil
    return true
end
function autoQuest.Run(data)
    if not data then return false end
    if not data.enabled then
        if isRunning then autoQuest.Stop() end
        return false
    end
    if not isRunning then
        return startQuest(data)
    else
        dataRef=data
        return true
    end
end
function autoQuest.SetNPC(npcName)
    if dataRef then
        dataRef.npcName=npcName
        return true
    end
    return false
end
function autoQuest.SetQuestType(questType)
    if dataRef then
        dataRef.questType=questType
        return true
    end
    return false
end
function autoQuest.ToggleAutoTurnIn()
    if dataRef then
        dataRef.autoTurnIn=not dataRef.autoTurnIn
        return dataRef.autoTurnIn
    end
    return false
end
function autoQuest.GetStatus()
    return{
        isRunning=isRunning,
        currentNPC=currentNPC and currentNPC.Name or "None",
        currentQuest=currentQuest,
        questProgress=questProgress,
        completedQuests=#completedQuests,
        questTimer=questTimer
    }
end
function autoQuest.GetAvailableQuests()
    return getAvailableQuests()
end
function autoQuest.GetCompletedQuests()
    return completedQuests
end
function autoQuest.GetQuestRewards()
    return getQuestReward()
end
function autoQuest.FindAllNPCs()
    local list={}
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Model") and v:FindFirstChild("Head") and v:FindFirstChild("IsNPC") then
            table.insert(list,v.Name)
        end
    end
    return list
end
function autoQuest.MoveToNPC(npcName)
    local npc=findNearestNPC(npcName)
    if npc then
        return moveTo(npc.Head.Position,5)
    end
    return false
end
function autoQuest.AcceptQuest(npcName)
    return acceptQuest(npcName)
end
function autoQuest.TurnInQuest(npcName)
    return turnInQuest(npcName)
end
function autoQuest.CompleteQuest()
    if currentQuest then
        local questType=dataRef and dataRef.questType or "Normal"
        if questType=="Normal" or questType=="Daily" then
            return completeQuestByKill()
        elseif questType=="Weekly" then
            return completeQuestByKill() or completeQuestByCollect()
        elseif questType=="Event" then
            return completeQuestByKill() or completeQuestByCollect()
        end
    end
    return false
end
function autoQuest.SkipQuest()
    if currentQuest then
        currentQuest=nil
        return true
    end
    return false
end
function autoQuest.GetCurrentQuest()
    return currentQuest
end
function autoQuest.IsQuestComplete()
    return checkQuestCompletion()
end
function autoQuest.ResetProgress()
    questProgress=0
    currentQuest=nil
    completedQuests={}
    return true
end
function autoQuest.Pause()
    isRunning=false
    return true
end
function autoQuest.Resume()
    if dataRef and dataRef.enabled then
        isRunning=true
        return true
    end
    return false
end
function autoQuest.Destroy()
    autoQuest.Stop()
    dataRef=nil
    currentNPC=nil
    currentQuest=nil
    completedQuests={}
    questList={}
    return true
end
function autoQuest.Initialize(data)
    dataRef=data
    updateCharacter()
    return true
end
return autoQuest
