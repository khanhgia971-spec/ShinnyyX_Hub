local update={}
update.__index=update
local player=game.Players.LocalPlayer
local runService=game:GetService("RunService")
local httpService=game:GetService("HttpService")
local workspace=game:GetService("Workspace")
local players=game:GetService("Players")
local coreGui=game:GetService("CoreGui")
local debris=game:GetService("Debris")
local dataRef=nil
local isRunning=false
local currentVersion="4.0.0"
local repoUrl="https://raw.githubusercontent.com/khanhgia971-spec/ShinnyyX_Hub/main/"
local updateCheckInterval=3600
local autoUpdateEnabled=true
local lastCheckTime=0
local updateAvailable=false
local latestVersion=""
local updateFiles={}
local downloadQueue={}
local downloading=false
local downloadedFiles={}
local updateHistory={}
local maxHistory=20
local backupFolder="ShinnyX_Backup"
local function getVersionNumber(version)
    local parts={}
    for part in string.gmatch(version,"[%d]+") do
        table.insert(parts,tonumber(part))
    end
    local num=0
    for i=1,math.min(#parts,3) do
        num=num*1000+(parts[i] or 0)
    end
    return num
end
local function compareVersions(v1,v2)
    return getVersionNumber(v1)>getVersionNumber(v2)
end
local function getCurrentVersion()
    return currentVersion
end
local function setCurrentVersion(version)
    currentVersion=version
    return true
end
local function getVersionFile()
    local url=repoUrl.."version.txt"
    local success,result=pcall(function()
        return game:HttpGet(url)
    end)
    if success and result then
        local lines=string.split(result,"\n")
        if #lines>0 then
            return string.trim(lines[1])
        end
    end
    return nil
end
local function getFileList()
    local url=repoUrl.."files.json"
    local success,result=pcall(function()
        return game:HttpGet(url)
    end)
    if success and result then
        local data=httpService:JSONDecode(result)
        if data and data.files then
            return data.files
        end
    end
    return nil
end
local function downloadFile(filename)
    local url=repoUrl..filename
    local success,result=pcall(function()
        return game:HttpGet(url)
    end)
    if success and result then
        return result
    end
    return nil
end
local function downloadAllFiles(files)
    downloadQueue={}
    for _,f in ipairs(files) do
        table.insert(downloadQueue,f)
    end
    downloading=true
    downloadedFiles={}
    task.spawn(function()
        while #downloadQueue>0 do
            local file=table.remove(downloadQueue,1)
            local content=downloadFile(file)
            if content then
                downloadedFiles[file]=content
                table.insert(updateHistory,{file=file,time=os.time(),status="success"})
            else
                table.insert(updateHistory,{file=file,time=os.time(),status="failed"})
            end
            if #updateHistory>maxHistory then table.remove(updateHistory,1) end
            task.wait(0.1)
        end
        downloading=false
    end)
    return true
end
local function applyUpdate()
    if not updateAvailable then return false end
    local loaded=0
    for file,content in pairs(downloadedFiles) do
        if file:match("%.lua$") then
            local success,func=pcall(function()
                return loadstring(content)
            end)
            if success and func then
                local result=func()
                if result then
                    loaded=loaded+1
                end
            end
        end
    end
    if loaded>0 then
        currentVersion=latestVersion
        updateAvailable=false
        return true
    end
    return false
end
local function createBackup()
    local folder=coreGui:FindFirstChild(backupFolder)
    if not folder then
        folder=Instance.new("Folder")
        folder.Name=backupFolder
        folder.Parent=coreGui
    end
    local backup=Instance.new("StringValue")
    backup.Name="backup_"..os.time()
    backup.Value=httpService:JSONEncode({
        version=currentVersion,
        time=os.time(),
        player=player.Name
    })
    backup.Parent=folder
    debris:AddItem(backup,86400)
    return true
end
local function restoreBackup()
    local folder=coreGui:FindFirstChild(backupFolder)
    if folder then
        local backups={}
        for _,v in pairs(folder:GetChildren()) do
            if v:IsA("StringValue") and v.Name:match("backup") then
                local data=httpService:JSONDecode(v.Value)
                if data then
                    table.insert(backups,{obj=v,time=data.time or 0})
                end
            end
        end
        table.sort(backups,function(a,b)return a.time>b.time end)
        if #backups>0 then
            local last=backups[1]
            local data=httpService:JSONDecode(last.obj.Value)
            if data then
                setCurrentVersion(data.version or "0.0.0")
                return true
            end
        end
    end
    return false
end
local function clearBackups()
    local folder=coreGui:FindFirstChild(backupFolder)
    if folder then
        for _,v in pairs(folder:GetChildren()) do
            v:Destroy()
        end
        return true
    end
    return false
end
local function checkForUpdates()
    local version=getVersionFile()
    if version then
        latestVersion=version
        if compareVersions(version,currentVersion) then
            updateAvailable=true
            local files=getFileList()
            if files then
                updateFiles=files
                return true
            end
        else
            updateAvailable=false
        end
    end
    return false
end
local function performUpdate()
    if not updateAvailable then return false end
    if #updateFiles==0 then
        local files=getFileList()
        if not files then return false end
        updateFiles=files
    end
    createBackup()
    downloadAllFiles(updateFiles)
    task.wait(#updateFiles*0.1+1)
    return applyUpdate()
end
local function autoUpdateLoop()
    task.spawn(function()
        while isRunning do
            task.wait(updateCheckInterval)
            if autoUpdateEnabled then
                pcall(function()
                    if checkForUpdates() then
                        performUpdate()
                    end
                end)
            end
        end
    end)
end
local function createUpdateNotification(title,message)
    local gui=Instance.new("ScreenGui")
    gui.Name="UpdateNotification"
    gui.Parent=coreGui
    local frame=Instance.new("Frame")
    frame.Size=UDim2.new(0,400,0,150)
    frame.Position=UDim2.new(0.5,-200,0.5,-75)
    frame.BackgroundColor3=Color3.fromRGB(10,10,20)
    frame.BackgroundTransparency=0.3
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
    local btn=Instance.new("TextButton")
    btn.Size=UDim2.new(0,100,0,30)
    btn.Position=UDim2.new(0.5,-50,0,110)
    btn.BackgroundColor3=Color3.fromRGB(40,40,80)
    btn.Text="Update"
    btn.TextColor3=Color3.fromRGB(255,255,255)
    btn.Parent=frame
    btn.MouseButton1Click:Connect(function()
        gui:Destroy()
        performUpdate()
    end)
    local cancel=Instance.new("TextButton")
    cancel.Size=UDim2.new(0,60,0,30)
    cancel.Position=UDim2.new(0.5+60,0,0,110)
    cancel.BackgroundColor3=Color3.fromRGB(80,40,40)
    cancel.Text="Later"
    cancel.TextColor3=Color3.fromRGB(255,255,255)
    cancel.Parent=frame
    cancel.MouseButton1Click:Connect(function()
        gui:Destroy()
    end)
    return gui
end
local function showUpdateAvailable()
    if updateAvailable then
        createUpdateNotification("Update Available!","Version "..latestVersion.." is ready.\nClick Update to install now.")
        return true
    end
    return false
end
local function getUpdateStatus()
    return{
        currentVersion=currentVersion,
        latestVersion=latestVersion,
        updateAvailable=updateAvailable,
        autoUpdateEnabled=autoUpdateEnabled,
        isRunning=isRunning,
        downloading=downloading,
        downloadQueueSize=#downloadQueue,
        downloadedFilesCount=#downloadedFiles,
        historySize=#updateHistory
    }
end
local function setRepoUrl(url)
    repoUrl=url
    return true
end
local function getRepoUrl()
    return repoUrl
end
local function setAutoUpdateEnabled(enabled)
    autoUpdateEnabled=enabled
    return true
end
local function isAutoUpdateEnabled()
    return autoUpdateEnabled
end
local function setCheckInterval(interval)
    updateCheckInterval=interval
    return true
end
local function getCheckInterval()
    return updateCheckInterval
end
local function forceCheck()
    return checkForUpdates()
end
local function forceUpdate()
    return performUpdate()
end
local function getHistory()
    return updateHistory
end
local function clearHistory()
    updateHistory={}
    return true
end
local function getFileListFromRepo()
    return getFileList()
end
local function downloadSingleFile(filename)
    return downloadFile(filename)
end
local function getCurrentVersionString()
    return currentVersion
end
local function setCurrentVersionString(version)
    currentVersion=version
    return true
end
local function isUpdateAvailable()
    return updateAvailable
end
local function getLatestVersion()
    return latestVersion
end
local function compareVersionStrings(v1,v2)
    return compareVersions(v1,v2)
end
local function getVersionNumberFromString(v)
    return getVersionNumber(v)
end
local function parseVersionString(v)
    local parts={}
    for part in string.gmatch(v,"[%d]+") do
        table.insert(parts,tonumber(part))
    end
    return parts
end
local function getVersionMajor(v)
    local parts=parseVersionString(v)
    return parts[1] or 0
end
local function getVersionMinor(v)
    local parts=parseVersionString(v)
    return parts[2] or 0
end
local function getVersionPatch(v)
    local parts=parseVersionString(v)
    return parts[3] or 0
end
local function incrementVersion(v,index,amount)
    index=index or 3
    amount=amount or 1
    local parts=parseVersionString(v)
    if #parts<index then
        for i=#parts+1,index do parts[i]=0 end
    end
    parts[index]=parts[index]+amount
    return table.concat(parts,".")
end
local function getUpdateFileList()
    return updateFiles
end
local function getDownloadedFiles()
    return downloadedFiles
end
local function getDownloadQueue()
    return downloadQueue
end
local function cancelDownload()
    downloadQueue={}
    downloading=false
    return true
end
local function resetUpdateState()
    updateAvailable=false
    latestVersion=""
    updateFiles={}
    downloadedFiles={}
    downloadQueue={}
    downloading=false
    return true
end
local function createManifest()
    return{
        version=currentVersion,
        files=updateFiles,
        timestamp=os.time(),
        player=player.Name
    }
end
local function exportManifest()
    return httpService:JSONEncode(createManifest())
end
local function importManifest(json)
    local success,data=pcall(function()return httpService:JSONDecode(json)end)
    if success and data then
        if data.version then currentVersion=data.version end
        if data.files then updateFiles=data.files end
        return true
    end
    return false
end
local function rollback()
    return restoreBackup()
end
local function cleanBackups()
    return clearBackups()
end
local function getBackupCount()
    local folder=coreGui:FindFirstChild(backupFolder)
    if folder then
        local count=0
        for _,_ in pairs(folder:GetChildren()) do
            count=count+1
        end
        return count
    end
    return 0
end
local function getLatestBackup()
    local folder=coreGui:FindFirstChild(backupFolder)
    if folder then
        local latest=nil
        local latestTime=0
        for _,v in pairs(folder:GetChildren()) do
            if v:IsA("StringValue") and v.Name:match("backup") then
                local data=httpService:JSONDecode(v.Value)
                if data and data.time and data.time>latestTime then
                    latestTime=data.time
                    latest=v
                end
            end
        end
        if latest then
            return httpService:JSONDecode(latest.Value)
        end
    end
    return nil
end
local function createUpdateCheckCallback(callback)
    return function()
        local result=checkForUpdates()
        if callback then callback(result) end
        return result
    end
end
local function createUpdateCallback(callback)
    return function()
        local result=performUpdate()
        if callback then callback(result) end
        return result
    end
end
local function start()
    if isRunning then return false end
    isRunning=true
    autoUpdateLoop()
    return true
end
local function stop()
    isRunning=false
    return true
end
local function pause()
    isRunning=false
    return true
end
local function resume()
    if not isRunning then
        isRunning=true
        autoUpdateLoop()
        return true
    end
    return false
end
local function destroy()
    isRunning=false
    resetUpdateState()
    return true
end
local function initialize(data)
    dataRef=data
    if data then
        if data.repoUrl then setRepoUrl(data.repoUrl) end
        if data.autoUpdateEnabled~=nil then setAutoUpdateEnabled(data.autoUpdateEnabled) end
        if data.checkInterval then setCheckInterval(data.checkInterval) end
        if data.version then setCurrentVersion(data.version) end
    end
    start()
    return true
end
update.Initialize=initialize
update.start=start
update.stop=stop
update.pause=pause
update.resume=resume
update.destroy=destroy
update.checkForUpdates=checkForUpdates
update.performUpdate=performUpdate
update.forceCheck=forceCheck
update.forceUpdate=forceUpdate
update.showUpdateAvailable=showUpdateAvailable
update.getUpdateStatus=getUpdateStatus
update.setRepoUrl=setRepoUrl
update.getRepoUrl=getRepoUrl
update.setAutoUpdateEnabled=setAutoUpdateEnabled
update.isAutoUpdateEnabled=isAutoUpdateEnabled
update.setCheckInterval=setCheckInterval
update.getCheckInterval=getCheckInterval
update.getHistory=getHistory
update.clearHistory=clearHistory
update.getFileListFromRepo=getFileListFromRepo
update.downloadSingleFile=downloadSingleFile
update.getCurrentVersionString=getCurrentVersionString
update.setCurrentVersionString=setCurrentVersionString
update.isUpdateAvailable=isUpdateAvailable
update.getLatestVersion=getLatestVersion
update.compareVersionStrings=compareVersionStrings
update.getVersionNumberFromString=getVersionNumberFromString
update.parseVersionString=parseVersionString
update.getVersionMajor=getVersionMajor
update.getVersionMinor=getVersionMinor
update.getVersionPatch=getVersionPatch
update.incrementVersion=incrementVersion
update.getUpdateFileList=getUpdateFileList
update.getDownloadedFiles=getDownloadedFiles
update.getDownloadQueue=getDownloadQueue
update.cancelDownload=cancelDownload
update.resetUpdateState=resetUpdateState
update.createManifest=createManifest
update.exportManifest=exportManifest
update.importManifest=importManifest
update.rollback=rollback
update.cleanBackups=cleanBackups
update.getBackupCount=getBackupCount
update.getLatestBackup=getLatestBackup
update.createUpdateCheckCallback=createUpdateCheckCallback
update.createUpdateCallback=createUpdateCallback
return update
