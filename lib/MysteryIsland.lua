local mysteryIsland={}
mysteryIsland.__index=mysteryIsland
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
local dataRef=nil
local isRunning=false
local character=nil
local humanoid=nil
local rootPart=nil
local currentIsland=nil
local islandPosition=nil
local highestPoint=nil
local gearPosition=nil
local leverPosition=nil
local moonPhaseChecked=false
local waitingForMoon=false
local moonAchieved=false
local gearCollected=false
local leverActivated=false
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
local function findMysteryIsland()
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Model") and v:FindFirstChild("Head") then
            local name=v.Name:lower()
            if name:find("mysterious") or name:find("island") or name:find("moon") then
                return v
            end
        end
    end
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Part") and v.Name:lower():find("mysterious") then
            return v
        end
    end
    return nil
end
local function getHighestPoint(island)
    if not island then return nil end
    local highestY=-math.huge
    local highestPos=nil
    local function scan(part)
        if part:IsA("BasePart") then
            local y=part.Position.Y
            if y>highestY then
                highestY=y
                highestPos=part.Position
            end
        end
        for _,child in pairs(part:GetChildren()) do
            scan(child)
        end
    end
    scan(island)
    if highestPos then
        return highestPos+Vector3.new(0,3,0)
    end
    if island:FindFirstChild("Head") then
        return island.Head.Position+Vector3.new(0,5,0)
    end
    return island.Position+Vector3.new(0,10,0)
end
local function getGearPosition(island)
    if not island then return nil end
    for _,v in pairs(island:GetDescendants()) do
        if v:IsA("Part") and v.Name:lower():find("gear") then
            return v.Position+Vector3.new(0,1,0)
        end
    end
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Part") and v.Name:lower():find("gear") then
            return v.Position+Vector3.new(0,1,0)
        end
    end
    return nil
end
local function getLeverPosition(island)
    if not island then return nil end
    for _,v in pairs(island:GetDescendants()) do
        if v:IsA("Part") and v.Name:lower():find("lever") then
            return v.Position+Vector3.new(0,1,0)
        end
    end
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Part") and v.Name:lower():find("lever") then
            return v.Position+Vector3.new(0,1,0)
        end
    end
    return nil
end
local function getMoonPhase()
    local timeOfDay=lighting.TimeOfDay
    local hour=tonumber(string.sub(timeOfDay,1,2)) or 0
    local minute=tonumber(string.sub(timeOfDay,4,5)) or 0
    local totalMinutes=hour*60+minute
    local dayCycle=80
    local phase=math.floor((totalMinutes/10)%8)
    if phase<0 then phase=0 end
    if phase>7 then phase=7 end
    local sky=workspace:FindFirstChild("Sky")
    if sky then
        local moon=sky:FindFirstChild("Moon")
        if moon and moon:FindFirstChild("Rotation") then
            local rot=moon.Rotation.Y or 0
            if rot>315 or rot<45 then phase=4
            elseif rot>45 and rot<135 then phase=2
            elseif rot>135 and rot<225 then phase=0
            elseif rot>225 and rot<315 then phase=6 end
        end
    end
    return phase
end
local function isFullMoon()
    local phase=getMoonPhase()
    return phase==4 or phase==3 or phase==5
end
local function waitForMoon(timeout)
    timeout=timeout or 300
    local start=tick()
    while tick()-start<timeout do
        if isFullMoon() then return true end
        wait(1)
    end
    return false
end
local function activateRaceV3()
    local race=player:FindFirstChild("Race")
    if race and race:IsA("StringValue") then
        local v3=player:FindFirstChild("RaceV3")
        if not v3 or (v3:IsA("BoolValue") and v3.Value==false) then
            if humanoid then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                wait(0.5)
                humanoid:ChangeState(Enum.HumanoidStateType.Landed)
                return true
            end
        end
    end
    return false
end
local function showPrompt(title,message,options)
    local gui=Instance.new("ScreenGui")
    gui.Name="MysteryIslandPrompt"
    gui.Parent=coreGui
    local frame=Instance.new("Frame")
    frame.Size=UDim2.new(0,400,0,200)
    frame.Position=UDim2.new(0.5,-200,0.5,-100)
    frame.BackgroundColor3=Color3.fromRGB(10,10,30)
    frame.BackgroundTransparency=0.2
    frame.BorderSizePixel=0
    frame.Parent=gui
    local titleLabel=Instance.new("TextLabel")
    titleLabel.Size=UDim2.new(1,0,0,40)
    titleLabel.Text=title
    titleLabel.TextColor3=Color3.fromRGB(0,200,255)
    titleLabel.TextScaled=true
    titleLabel.Font=Enum.Font.GothamBold
    titleLabel.Parent=frame
    local msgLabel=Instance.new("TextLabel")
    msgLabel.Size=UDim2.new(1,0,0,60)
    msgLabel.Position=UDim2.new(0,0,0,45)
    msgLabel.Text=message
    msgLabel.TextColor3=Color3.fromRGB(255,255,255)
    msgLabel.TextScaled=true
    msgLabel.Parent=frame
    local btnFrame=Instance.new("Frame")
    btnFrame.Size=UDim2.new(1,0,0,50)
    btnFrame.Position=UDim2.new(0,0,0,120)
    btnFrame.BackgroundTransparency=1
    btnFrame.Parent=frame
    local result=nil
    for i,opt in ipairs(options) do
        local btn=Instance.new("TextButton")
        btn.Size=UDim2.new(0.4,0,1,0)
        btn.Position=UDim2.new(0.1+(i-1)*0.5,0,0,0)
        btn.BackgroundColor3=Color3.fromRGB(40,40,80)
        btn.Text=opt
        btn.TextColor3=Color3.fromRGB(255,255,255)
        btn.Parent=btnFrame
        btn.MouseButton1Click:Connect(function()
            result=opt
            gui:Destroy()
        end)
    end
    repeat wait(0.1) until result~=nil or not gui.Parent
    if result then
        return result
    end
    return nil
