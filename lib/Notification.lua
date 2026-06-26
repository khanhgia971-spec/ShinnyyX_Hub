local notification={}
notification.__index=notification
local player=game.Players.LocalPlayer
local runService=game:GetService("RunService")
local tweenService=game:GetService("TweenService")
local workspace=game:GetService("Workspace")
local coreGui=game:GetService("CoreGui")
local guiService=game:GetService("GuiService")
local userInput=game:GetService("UserInputService")
local debris=game:GetService("Debris")
local dataRef=nil
local notificationQueue={}
local activeNotifications={}
local isProcessing=false
local defaultSettings={
    position="TopRight",
    duration=3,
    fadeDuration=0.3,
    slideDuration=0.3,
    spacing=10,
    maxVisible=5,
    showIcon=true,
    showCloseButton=true,
    soundEnabled=true,
    queueEnabled=true,
    persistOnRespawn=false
}
local typeColors={
    Success=Color3.fromRGB(0,255,0),
    Error=Color3.fromRGB(255,0,0),
    Warning=Color3.fromRGB(255,255,0),
    Info=Color3.fromRGB(0,200,255),
    Custom=Color3.fromRGB(200,200,200)
}
local typeIcons={
    Success="✓",
    Error="✗",
    Warning="⚠",
    Info="ℹ"
}
local function getScreenSize()
    return guiService:GetScreenSize()
end
local function createNotificationFrame(title,message,notifType,duration,customColor)
    local screenGui=Instance.new("ScreenGui")
    screenGui.Name="Notification_"..tostring(os.time())
    screenGui.Parent=coreGui
    screenGui.ResetOnSpawn=not defaultSettings.persistOnRespawn
    local mainFrame=Instance.new("Frame")
    mainFrame.Size=UDim2.new(0,350,0,80)
    mainFrame.BackgroundColor3=Color3.fromRGB(20,20,40)
    mainFrame.BackgroundTransparency=0.2
    mainFrame.BorderSizePixel=0
    mainFrame.ClipsDescendants=true
    mainFrame.Parent=screenGui
    local colorLine=Instance.new("Frame")
    colorLine.Size=UDim2.new(0,5,1,0)
    colorLine.BackgroundColor3=customColor or typeColors[notifType] or Color3.fromRGB(255,255,255)
    colorLine.Parent=mainFrame
    local closeBtn=Instance.new("TextButton")
    closeBtn.Size=UDim2.new(0,25,0,25)
    closeBtn.Position=UDim2.new(1,-30,0,5)
    closeBtn.BackgroundColor3=Color3.fromRGB(255,0,0)
    closeBtn.BackgroundTransparency=0.5
    closeBtn.Text="✕"
    closeBtn.TextColor3=Color3.fromRGB(255,255,255)
    closeBtn.TextScaled=true
    closeBtn.Parent=mainFrame
    closeBtn.MouseButton1Click:Connect(function()
        notification:DestroyNotification(screenGui)
    end)
    local iconLabel=Instance.new("TextLabel")
    iconLabel.Size=UDim2.new(0,40,0,40)
    iconLabel.Position=UDim2.new(0,10,0,20)
    iconLabel.BackgroundTransparency=1
    iconLabel.Text=typeIcons[notifType] or "ℹ"
    iconLabel.TextColor3=customColor or typeColors[notifType] or Color3.fromRGB(255,255,255)
    iconLabel.TextScaled=true
    iconLabel.Font=Enum.Font.GothamBold
    iconLabel.Parent=mainFrame
    local titleLabel=Instance.new("TextLabel")
    titleLabel.Size=UDim2.new(0,250,0,25)
    titleLabel.Position=UDim2.new(0,55,0,8)
    titleLabel.BackgroundTransparency=1
    titleLabel.Text=title
    titleLabel.TextColor3=Color3.fromRGB(255,255,255)
    titleLabel.TextScaled=true
    titleLabel.Font=Enum.Font.GothamBold
    titleLabel.TextXAlignment=Enum.TextXAlignment.Left
    titleLabel.Parent=mainFrame
    local msgLabel=Instance.new("TextLabel")
    msgLabel.Size=UDim2.new(0,250,0,30)
    msgLabel.Position=UDim2.new(0,55,0,35)
    msgLabel.BackgroundTransparency=1
    msgLabel.Text=message
    msgLabel.TextColor3=Color3.fromRGB(200,200,200)
    msgLabel.TextScaled=true
    msgLabel.Font=Enum.Font.Gotham
    msgLabel.TextXAlignment=Enum.TextXAlignment.Left
    msgLabel.Parent=mainFrame
    return screenGui,mainFrame
