local settings={}
settings.__index=settings
local player=game.Players.LocalPlayer
local runService=game:GetService("RunService")
local httpService=game:GetService("HttpService")
local workspace=game:GetService("Workspace")
local players=game:GetService("Players")
local userInput=game:GetService("UserInputService")
local tweenService=game:GetService("TweenService")
local debris=game:GetService("Debris")
local collectionService=game:GetService("CollectionService")
local replicatedStorage=game:GetService("ReplicatedStorage")
local dataRef=nil local isRunning=false
local profiles={} local currentProfile="Default"
local settingsFile="" local saveInterval=30
local autoSaveTimer=0 local backupCounter=0
local configVersion="4.0.0"
local defaultSettings={
    AutoFarm={enabled=false,targetType="Quái",targetName="",radius=500,speed=1,useSkill=true,collectItems=true,autoQuest=false},
    AutoQuest={enabled=false,npcName="",questType="Daily",autoTurnIn=true},
    Teleport={targetPosition=Vector3.new(0,0,0),targetPlayer="",islandName="Jungle"},
    ESP={enabled=false,showPlayers=true,showFruits=true,showItems=false,showBoss=true,showNPC=false,distance=1000,colorPlayer=Color3.fromRGB(0,255,0),colorFruit=Color3.fromRGB(255,255,0),colorItem=Color3.fromRGB(0,100,255),colorBoss=Color3.fromRGB(255,0,0),colorNPC=Color3.fromRGB(200,200,200)},
    Combat={autoAttack=false,autoDodge=false,spamSkill=false,skillKey="Q",hitboxMultiplier=1,damageMultiplier=1,targetPriority="LowestHealth",radius=100,comboType="Basic",comboEnabled=false},
    Movement={walkSpeed=16,jumpPower=50,fly=false,noclip=false,speedHack=false,swimSpeed=10,flySpeed=50,gravity=1,speedMultiplier=2},
    Items={spawnFruit="Leopard",spawnWeapon="Saber",autoCollect=false,collectRadius=2000,collectFilter="All"},
    Player={godMode=false,infiniteEnergy=false,infiniteStamina=false,infiniteMana=false,resetStats=false,maxHealth=999999,maxEnergy=999999,autoAssignStats=false,statPriority="Melee"},
    World={timeOfDay="Day",weather="Clear",fogEnabled=false,fogStart=0,fogEnd=1000,brightness=1,seaLevel=0,timeCycleSpeed=1,ambientColor=Color3.fromRGB(255,255,255),outdoorAmbient=Color3.fromRGB(127,127,127),colorCorrection=1,bloom=0},
    Settings={saveOnChange=true,autoUpdate=true,notifyOnLoad=true,defaultProfile="Default",antiAFK=true,autoSave=true,saveInterval=30,backupCount=5},
    Keybind={toggleFarm=Enum.KeyCode.F1,toggleFly=Enum.KeyCode.F2,toggleESP=Enum.KeyCode.F3,toggleGod=Enum.KeyCode.F4,teleportHome=Enum.KeyCode.F5,toggleCombat=Enum.KeyCode.F6,toggleNoclip=Enum.KeyCode.F7,toggleSpeedHack=Enum.KeyCode.F8},
    Fishing={enabled=false,autoCast=true,autoReel=true,fishType="All"},
    Raid={enabled=false,autoStart=true,autoComplete=true,raidDifficulty="Normal"},
    SeaEvent={enabled=false,autoFind=true,autoFight=true,eventType="All"},
    Stats={enabled=false,autoAssign=true,statPriority="Melee",stats={Melee=0,Defense=0,Sword=0,Gun=0,Fruit=0}},
    Misc={autoSpin=false,dailyReward=false,giftCollect=false,autoBuy=false}
}
local function serializeValue(value)
    local t=type(value)
    if t=="number" or t=="string" or t=="boolean" then return tostring(value) end
    if t=="table" then
        if value.X and value.Y and value.Z and getmetatable(value)==Vector3 then
            return "Vector3("..value.X..","..value.Y..","..value.Z..")"
        end
        if value.R and value.G and value.B and getmetatable(value)==Color3 then
            return "Color3("..value.R..","..value.G..","..value.B..")"
        end
        if value.Name and value.Value and getmetatable(value)==EnumItem then
            return "Enum."..value.Name
        end
        return httpService:JSONEncode(value)
    end
    return tostring(value)
