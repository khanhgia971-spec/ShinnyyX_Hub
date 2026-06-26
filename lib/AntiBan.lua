local antiBan={}
antiBan.__index=antiBan
local player=game.Players.LocalPlayer
local runService=game:GetService("RunService")
local userInput=game:GetService("UserInputService")
local workspace=game:GetService("Workspace")
local players=game:GetService("Players")
local tweenService=game:GetService("TweenService")
local virtualUser=game:GetService("VirtualUser")
local httpService=game:GetService("HttpService")
local debris=game:GetService("Debris")
local collectionService=game:GetService("CollectionService")
local replicatedStorage=game:GetService("ReplicatedStorage")
local dataRef=nil
local isRunning=false
local antiBanEnabled=true
local detectionLevel=0
local maxDetectionLevel=10
local lastDetectionTime=0
local detectionCooldown=5
local randomDelayMin=0.05
local randomDelayMax=0.3
local fakeInputEnabled=true
local fakeInputInterval=3
local antiAFKEnabled=true
local antiAFKInterval=60
local autoDisableOnDetection=true
local detectionThreshold=5
local useHumanLikeMovement=true
local humanLikeSpeed=1.0
local jitterAmount=2
local behaviorProfile="Normal"
local profiles={
    Normal={delayMin=0.05,delayMax=0.2,jitter=2,speed=1.0},
    Cautious={delayMin=0.1,delayMax=0.4,jitter=3,speed=0.8},
    Aggressive={delayMin=0.02,delayMax=0.1,jitter=1,speed=1.5},
    Stealth={delayMin=0.2,delayMax=0.6,jitter=5,speed=0.6}
}
local detectionKeywords={
    "ban","detected","cheat","hack","exploit","suspect","warning","violation"
}
local detectionLog={}
local fakeInputQueue={}
local fakeInputRunning=false
local humanMovementActive=false
local lastHumanMoveTime=0
local movementPattern={}
local currentPatternIndex=1
local character=nil local humanoid=nil local rootPart=nil
local function updateCharacter()
    character=player.Character or player.CharacterAdded:Wait()
    if character then
        humanoid=character:FindFirstChild("Humanoid")
        rootPart=character:FindFirstChild("HumanoidRootPart")
    end
end
local function getRandomDelay()
    local min=dataRef and dataRef.delayMin or randomDelayMin
    local max=dataRef and dataRef.delayMax or randomDelayMax
    return math.random()*(max-min)+min
end
local function getCurrentProfile()
    local profile=dataRef and dataRef.behaviorProfile or behaviorProfile
    return profiles[profile] or profiles.Normal
end
local function checkDetection(text)
    if not text then return false end
    text=text:lower()
    for _,keyword in ipairs(detectionKeywords) do
        if string.find(text,keyword) then
            return true
        end
    end
    return false
end
local function addDetection(reason,source)
    local now=os.time()
    if now-lastDetectionTime<detectionCooldown then return end
    lastDetectionTime=now
    detectionLevel=detectionLevel+1
    table.insert(detectionLog,{time=now,reason=reason,source=source,level=detectionLevel})
    if #detectionLog>100 then table.remove(detectionLog,1) end
    if detectionLevel>=detectionThreshold and autoDisableOnDetection then
        antiBan:DisableAll()
    end
end
local function checkChatMessages()
    local chat=game:GetService("Chat")
    if not chat then return end
    local messages=chat:GetRecentMessages()
    if messages then
        for _,msg in ipairs(messages) do
            if msg and msg.Message then
                if checkDetection(msg.Message) then
                    addDetection("Suspicious chat message: "..msg.Message,"Chat")
                end
            end
        end
    end
end
local function checkServerAnnouncements()
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Model") and v.Name:match("Announcement") then
            local text=v:FindFirstChild("Text")
            if text and text:IsA("StringValue") then
                if checkDetection(text.Value) then
                    addDetection("Server announcement: "..text.Value,"Server")
                end
            end
        end
    end
end
local function checkPlayerNames()
    for _,p in pairs(players:GetPlayers()) do
        if p~=player then
            if checkDetection(p.Name) then
                addDetection("Suspicious player name: "..p.Name,"Player")
            end
        end
    end