end
local function processMysteryIsland(data)
    if not data or not data.enabled then
        if isRunning then mysteryIsland.Stop() end
        return
    end
    if not rootPart or not humanoid then updateCharacter() end
    if not rootPart or not humanoid then return end
    if not currentIsland or not currentIsland.Parent then
        currentIsland=findMysteryIsland()
        if not currentIsland then
            print("[MysteryIsland] Không tìm thấy đảo bí ẩn, đang chờ...")
            return
        end
        islandPosition=currentIsland.Position or currentIsland:FindFirstChild("Head").Position
        highestPoint=getHighestPoint(currentIsland)
        gearPosition=getGearPosition(currentIsland)
        leverPosition=getLeverPosition(currentIsland)
    end
    if not highestPoint then
        highestPoint=islandPosition+Vector3.new(0,20,0)
    end
    if not gearPosition then
        gearPosition=islandPosition+Vector3.new(0,5,0)
    end
    if not leverPosition then
        leverPosition=islandPosition+Vector3.new(0,2,0)
    end
    if not moonAchieved then
        local distToHigh=getDistance(rootPart.Position,highestPoint)
        if distToHigh>5 then
            moveToPosition(highestPoint,5)
        else
            if not moonPhaseChecked then
                activateRaceV3()
                moonPhaseChecked=true
            end
            if waitForMoon(120) then
                moonAchieved=true
                print("[MysteryIsland] Trăng sáng đã đạt!")
            end
        end
        return
    end
    if moonAchieved and not gearCollected then
        local distToGear=getDistance(rootPart.Position,gearPosition)
        if distToGear>5 then
            moveToPosition(gearPosition,5)
        else
            gearCollected=true
            print("[MysteryIsland] Đã thu thập bánh răng!")
            local choice=showPrompt("Bánh răng đã thu thập!","Bạn có muốn đến thời gian để gạt cần không?","Có","Không")
            if choice=="Có" then
                local distToLever=getDistance(rootPart.Position,leverPosition)
                if distToLever>5 then
                    moveToPosition(leverPosition,5)
                end
                leverActivated=true
                print("[MysteryIsland] Cần gạt đã được kích hoạt!")
            else
                print("[MysteryIsland] Cảm ơn bạn đã sử dụng dịch vụ!")
            end
            mysteryIsland.Stop()
        end
        return
    end
end
local function startMysteryIslandLoop(data)
    if isRunning then return end
    isRunning=true
    moonAchieved=false
    gearCollected=false
    leverActivated=false
    moonPhaseChecked=false
    task.spawn(function()
        while isRunning do
            wait(0.5)
            pcall(function()processMysteryIsland(data)end)
        end
    end)
end
function mysteryIsland.Stop()
    isRunning=false
    currentIsland=nil
    islandPosition=nil
    highestPoint=nil
    gearPosition=nil
    leverPosition=nil
    return true
end
function mysteryIsland.Run(data)
    if not data then return false end
    dataRef=data
    if not data.enabled then
        if isRunning then mysteryIsland.Stop() end
        return false
    end
    if not isRunning then
        updateCharacter()
        startMysteryIslandLoop(data)
    end
    return true
end
function mysteryIsland.GetStatus()
    return{
        isRunning=isRunning,
        islandFound=currentIsland~=nil,
        moonAchieved=moonAchieved,
        gearCollected=gearCollected,
        leverActivated=leverActivated,
        highestPoint=highestPoint,
        gearPosition=gearPosition,
        leverPosition=leverPosition
    }
end
function mysteryIsland.FindIsland()
    local island=findMysteryIsland()
    if island then
        currentIsland=island
        islandPosition=island.Position or island:FindFirstChild("Head").Position
        highestPoint=getHighestPoint(island)
        gearPosition=getGearPosition(island)
        leverPosition=getLeverPosition(island)
        return true
    end
    return false
end
function mysteryIsland.MoveToHighest()
    if highestPoint then
        return moveToPosition(highestPoint)
    end
    return false
end
function mysteryIsland.MoveToGear()
    if gearPosition then
        return moveToPosition(gearPosition)
    end
    return false
end
function mysteryIsland.MoveToLever()
    if leverPosition then
        return moveToPosition(leverPosition)
    end
    return false
end
function mysteryIsland.WaitForMoon(timeout)
    return waitForMoon(timeout)
end
function mysteryIsland.ActivateRaceV3()
    return activateRaceV3()
end
function mysteryIsland.ShowPrompt(title,message,options)
    return showPrompt(title,message,options)
end
function mysteryIsland.Pause()
    isRunning=false
    return true
end
function mysteryIsland.Resume()
    if dataRef and dataRef.enabled then
        isRunning=true
        startMysteryIslandLoop(dataRef)
        return true
    end
    return false
end
function mysteryIsland.Destroy()
    mysteryIsland.Stop()
    dataRef=nil
    return true
end
function mysteryIsland.Initialize(data)
    dataRef=data
    updateCharacter()
    return true
end
return mysteryIsland