end
local function positionNotification(frame,index,total)
    local screenSize=getScreenSize()
    local position=defaultSettings.position
    local spacing=defaultSettings.spacing
    local frameSize=frame.AbsoluteSize or Vector2.new(350,80)
    local x=0
    local y=0
    if position=="TopRight" then
        x=screenSize.X-frameSize.X-spacing
        y=spacing+index*(frameSize.Y+spacing)
    elseif position=="TopLeft" then
        x=spacing
        y=spacing+index*(frameSize.Y+spacing)
    elseif position=="BottomRight" then
        x=screenSize.X-frameSize.X-spacing
        y=screenSize.Y-frameSize.Y-spacing-index*(frameSize.Y+spacing)
    elseif position=="BottomLeft" then
        x=spacing
        y=screenSize.Y-frameSize.Y-spacing-index*(frameSize.Y+spacing)
    elseif position=="Center" then
        x=(screenSize.X-frameSize.X)/2
        y=(screenSize.Y-frameSize.Y)/2+index*(frameSize.Y+spacing)
    end
    frame.Position=UDim2.new(0,x,0,y)
end
local function animateIn(frame)
    local originalPos=frame.Position
    frame.Position=UDim2.new(0,originalPos.X.Offset+200,0,originalPos.Y.Offset)
    frame.BackgroundTransparency=1
    local t1=tweenService:Create(frame,TweenInfo.new(defaultSettings.slideDuration,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=originalPos})
    local t2=tweenService:Create(frame,TweenInfo.new(defaultSettings.fadeDuration,Enum.EasingStyle.Linear),{BackgroundTransparency=0.2})
    t1:Play()
    t2:Play()
    t1.Completed:Wait()
end
local function animateOut(frame,callback)
    local targetPos=frame.Position
    targetPos=UDim2.new(0,targetPos.X.Offset+200,0,targetPos.Y.Offset)
    local t1=tweenService:Create(frame,TweenInfo.new(defaultSettings.slideDuration,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Position=targetPos})
    local t2=tweenService:Create(frame,TweenInfo.new(defaultSettings.fadeDuration,Enum.EasingStyle.Linear),{BackgroundTransparency=1})
    t1:Play()
    t2:Play()
    t1.Completed:Connect(function()
        if callback then callback() end
    end)
end
local function processQueue()
    if isProcessing then return end
    if #notificationQueue==0 then
        isProcessing=false
        return
    end
    isProcessing=true
    local notifData=table.remove(notificationQueue,1)
    local screenGui,mainFrame=createNotificationFrame(notifData.title,notifData.message,notifData.type,notifData.duration,notifData.customColor)
    table.insert(activeNotifications,{gui=screenGui,frame=mainFrame,data=notifData})
    local index=#activeNotifications-1
    if index<0 then index=0 end
    positionNotification(mainFrame,index)
    animateIn(mainFrame)
    task.wait(notifData.duration or defaultSettings.duration)
    if screenGui.Parent then
        notification:DestroyNotification(screenGui)
    end
    isProcessing=false
    processQueue()