end
local function performFakeInput()
    if not fakeInputEnabled then return end
    local actions={"Jump","Sit","Walk","Turn","Look"}
    local action=actions[math.random(1,#actions)]
    if action=="Jump" then
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            task.wait(getRandomDelay())
        end
    elseif action=="Sit" then
        if humanoid then
            humanoid.Sit=not humanoid.Sit
            task.wait(getRandomDelay())
        end
    elseif action=="Walk" then
        if rootPart then
            local dir=Vector3.new(math.random(-1,1),0,math.random(-1,1))
            if dir.Magnitude>0 then
                dir=dir.Unit*10
                rootPart.Velocity=dir
                task.wait(getRandomDelay())
                rootPart.Velocity=Vector3.new(0,0,0)
            end
        end
    elseif action=="Turn" then
        if rootPart then
            local angle=math.rad(math.random(-45,45))
            local cf=rootPart.CFrame*CFrame.Angles(0,angle,0)
            rootPart.CFrame=cf
            task.wait(getRandomDelay())
        end
    elseif action=="Look" then
        if character and character:FindFirstChild("Head") then
            local head=character.Head
            local target=Vector3.new(math.random(-50,50),math.random(-10,10),math.random(-50,50))
            local look=target-head.Position
            if look.Magnitude>0 then
                head.CFrame=CFrame.new(head.Position,look)
            end
        end
    end
end
local function performAntiAFK()
    if not antiAFKEnabled then return end
    pcall(function()
        virtualUser:CaptureController()
        virtualUser:ClickButton2(Vector2.new())
        task.wait(getRandomDelay())
        virtualUser:ClickButton2(Vector2.new())
    end)
end
local function simulateHumanMovement()
    if not useHumanLikeMovement or not rootPart then return end
    local now=tick()
    if now-lastHumanMoveTime<0.5 then return end
    lastHumanMoveTime=now
    local profile=getCurrentProfile()
    local speed=profile.speed or 1.0
    local jitter=profile.jitter or 2
    local patterns={
        {Vector3.new(1,0,0),Vector3.new(0,0,1),Vector3.new(-1,0,0),Vector3.new(0,0,-1)},
        {Vector3.new(1,0,1),Vector3.new(-1,0,1),Vector3.new(-1,0,-1),Vector3.new(1,0,-1)},
        {Vector3.new(0,0,1),Vector3.new(1,0,0),Vector3.new(0,0,-1),Vector3.new(-1,0,0)}
    }
    local pattern=patterns[math.random(1,#patterns)]
    local dir=pattern[math.random(1,#pattern)]
    local jitterVector=Vector3.new(
        math.random(-jitter,jitter)/10,
        math.random(-jitter,jitter)/10,
        math.random(-jitter,jitter)/10
    )
    dir=dir+jitterVector
    dir=dir.Unit*8*speed
    rootPart.Velocity=dir
    task.wait(getRandomDelay())
    rootPart.Velocity=Vector3.new(0,0,0)
end
local function checkAdminPresence()
    for _,p in pairs(players:GetPlayers()) do
        if p~=player then
            local rank=p:FindFirstChild("Rank")
            if rank and rank:IsA("StringValue") then
                local rankName=rank.Value:lower()
                if rankName=="admin" or rankName=="moderator" or rankName=="owner" then
                    addDetection("Admin detected: "..p.Name,"Admin")
                end
            end
        end
    end
end
local function checkServerType()
    local serverType=game:GetService("GameSettings"):GetGameCapabilities()
    if serverType and serverType:match("official") then
        addDetection("Official server detected","Server")
    end
end
local function checkPlayerCount()
    local count=#players:GetPlayers()
    if count<3 then
        addDetection("Low player count: "..count,"Server")
    end
end
local function checkGameVersion()
    local version=replicatedStorage:FindFirstChild("Version")
    if version and version:IsA("StringValue") then
        if string.find(version.Value,"beta") or string.find(version.Value,"test") then
            addDetection("Beta/test version detected: "..version.Value,"Game")
        end
    end
end
local function checkForUpdates()
    local update=replicatedStorage:FindFirstChild("Update")
    if update and update:IsA("BoolValue") and update.Value==true then
        addDetection("Game update detected","Game")
    end
end
local function checkRemoteEvents()
    for _,v in pairs(replicatedStorage:GetChildren()) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            if string.find(v.Name:lower(),"ban") or string.find(v.Name:lower(),"kick") or string.find(v.Name:lower(),"check") then
                addDetection("Suspicious remote: "..v.Name,"Remote")
            end
        end
    end
end
local function randomizeBehavior()
    local profiles={"Normal","Cautious","Stealth"}
    local newProfile=profiles[math.random(1,#profiles)]
    if dataRef then
        dataRef.behaviorProfile=newProfile
    else
        behaviorProfile=newProfile
    end
end
local function getRandomPosition()
    local center=rootPart and rootPart.Position or Vector3.new(0,0,0)
    local radius=math.random(5,20)
    local angle=math.random()*2*math.pi
    local x=center.X+radius*math.cos(angle)
    local z=center.Z+radius*math.sin(angle)
    local y=center.Y+math.random(-2,2)
    return Vector3.new(x,y,z)
end
local function performRandomMovement()
    if not rootPart then return end
    local target=getRandomPosition()
    local tweenInfo=TweenInfo.new(math.random(1,3),Enum.EasingStyle.Linear)
    local tween=tweenService:Create(rootPart,tweenInfo,{CFrame=CFrame.new(target)})
    tween:Play()
    task.wait(getRandomDelay())
end
local function performRandomLook()
    if not character or not character:FindFirstChild("Head") then return end
    local head=character.Head
    local target=Vector3.new(math.random(-100,100),math.random(-20,20),math.random(-100,100))
    local look=target-head.Position
    if look.Magnitude>0 then
        head.CFrame=CFrame.new(head.Position,look)
    end
end
local function performRandomInteraction()
    local interactions={"Jump","Sit","Crouch","Spin"}
    local action=interactions[math.random(1,#interactions)]
    if action=="Jump" and humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    elseif action=="Sit" and humanoid then
        humanoid.Sit=not humanoid.Sit
    elseif action=="Crouch" and humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Climbing)
        task.wait(0.2)
        humanoid:ChangeState(Enum.HumanoidStateType.Landed)
    elseif action=="Spin" and rootPart then
        rootPart.CFrame=rootPart.CFrame*CFrame.Angles(0,math.rad(360),0)
    end
end
local function performRandomText()
    local texts={"lol","gg","ez","nice","wow","xd","hello","hi","whats up","ok","yeah","no","maybe","sure","idk"}
    local text=texts[math.random(1,#texts)]
    local chat=game:GetService("Chat")
    if chat then
        chat:SendMessage(text)
    end
end
local function checkForDetections()
    checkChatMessages()
    checkServerAnnouncements()
    checkPlayerNames()
    checkAdminPresence()
    checkServerType()
    checkPlayerCount()
    checkGameVersion()
    checkForUpdates()
    checkRemoteEvents()
end
local function startFakeInputLoop()
    task.spawn(function()
        while isRunning do
            task.wait(fakeInputInterval+getRandomDelay())
            pcall(performFakeInput)
        end
    end)
end
local function startAntiAFKLoop()
    task.spawn(function()
        while isRunning do
            task.wait(antiAFKInterval+getRandomDelay())
            pcall(performAntiAFK)
        end
    end)
end
local function startHumanMovementLoop()
    task.spawn(function()
        while isRunning do
            task.wait(getRandomDelay())
            pcall(simulateHumanMovement)
        end
    end)
end
local function startRandomBehaviorLoop()
    task.spawn(function()
        while isRunning do
            task.wait(math.random(30,60))
            pcall(randomizeBehavior)
        end
    end)
end
local function startRandomActionsLoop()
    task.spawn(function()
        while isRunning do
            task.wait(math.random(5,15))
            local action=math.random(1,4)
            if action==1 then pcall(performRandomMovement)
            elseif action==2 then pcall(performRandomLook)
            elseif action==3 then pcall(performRandomInteraction)
            elseif action==4 then pcall(performRandomText) end
        end
    end)
end
local function startDetectionLoop()
    task.spawn(function()
        while isRunning do
            task.wait(5)
            pcall(checkForDetections)
        end
    end)
end
function antiBan.Enable()
    antiBanEnabled=true
    return true
end
function antiBan.Disable()
    antiBanEnabled=false
    return true
end
function antiBan.Toggle()
    antiBanEnabled=not antiBanEnabled
    return antiBanEnabled
end
function antiBan.IsEnabled()
    return antiBanEnabled
end
function antiBan.SetDetectionLevel(level)
    detectionLevel=level
    return true
end
function antiBan.GetDetectionLevel()
    return detectionLevel
end
function antiBan.ResetDetectionLevel()
    detectionLevel=0
    return true
end
function antiBan.SetDetectionThreshold(threshold)
    detectionThreshold=threshold
    return true
end
function antiBan.GetDetectionThreshold()
    return detectionThreshold
end
function antiBan.SetAutoDisable(enabled)
    autoDisableOnDetection=enabled
    return true
end
function antiBan.IsAutoDisable()
    return autoDisableOnDetection
end
function antiBan.SetRandomDelay(min,max)
    randomDelayMin=min
    randomDelayMax=max
    return true
end
function antiBan.GetRandomDelay()
    return randomDelayMin,randomDelayMax
end
function antiBan.SetFakeInputEnabled(enabled)
    fakeInputEnabled=enabled
    return true
end
function antiBan.IsFakeInputEnabled()
    return fakeInputEnabled
end
function antiBan.SetFakeInputInterval(interval)
    fakeInputInterval=interval
    return true
end
function antiBan.GetFakeInputInterval()
    return fakeInputInterval
end
function antiBan.SetAntiAFKEnabled(enabled)
    antiAFKEnabled=enabled
    return true
end
function antiBan.IsAntiAFKEnabled()
    return antiAFKEnabled
end
function antiBan.SetAntiAFKInterval(interval)
    antiAFKInterval=interval
    return true
end
function antiBan.GetAntiAFKInterval()
    return antiAFKInterval
end
function antiBan.SetHumanLikeMovement(enabled)
    useHumanLikeMovement=enabled
    return true
end
function antiBan.IsHumanLikeMovement()
    return useHumanLikeMovement
end
function antiBan.SetHumanLikeSpeed(speed)
    humanLikeSpeed=speed
    return true
end
function antiBan.GetHumanLikeSpeed()
    return humanLikeSpeed
end
function antiBan.SetJitterAmount(amount)
    jitterAmount=amount
    return true
end
function antiBan.GetJitterAmount()
    return jitterAmount
end
function antiBan.SetBehaviorProfile(profile)
    if profiles[profile] then
        behaviorProfile=profile
        return true
    end
    return false
end
function antiBan.GetBehaviorProfile()
    return behaviorProfile
end
function antiBan.GetProfiles()
    return profiles
end
function antiBan.AddProfile(name,config)
    profiles[name]=config
    return true
end
function antiBan.RemoveProfile(name)
    profiles[name]=nil
    return true
end
function antiBan.GetDetectionLog()
    return detectionLog
end
function antiBan.ClearDetectionLog()
    detectionLog={}
    return true
end
function antiBan.DisableAll()
    if dataRef then
        dataRef.enabled=false
    end
    antiBanEnabled=false
    fakeInputEnabled=false
    antiAFKEnabled=false
    useHumanLikeMovement=false
    isRunning=false
    return true
end
function antiBan.EnableAll()
    antiBanEnabled=true
    fakeInputEnabled=true
    antiAFKEnabled=true
    useHumanLikeMovement=true
    if not isRunning then
        antiBan:Run(dataRef or {})
    end
    return true
end
function antiBan.AddDetectionKeyword(keyword)
    table.insert(detectionKeywords,keyword:lower())
    return true
end
function antiBan.RemoveDetectionKeyword(keyword)
    for i,v in ipairs(detectionKeywords) do
        if v==keyword:lower() then
            table.remove(detectionKeywords,i)
            return true
        end
    end
    return false
end
function antiBan.GetDetectionKeywords()
    return detectionKeywords
end
function antiBan.ResetDetectionKeywords()
    detectionKeywords={
        "ban","detected","cheat","hack","exploit","suspect","warning","violation"
    }
    return true
end
function antiBan.PerformFakeInput()
    return performFakeInput()
end
function antiBan.PerformAntiAFK()
    return performAntiAFK()
end
function antiBan.SimulateHumanMovement()
    return simulateHumanMovement()
end
function antiBan.RandomizeBehavior()
    return randomizeBehavior()
end
function antiBan.GetStatus()
    return{
        isRunning=isRunning,
        antiBanEnabled=antiBanEnabled,
        detectionLevel=detectionLevel,
        detectionThreshold=detectionThreshold,
        autoDisableOnDetection=autoDisableOnDetection,
        fakeInputEnabled=fakeInputEnabled,
        antiAFKEnabled=antiAFKEnabled,
        useHumanLikeMovement=useHumanLikeMovement,
        behaviorProfile=behaviorProfile,
        detectionLogSize=#detectionLog
    }
end
function antiBan.ExportConfig()
    return httpService:JSONEncode({
        antiBanEnabled=antiBanEnabled,
        randomDelayMin=randomDelayMin,
        randomDelayMax=randomDelayMax,
        fakeInputEnabled=fakeInputEnabled,
        fakeInputInterval=fakeInputInterval,
        antiAFKEnabled=antiAFKEnabled,
        antiAFKInterval=antiAFKInterval,
        useHumanLikeMovement=useHumanLikeMovement,
        humanLikeSpeed=humanLikeSpeed,
        jitterAmount=jitterAmount,
        behaviorProfile=behaviorProfile,
        detectionThreshold=detectionThreshold,
        autoDisableOnDetection=autoDisableOnDetection,
        detectionKeywords=detectionKeywords
    })
end
function antiBan.ImportConfig(json)
    local success,data=pcall(function()return httpService:JSONDecode(json)end)
    if not success or not data then return false end
    if data.antiBanEnabled~=nil then antiBanEnabled=data.antiBanEnabled end
    if data.randomDelayMin then randomDelayMin=data.randomDelayMin end
    if data.randomDelayMax then randomDelayMax=data.randomDelayMax end
    if data.fakeInputEnabled~=nil then fakeInputEnabled=data.fakeInputEnabled end
    if data.fakeInputInterval then fakeInputInterval=data.fakeInputInterval end
    if data.antiAFKEnabled~=nil then antiAFKEnabled=data.antiAFKEnabled end
    if data.antiAFKInterval then antiAFKInterval=data.antiAFKInterval end
    if data.useHumanLikeMovement~=nil then useHumanLikeMovement=data.useHumanLikeMovement end
    if data.humanLikeSpeed then humanLikeSpeed=data.humanLikeSpeed end
    if data.jitterAmount then jitterAmount=data.jitterAmount end
    if data.behaviorProfile then behaviorProfile=data.behaviorProfile end
    if data.detectionThreshold then detectionThreshold=data.detectionThreshold end
    if data.autoDisableOnDetection~=nil then autoDisableOnDetection=data.autoDisableOnDetection end
    if data.detectionKeywords then detectionKeywords=data.detectionKeywords end
    return true
end
function antiBan.Pause()
    isRunning=false
    return true
end
function antiBan.Resume()
    if dataRef then
        isRunning=true
        startFakeInputLoop()
        startAntiAFKLoop()
        startHumanMovementLoop()
        startRandomBehaviorLoop()
        startRandomActionsLoop()
        startDetectionLoop()
        return true
    end
    return false
end
function antiBan.Stop()
    isRunning=false
    return true
end
function antiBan.Run(data)
    if not data then return false end
    dataRef=data
    if data.enabled==false then
        antiBan.Stop()
        return false
    end
    if data.delayMin then randomDelayMin=data.delayMin end
    if data.delayMax then randomDelayMax=data.delayMax end
    if data.fakeInputInterval then fakeInputInterval=data.fakeInputInterval end
    if data.antiAFKInterval then antiAFKInterval=data.antiAFKInterval end
    if data.behaviorProfile then behaviorProfile=data.behaviorProfile end
    if data.detectionThreshold then detectionThreshold=data.detectionThreshold end
    if data.autoDisableOnDetection~=nil then autoDisableOnDetection=data.autoDisableOnDetection end
    if data.fakeInputEnabled~=nil then fakeInputEnabled=data.fakeInputEnabled end
    if data.antiAFKEnabled~=nil then antiAFKEnabled=data.antiAFKEnabled end
    if data.useHumanLikeMovement~=nil then useHumanLikeMovement=data.useHumanLikeMovement end
    if data.humanLikeSpeed then humanLikeSpeed=data.humanLikeSpeed end
    if data.jitterAmount then jitterAmount=data.jitterAmount end
    antiBanEnabled=true
    if not isRunning then
        isRunning=true
        updateCharacter()
        startFakeInputLoop()
        startAntiAFKLoop()
        startHumanMovementLoop()
        startRandomBehaviorLoop()
        startRandomActionsLoop()
        startDetectionLoop()
    end
    return true
end
function antiBan.Initialize(data)
    dataRef=data
    updateCharacter()
    return true
end
return antiBan