end
local function deserializeValue(str)
    if str:match("^Vector3%(") then
        local nums={}
        for num in str:gmatch("[%d%.]+") do table.insert(nums,tonumber(num)) end
        if #nums==3 then return Vector3.new(nums[1],nums[2],nums[3]) end
    end
    if str:match("^Color3%(") then
        local nums={}
        for num in str:gmatch("[%d%.]+") do table.insert(nums,tonumber(num)) end
        if #nums==3 then return Color3.new(nums[1],nums[2],nums[3]) end
    end
    if str:match("^Enum%.") then
        local enumName=str:gsub("Enum%.","")
        return Enum.KeyCode[enumName] or Enum.HumanoidStateType[enumName]
    end
    if str=="true" then return true end
    if str=="false" then return false end
    if tonumber(str) then return tonumber(str) end
    return str
end
local function getSettingsPath()
    return "ShinnyX_Settings_"..player.UserId..".json"
end
local function loadFromFile()
    local path=getSettingsPath()
    local success,result=pcall(function()return readfile(path)end)
    if success and result then
        local decoded=httpService:JSONDecode(result)
        if decoded and decoded.version==configVersion then
            return decoded.data
        end
    end
    return nil
end
local function saveToFile(data)
    local path=getSettingsPath()
    local json=httpService:JSONEncode({version=configVersion,data=data,user=player.UserId,time=os.time()})
    local success=pcall(function()writefile(path,json)end)
    if success then return true end
    return false
end
local function createBackup(data)
    local path="ShinnyX_Backup_"..player.UserId.."_"..os.time()..".json"
    local json=httpService:JSONEncode({version=configVersion,data=data,user=player.UserId,time=os.time(),backup=true})
    local success=pcall(function()writefile(path,json)end)
    if success then backupCounter=backupCounter+1 return true end
    return false
end
local function loadBackup()
    local success,files=pcall(function()return listfiles()end)
    if success and files then
        local backups={}
        for _,file in pairs(files) do
            if file:match("ShinnyX_Backup_"..player.UserId) then
                local info=pcall(function()return readfile(file)end)
                if info then
                    local decoded=httpService:JSONDecode(info)
                    if decoded then table.insert(backups,{file=file,time=decoded.time or 0}) end
                end
            end
        end
        table.sort(backups,function(a,b)return a.time>b.time end)
        if #backups>0 then
            local data=readfile(backups[1].file)
            local decoded=httpService:JSONDecode(data)
            if decoded then return decoded.data end
        end
    end
    return nil
end
local function mergeTables(t1,t2)
    for k,v in pairs(t2)do
        if type(v)=="table"and type(t1[k])=="table"then
            mergeTables(t1[k],v)
        else
            t1[k]=v
        end
    end
    return t1
end
local function deepCopy(t)
    local r={}
    for k,v in pairs(t)do
        if type(v)=="table"then
            r[k]=deepCopy(v)
        else
            r[k]=v
        end
    end
    return r
end
local function validateSettings(data)
    local default=deepCopy(defaultSettings)
    for k,v in pairs(default)do
        if data[k]==nil then data[k]=v end
    end
    return data
end
local function saveProfile(name,data)
    if not name or name=="" then return false end
    profiles[name]=deepCopy(data)
    return true
end
local function loadProfile(name)
    if not name or name=="" then return false end
    if profiles[name] then
        dataRef=deepCopy(profiles[name])
        currentProfile=name
        return true
    end
    return false
end
local function deleteProfile(name)
    if name=="Default" then return false end
    if profiles[name] then
        profiles[name]=nil
        return true
    end
    return false
