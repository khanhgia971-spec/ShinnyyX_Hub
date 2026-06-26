local world={}
world.__index=world
local player=game.Players.LocalPlayer
local runService=game:GetService("RunService")
local userInput=game:GetService("UserInputService")
local workspace=game:GetService("Workspace")
local lighting=game:GetService("Lighting")
local players=game:GetService("Players")
local tweenService=game:GetService("TweenService")
local debris=game:GetService("Debris")
local collectionService=game:GetService("CollectionService")
local replicatedStorage=game:GetService("ReplicatedStorage")
local dataRef=nil local isRunning=false
local currentTime="Day" local currentWeather="Clear"
local currentFogStart=0 local currentFogEnd=1000
local fogEnabled=false
local timeCycleSpeed=1
local weatherCycle={}
local weatherEvents={}
local seaLevel=0 local seaLevelOffset=0
local function getDistance(pos1,pos2)
    if not pos1 or not pos2 then return math.huge end
    return (pos1-pos2).Magnitude
end
local function setTimeOfDay(timeString)
    local times={
        Day="12:00:00",
        Night="00:00:00",
        Sunrise="06:00:00",
        Sunset="18:00:00",
        Midnight="00:00:00",
        Noon="12:00:00"
    }
    local timeStr=times[timeString]
    if timeStr then
        lighting.TimeOfDay=timeStr
        currentTime=timeString
        return true
    end
    return false
end
local function setWeather(weatherType)
    local weatherSettings={
        Clear={Brightness=1,Ambient=Color3.fromRGB(255,255,255),FogStart=0,FogEnd=1000},
        Rain={Brightness=0.6,Ambient=Color3.fromRGB(150,150,180),FogStart=0,FogEnd=500},
        Storm={Brightness=0.3,Ambient=Color3.fromRGB(80,80,120),FogStart=0,FogEnd=300},
        Fog={Brightness=0.5,Ambient=Color3.fromRGB(200,200,220),FogStart=10,FogEnd=200},
        Snow={Brightness=0.8,Ambient=Color3.fromRGB(220,230,255),FogStart=0,FogEnd=800},
        Sandstorm={Brightness=0.4,Ambient=Color3.fromRGB(180,160,100),FogStart=20,FogEnd=400}
    }
    local settings=weatherSettings[weatherType]
    if settings then
        lighting.Brightness=settings.Brightness
        lighting.Ambient=settings.Ambient
        lighting.FogStart=settings.FogStart
        lighting.FogEnd=settings.FogEnd
        if weatherType=="Rain" then
            lighting.RainIntensity=0.5
        elseif weatherType=="Storm" then
            lighting.RainIntensity=1
        else
            lighting.RainIntensity=0
        end
        currentWeather=weatherType
        return true
    end
    return false
end
local function setFog(start,endDist)
    start=start or 0
    endDist=endDist or 1000
    lighting.FogStart=start
    lighting.FogEnd=endDist
    currentFogStart=start
    currentFogEnd=endDist
    fogEnabled=true
    return true
end
local function disableFog()
    lighting.FogStart=0
    lighting.FogEnd=10000
    fogEnabled=false
    return true
end
local function setSeaLevel(level)
    seaLevel=level or 0
    local sea=workspace:FindFirstChild("Sea")
    if sea then
        sea.Position=Vector3.new(0,level,0)
        return true
    end
    return false
end
local function getSeaLevel()
    local sea=workspace:FindFirstChild("Sea")
    if sea then
        return sea.Position.Y
    end
    return 0
end
local function setBrightness(value)
    value=math.clamp(value,0,1)
    lighting.Brightness=value
    return true
end
local function setAmbientColor(color)
    lighting.Ambient=color
    return true
end
local function setOutdoorAmbient(color)
    lighting.OutdoorAmbient=color
    return true
end
local function setColorCorrection(value)
    local cc=lighting:FindFirstChild("ColorCorrection")
    if not cc then
        cc=Instance.new("ColorCorrectionEffect")
        cc.Parent=lighting
    end
    cc.Brightness=value
    return true