end
local function addToQueue(title,message,notifType,duration,customColor)
    if not title then title="Notification" end
    if not message then message="" end
    notifType=notifType or "Info"
    duration=duration or defaultSettings.duration
    local data={title=title,message=message,type=notifType,duration=duration,customColor=customColor}
    if defaultSettings.queueEnabled then
        table.insert(notificationQueue,data)
        if not isProcessing then
            processQueue()
        end
    else
        if #activeNotifications>=defaultSettings.maxVisible then
            local oldest=activeNotifications[1]
            if oldest then
                notification:DestroyNotification(oldest.gui)
            end
        end
        local screenGui,mainFrame=createNotificationFrame(title,message,notifType,duration,customColor)
        table.insert(activeNotifications,{gui=screenGui,frame=mainFrame,data=data})
        local index=#activeNotifications-1
        if index<0 then index=0 end
        positionNotification(mainFrame,index)
        animateIn(mainFrame)
        task.spawn(function()
            task.wait(duration)
            if screenGui.Parent then
                notification:DestroyNotification(screenGui)
            end
        end)
    end
end
function notification.Show(title,message,notifType,duration,customColor)
    addToQueue(title,message,notifType,duration,customColor)
end
function notification.Success(title,message,duration)
    addToQueue(title,message,"Success",duration)
end
function notification.Error(title,message,duration)
    addToQueue(title,message,"Error",duration)
end
function notification.Warning(title,message,duration)
    addToQueue(title,message,"Warning",duration)
end
function notification.Info(title,message,duration)
    addToQueue(title,message,"Info",duration)
end
function notification.Custom(title,message,color,duration)
    addToQueue(title,message,"Custom",duration,color)
end
function notification.DestroyNotification(gui)
    if not gui or not gui.Parent then return end
    local frame=nil
    for i,v in ipairs(activeNotifications) do
        if v.gui==gui then
            frame=v.frame
            table.remove(activeNotifications,i)
            break
        end
    end
    if frame then
        animateOut(frame,function()
            gui:Destroy()
        end)
    else
        gui:Destroy()
    end
    for i,v in ipairs(activeNotifications) do
        positionNotification(v.frame,i-1)
    end
end
function notification.DestroyAll()
    for _,v in ipairs(activeNotifications) do
        pcall(function()v.gui:Destroy()end)
    end
    activeNotifications={}
    notificationQueue={}
    isProcessing=false
end
function notification.SetPosition(pos)
    if pos=="TopRight" or pos=="TopLeft" or pos=="BottomRight" or pos=="BottomLeft" or pos=="Center" then
        defaultSettings.position=pos
        for i,v in ipairs(activeNotifications) do
            positionNotification(v.frame,i-1)
        end
        return true
    end
    return false
end
function notification.SetDuration(duration)
    defaultSettings.duration=duration
    return true
end
function notification.SetFadeDuration(duration)
    defaultSettings.fadeDuration=duration
    return true
end
function notification.SetSlideDuration(duration)
    defaultSettings.slideDuration=duration
    return true
end
function notification.SetSpacing(spacing)
    defaultSettings.spacing=spacing
    for i,v in ipairs(activeNotifications) do
        positionNotification(v.frame,i-1)
    end
    return true
end
function notification.SetMaxVisible(max)
    defaultSettings.maxVisible=max
    return true
end
function notification.SetQueueEnabled(enabled)
    defaultSettings.queueEnabled=enabled
    return true
end
function notification.SetSoundEnabled(enabled)
    defaultSettings.soundEnabled=enabled
    return true
end
function notification.SetPersistOnRespawn(enabled)
    defaultSettings.persistOnRespawn=enabled
    return true
end
function notification.SetTypeColor(notifType,color)
    typeColors[notifType]=color
    return true
end
function notification.SetTypeIcon(notifType,icon)
    typeIcons[notifType]=icon
    return true
end
function notification.GetSettings()
    local settings={}
    for k,v in pairs(defaultSettings) do
        settings[k]=v
    end
    return settings