end
local function listProfiles()
    local list={}
    for k,_ in pairs(profiles)do
        table.insert(list,k)
    end
    return list
end
local function exportProfile(name)
    if profiles[name] then
        return httpService:JSONEncode(profiles[name])
    end
    return nil
end
local function importProfile(name,json)
    local success,decoded=pcall(function()return httpService:JSONDecode(json)end)
    if success and decoded then
        profiles[name]=decoded
        return true
    end
    return false
end
local function getKeybindName(key)
    if type(key)=="string" then
        if key:match("F%d") then return key end
        if key:match("^Enum%.") then
            local name=key:gsub("Enum%.","")
            return name
        end
        return key
    end
    if type(key)=="number" then
        for _,v in pairs(Enum.KeyCode:GetEnumItems())do
            if v.Value==key then return v.Name end
        end
        return "Unknown"
    end
    return tostring(key)
end
local function setKeybind(keyName,key)
    if dataRef and dataRef.Keybind then
        dataRef.Keybind[keyName]=key
        return true
    end
    return false
end
local function getKeybind(keyName)
    if dataRef and dataRef.Keybind then
        return dataRef.Keybind[keyName]
    end
    return nil
end
local function resetKeybinds()
    if dataRef then
        dataRef.Keybind={
            toggleFarm=Enum.KeyCode.F1,
            toggleFly=Enum.KeyCode.F2,
            toggleESP=Enum.KeyCode.F3,
            toggleGod=Enum.KeyCode.F4,
            teleportHome=Enum.KeyCode.F5,
            toggleCombat=Enum.KeyCode.F6,
            toggleNoclip=Enum.KeyCode.F7,
            toggleSpeedHack=Enum.KeyCode.F8
        }
        return true
    end
    return false
end
local function loadSettings(data)
    if dataRef then
        dataRef=mergeTables(dataRef,data)
    else
        dataRef=deepCopy(data)
    end
    dataRef=validateSettings(dataRef)
    return true
end
local function saveSettings(data)
    if not data then data=dataRef end
    if not data then return false end
    local success=saveToFile(data)
    if success and data.Settings and data.Settings.backupCount and backupCounter%data.Settings.backupCount==0 then
        createBackup(data)
    end
    return success
end
local function autoSave()
    if dataRef and dataRef.Settings and dataRef.Settings.autoSave then
        saveSettings(dataRef)
    end
end
local function startAutoSave()
    task.spawn(function()
        while isRunning do
            wait(saveInterval)
            autoSave()
        end
    end)
end
local function resetToDefault()
    dataRef=deepCopy(defaultSettings)
    currentProfile="Default"
    return true
end
local function applySettingsToModules(modules)
    if not dataRef or not modules then return false end
    for name,mod in pairs(modules)do
        if mod and mod.Apply then
            pcall(function()mod.Apply(dataRef[name] or {})end)
        end
        if mod and mod.Run then
            pcall(function()mod.Run(dataRef[name] or {})end)
        end
    end
    return true
end
local function getSettingsSnapshot()
    return deepCopy(dataRef)
end
local function diffSettings(newData)
    local changes={}
    for k,v in pairs(newData)do
        if type(v)=="table"then
            for subk,subv in pairs(v)do
                if dataRef[k] and dataRef[k][subk]~=subv then
                    changes[k.."."..subk]=subv
                end
            end
        else
            if dataRef[k]~=v then
                changes[k]=v
            end
        end
    end
    return changes