end
local function setBloom(value)
    local bloom=lighting:FindFirstChild("Bloom")
    if not bloom then
        bloom=Instance.new("BloomEffect")
        bloom.Parent=lighting
    end
    bloom.Intensity=value
    return true
end
local function setDepthOfField(value)
    local dof=lighting:FindFirstChild("DepthOfField")
    if not dof then
        dof=Instance.new("DepthOfFieldEffect")
        dof.Parent=lighting
    end
    dof.FocusDistance=value
    return true
end
local function setTimeScale(speed)
    timeCycleSpeed=speed or 1
    return true
end
local function setShadowSoftness(value)
    local sun=lighting:FindFirstChild("SunRays")
    if sun then
        sun.Intensity=value
    end
    return true
end
local function startWeatherCycle()
    local weathers={"Clear","Rain","Storm","Fog","Snow","Sandstorm"}
    task.spawn(function()
        while isRunning do
            wait(60)
            local newWeather=weathers[math.random(1,#weathers)]
            setWeather(newWeather)
            table.insert(weatherEvents,{weather=newWeather,time=os.time()})
            if #weatherEvents>20 then table.remove(weatherEvents,1) end
        end
    end)
end
local function startTimeCycle()
    task.spawn(function()
        while isRunning do
            wait(10)
            local currentHour=tonumber(string.sub(lighting.TimeOfDay,1,2))
            if currentHour then
                currentHour=currentHour+0.1*timeCycleSpeed
                if currentHour>=24 then currentHour=0 end
                local newTime=string.format("%02d:%02d:%02d",math.floor(currentHour),(currentHour%1)*60,0)
                lighting.TimeOfDay=newTime
            end
        end
    end)
end
local function getIslandInfo()
    local islands={}
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Model") and v:FindFirstChild("Head") then
            if v.Name:match("Island") or v.Name:match("Island") then
                table.insert(islands,{name=v.Name,position=v:FindFirstChild("Head") and v.Head.Position or v.Position})
            end
        end
    end
    return islands
end
local function getCurrentWeather()
    return currentWeather
end
local function getCurrentTime()
    return currentTime
end
local function isNight()
    local hour=tonumber(string.sub(lighting.TimeOfDay,1,2))
    return hour>=18 or hour<6
end
local function isDay()
    return not isNight()
end
local function setAllFog(start,endDist)
    return setFog(start,endDist)
end
local function resetWorld()
    setTimeOfDay("Day")
    setWeather("Clear")
    disableFog()
    setBrightness(1)
    setSeaLevel(0)
    setTimeScale(1)
    local cc=lighting:FindFirstChild("ColorCorrection")
    if cc then cc:Destroy() end
    local bloom=lighting:FindFirstChild("Bloom")
    if bloom then bloom:Destroy() end
    local dof=lighting:FindFirstChild("DepthOfField")
    if dof then dof:Destroy() end
    return true
end
local function processWorld(data)
    if data.timeOfDay and data.timeOfDay~=currentTime then
        setTimeOfDay(data.timeOfDay)
    end
    if data.weather and data.weather~=currentWeather then
        setWeather(data.weather)
    end
    if data.fogEnabled then
        if not fogEnabled then
            setFog(data.fogStart or 0,data.fogEnd or 1000)
        end
        if data.fogStart and data.fogStart~=currentFogStart then
            lighting.FogStart=data.fogStart
            currentFogStart=data.fogStart
        end
        if data.fogEnd and data.fogEnd~=currentFogEnd then
            lighting.FogEnd=data.fogEnd
            currentFogEnd=data.fogEnd
        end
    else
        if fogEnabled then disableFog() end
    end
    if data.brightness then
        setBrightness(data.brightness)
    end
    if data.seaLevel then
        setSeaLevel(data.seaLevel)
    end
    if data.timeCycleSpeed then
        timeCycleSpeed=data.timeCycleSpeed
    end
    if data.ambientColor then
        setAmbientColor(data.ambientColor)
    end
    if data.outdoorAmbient then
        setOutdoorAmbient(data.outdoorAmbient)
    end
    if data.colorCorrection then
        setColorCorrection(data.colorCorrection)
    end
    if data.bloom then
        setBloom(data.bloom)
    end
end
local function startWorldLoop(data)
    if isRunning then return end
    isRunning=true
    startTimeCycle()
    startWeatherCycle()
    task.spawn(function()
        while isRunning do
            wait(0.5)
            pcall(function()processWorld(data)end)
        end
    end)
end
function world.Stop()
    isRunning=false
    return true
end
function world.Apply(data)
    if not data then return false end
    dataRef=data
    if not isRunning then
        startWorldLoop(data)
    end
    return true
end
function world.SetTime(time)
    if dataRef then
        dataRef.timeOfDay=time
        setTimeOfDay(time)
        return true
    end
    return false
end
function world.SetWeather(weather)
    if dataRef then
        dataRef.weather=weather
        setWeather(weather)
        return true
    end
    return false
end
function world.ToggleFog()
    if dataRef then
        dataRef.fogEnabled=not dataRef.fogEnabled
        if dataRef.fogEnabled then
            setFog(dataRef.fogStart or 0,dataRef.fogEnd or 1000)
        else
            disableFog()
        end
        return dataRef.fogEnabled
    end
    return false
end
function world.SetFog(start,endDist)
    if dataRef then
        dataRef.fogStart=start
        dataRef.fogEnd=endDist
        dataRef.fogEnabled=true
        setFog(start,endDist)
        return true
    end
    return false
end
function world.SetBrightness(value)
    if dataRef then
        dataRef.brightness=value
        setBrightness(value)
        return true
    end
    return false
end
function world.SetSeaLevel(level)
    if dataRef then
        dataRef.seaLevel=level
        setSeaLevel(level)
        return true
    end
    return false
end
function world.SetTimeCycleSpeed(speed)
    if dataRef then
        dataRef.timeCycleSpeed=speed
        timeCycleSpeed=speed
        return true
    end
    return false
end
function world.SetAmbientColor(color)
    if dataRef then
        dataRef.ambientColor=color
        setAmbientColor(color)
        return true
    end
    return false
end
function world.SetOutdoorAmbient(color)
    if dataRef then
        dataRef.outdoorAmbient=color
        setOutdoorAmbient(color)
        return true
    end
    return false
end
function world.SetColorCorrection(value)
    if dataRef then
        dataRef.colorCorrection=value
        setColorCorrection(value)
        return true
    end
    return false
end
function world.SetBloom(value)
    if dataRef then
        dataRef.bloom=value
        setBloom(value)
        return true
    end
    return false
end
function world.GetStatus()
    return{
        isRunning=isRunning,
        timeOfDay=currentTime,
        weather=currentWeather,
        fogEnabled=fogEnabled,
        fogStart=currentFogStart,
        fogEnd=currentFogEnd,
        brightness=lighting.Brightness,
        seaLevel=getSeaLevel(),
        timeCycleSpeed=timeCycleSpeed,
        isNight=isNight(),
        isDay=isDay()
    }
end
function world.GetIslands()
    return getIslandInfo()
end
function world.GetWeatherEvents()
    return weatherEvents
end
function world.ClearWeatherEvents()
    weatherEvents={}
    return true
end
function world.Reset()
    resetWorld()
    if dataRef then
        dataRef.timeOfDay="Day"
        dataRef.weather="Clear"
        dataRef.fogEnabled=false
        dataRef.brightness=1
        dataRef.seaLevel=0
        dataRef.timeCycleSpeed=1
    end
    return true
end
function world.Pause()
    isRunning=false
    return true
end
function world.Resume()
    if dataRef then
        isRunning=true
        startWorldLoop(dataRef)
        return true
    end
    return false
end
function world.Destroy()
    isRunning=false
    resetWorld()
    dataRef=nil
    return true
end
function world.Initialize(data)
    dataRef=data
    resetWorld()
    if data then
        if data.timeOfDay then setTimeOfDay(data.timeOfDay) end
        if data.weather then setWeather(data.weather) end
        if data.fogEnabled then setFog(data.fogStart or 0,data.fogEnd or 1000) end
        if data.brightness then setBrightness(data.brightness) end
        if data.seaLevel then setSeaLevel(data.seaLevel) end
        if data.timeCycleSpeed then timeCycleSpeed=data.timeCycleSpeed end
    end
    return true
end
return world