end
function notification.GetActiveCount()
    return #activeNotifications
end
function notification.GetQueueCount()
    return #notificationQueue
end
function notification.ClearQueue()
    notificationQueue={}
    return true
end
function notification.SetCustomColor(notifType,color)
    typeColors[notifType]=color
    return true
end
function notification.SetCustomIcon(notifType,icon)
    typeIcons[notifType]=icon
    return true
end
function notification.AddCustomType(name,color,icon)
    typeColors[name]=color or Color3.fromRGB(255,255,255)
    typeIcons[name]=icon or "•"
    return true
end
function notification.RemoveCustomType(name)
    typeColors[name]=nil
    typeIcons[name]=nil
    return true
end
function notification.GetTypeList()
    local list={}
    for k,_ in pairs(typeColors) do
        table.insert(list,k)
    end
    return list
end
function notification.PlaySound(soundId)
    if not defaultSettings.soundEnabled then return false end
    local sound=Instance.new("Sound")
    sound.SoundId=soundId or "rbxassetid://9120269583"
    sound.Parent=workspace
    sound:Play()
    debris:AddItem(sound,5)
    return true
end
function notification.QueueShow(title,message,notifType,duration,customColor)
    addToQueue(title,message,notifType,duration,customColor)
end
function notification.QueueClear()
    notificationQueue={}
    return true
end
function notification.ProcessNext()
    if isProcessing then return false end
    if #notificationQueue>0 then
        processQueue()
        return true
    end
    return false
end
function notification.PauseQueue()
    isProcessing=true
    return true
end
function notification.ResumeQueue()
    isProcessing=false
    processQueue()
    return true
end
function notification.IsProcessing()
    return isProcessing
end
function notification.DestroyAllAndClear()
    notification.DestroyAll()
    notification.ClearQueue()
    return true
end
function notification.CreatePersistentNotification(title,message,notifType,duration)
    -- Tạo thông báo không tự động biến mất
    local customDuration=duration or 999999
    addToQueue(title,message,notifType,customDuration)
    return true
end
function notification.UpdateNotification(index,title,message)
    if index<1 or index>#activeNotifications then return false end
    local data=activeNotifications[index]
    if data and data.gui then
        local gui=data.gui
        local titleLabel=gui:FindFirstChild("TitleLabel")
        local msgLabel=gui:FindFirstChild("MessageLabel")
        if titleLabel then titleLabel.Text=title end
        if msgLabel then msgLabel.Text=message end
        return true
    end
    return false
end
function notification.GetNotificationData(index)
    if index<1 or index>#activeNotifications then return nil end
    return activeNotifications[index].data
end
function notification.GetAllNotifications()
    local list={}
    for _,v in ipairs(activeNotifications) do
        table.insert(list,v.data)
    end
    return list
end
function notification.SetGlobalDuration(duration)
    defaultSettings.duration=duration
    return true
end
function notification.ResetToDefaults()
    defaultSettings={
        position="TopRight",
        duration=3,
        fadeDuration=0.3,
        slideDuration=0.3,
        spacing=10,
        maxVisible=5,
        showIcon=true,
        showCloseButton=true,
        soundEnabled=true,
        queueEnabled=true,
        persistOnRespawn=false
    }
    typeColors={
        Success=Color3.fromRGB(0,255,0),
        Error=Color3.fromRGB(255,0,0),
        Warning=Color3.fromRGB(255,255,0),
        Info=Color3.fromRGB(0,200,255),
        Custom=Color3.fromRGB(200,200,200)
    }
    typeIcons={
        Success="✓",
        Error="✗",
        Warning="⚠",
        Info="ℹ"
    }
    return true
end
function notification.Initialize(data)
    dataRef=data
    if data and data.notificationSettings then
        for k,v in pairs(data.notificationSettings) do
            if defaultSettings[k]~=nil then
                defaultSettings[k]=v
            end
        end
    end
    return true
end
return notification