end
local function applyDiff(changes)
    for path,value in pairs(changes)do
        local parts={}
        for part in string.gmatch(path,"[^%.]+")do
            table.insert(parts,part)
        end
        local current=dataRef
        for i=1,#parts-1 do
            if not current[parts[i]]then current[parts[i]]={}end
            current=current[parts[i]]
        end
        current[parts[#parts]]=value
    end
    return true
end
local function getDefaultSettings()
    return deepCopy(defaultSettings)
end
local function compareToDefault()
    local diff={}
    for k,v in pairs(dataRef)do
        if type(v)=="table"then
            for subk,subv in pairs(v)do
                if defaultSettings[k] and defaultSettings[k][subk]~=subv then
                    diff[k.."."..subk]=subv
                end
            end
        else
            if defaultSettings[k]~=v then
                diff[k]=v
            end
        end
    end
    return diff
end
local function getProfile(name)
    return profiles[name] or nil
end
local function renameProfile(oldName,newName)
    if not profiles[oldName] or profiles[newName] then return false end
    profiles[newName]=profiles[oldName]
    profiles[oldName]=nil
    if currentProfile==oldName then currentProfile=newName end
    return true
end
local function duplicateProfile(name,newName)
    if not profiles[name] or profiles[newName] then return false end
    profiles[newName]=deepCopy(profiles[name])
    return true
end
local function syncProfiles()
    local data=loadFromFile()
    if data and data.profiles then
        for k,v in pairs(data.profiles)do
            profiles[k]=v
        end
        if data.currentProfile then currentProfile=data.currentProfile end
    end
    return true
end
local function saveProfiles()
    local data={profiles=profiles,currentProfile=currentProfile,version=configVersion}
    return saveToFile(data)
end
local function getConfigVersion()
    return configVersion
end
local function setConfigVersion(version)
    configVersion=version
    return true
end
local function isDefaultProfile()
    return currentProfile=="Default"
end
local function getCurrentProfile()
    return currentProfile
end
local function setCurrentProfile(name)
    if profiles[name] then
        currentProfile=name
        return true
    end
    return false
end
local function exportAllSettings()
    return httpService:JSONEncode({version=configVersion,data=dataRef,profiles=profiles,currentProfile=currentProfile,user=player.UserId,time=os.time()})
end
local function importAllSettings(json)
    local success,decoded=pcall(function()return httpService:JSONDecode(json)end)
    if success and decoded then
        if decoded.version==configVersion then
            if decoded.data then dataRef=decoded.data end
            if decoded.profiles then profiles=decoded.profiles end
            if decoded.currentProfile then currentProfile=decoded.currentProfile end
            return true
        end
    end
    return false
end
local function getLastSaveTime()
    local path=getSettingsPath()
    local success,info=pcall(function()return getfileinfo(path)end)
    if success and info then
        return info.Modified
    end
    return 0
end
local function isSettingsFileExists()
    local path=getSettingsPath()
    return pcall(function()return isfile(path)end)
end
local function deleteSettingsFile()
    local path=getSettingsPath()
    return pcall(function()delfile(path)end)
end
local function clearAllBackups()
    local success,files=pcall(function()return listfiles()end)
    if success and files then
        for _,file in pairs(files)do
            if file:match("ShinnyX_Backup_"..player.UserId) then
                pcall(function()delfile(file)end)
            end
        end
        backupCounter=0
        return true
    end
    return false
end
local function getBackupCount()
    local count=0
    local success,files=pcall(function()return listfiles()end)
    if success and files then
        for _,file in pairs(files)do
            if file:match("ShinnyX_Backup_"..player.UserId) then
                count=count+1
            end
        end
    end
    return count
end
local function startSettingsLoop()
    if isRunning then return end
    isRunning=true
    syncProfiles()
    local loaded=loadFromFile()
    if loaded then
        dataRef=loaded
    else
        resetToDefault()
    end
    if dataRef then
        dataRef=validateSettings(dataRef)
    end
    saveProfiles()
    startAutoSave()
    runService.Heartbeat:Connect(function(delta)
        if isRunning and dataRef and dataRef.Settings and dataRef.Settings.autoSave then
            autoSaveTimer=autoSaveTimer+delta
            if autoSaveTimer>=saveInterval then
                autoSaveTimer=0
                saveSettings(dataRef)
            end
        end
    end)
    return true
end
function settings.Stop()
    isRunning=false
    saveSettings(dataRef)
    saveProfiles()
    return true
end
function settings.Initialize(data)
    dataRef=data
    startSettingsLoop()
    return true
end
function settings.Load(data)
    if data then
        dataRef=deepCopy(data)
        dataRef=validateSettings(dataRef)
        return true
    end
    local loaded=loadFromFile()
    if loaded then
        dataRef=loaded
        dataRef=validateSettings(dataRef)
        return true
    end
    if dataRef then
        dataRef=validateSettings(dataRef)
        return true
    end
    return false
end
function settings.Save(data)
    if data then
        return saveSettings(data)
    end
    if dataRef then
        return saveSettings(dataRef)
    end
    return false
end
function settings.GetData()
    return dataRef
end
function settings.SetData(data)
    dataRef=deepCopy(data)
    dataRef=validateSettings(dataRef)
    return true
end
function settings.Reset()
    resetToDefault()
    saveSettings(dataRef)
    return true
end
function settings.CreateProfile(name)
    if not name or name=="" then return false end
    if profiles[name] then return false end
    profiles[name]=deepCopy(dataRef)
    return true
end
function settings.LoadProfile(name)
    return loadProfile(name)
end
function settings.DeleteProfile(name)
    return deleteProfile(name)
end
function settings.ListProfiles()
    return listProfiles()
end
function settings.ExportProfile(name)
    return exportProfile(name)
end
function settings.ImportProfile(name,json)
    return importProfile(name,json)
end
function settings.RenameProfile(oldName,newName)
    return renameProfile(oldName,newName)
end
function settings.DuplicateProfile(name,newName)
    return duplicateProfile(name,newName)
end
function settings.GetCurrentProfile()
    return getCurrentProfile()
end
function settings.SetCurrentProfile(name)
    return setCurrentProfile(name)
end
function settings.IsDefaultProfile()
    return isDefaultProfile()
end
function settings.GetKeybind(keyName)
    return getKeybind(keyName)
end
function settings.SetKeybind(keyName,key)
    return setKeybind(keyName,key)
end
function settings.ResetKeybinds()
    return resetKeybinds()
end
function settings.GetKeybindName(key)
    return getKeybindName(key)
end
function settings.ApplyToModules(modules)
    return applySettingsToModules(modules)
end
function settings.GetSnapshot()
    return getSettingsSnapshot()
end
function settings.Diff(newData)
    return diffSettings(newData)
end
function settings.ApplyDiff(changes)
    return applyDiff(changes)
end
function settings.GetDefault()
    return getDefaultSettings()
end
function settings.CompareToDefault()
    return compareToDefault()
end
function settings.ExportAll()
    return exportAllSettings()
end
function settings.ImportAll(json)
    return importAllSettings(json)
end
function settings.GetLastSaveTime()
    return getLastSaveTime()
end
function settings.IsFileExists()
    return isSettingsFileExists()
end
function settings.DeleteFile()
    return deleteSettingsFile()
end
function settings.ClearBackups()
    return clearAllBackups()
end
function settings.GetBackupCount()
    return getBackupCount()
end
function settings.GetVersion()
    return getConfigVersion()
end
function settings.SetVersion(version)
    return setConfigVersion(version)
end
function settings.SetSaveInterval(interval)
    saveInterval=interval
    if dataRef and dataRef.Settings then
        dataRef.Settings.saveInterval=interval
    end
    return true
end
function settings.ToggleAutoSave()
    if dataRef and dataRef.Settings then
        dataRef.Settings.autoSave=not dataRef.Settings.autoSave
        return dataRef.Settings.autoSave
    end
    return false
end
function settings.ToggleSaveOnChange()
    if dataRef and dataRef.Settings then
        dataRef.Settings.saveOnChange=not dataRef.Settings.saveOnChange
        return dataRef.Settings.saveOnChange
    end
    return false
end
function settings.Pause()
    isRunning=false
    return true
end
function settings.Resume()
    if dataRef then
        isRunning=true
        startAutoSave()
        return true
    end
    return false
end
function settings.Destroy()
    isRunning=false
    saveSettings(dataRef)
    saveProfiles()
    dataRef=nil
    return true
end
return settings
