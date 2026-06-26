local logger={}
logger.__index=logger
local player=game.Players.LocalPlayer
local runService=game:GetService("RunService")
local workspace=game:GetService("Workspace")
local players=game:GetService("Players")
local httpService=game:GetService("HttpService")
local dataRef=nil
local isRunning=false
local logFile=nil
local logLevels={DEBUG=0,INFO=1,WARN=2,ERROR=3,FATAL=4}
local currentLevel=logLevels.INFO
local logEntries={}
local maxLogEntries=1000
local logToConsole=true
local logToFile=false
local filePath="ShinnyX_Log.txt"
local maxFileSize=1024*1024 -- 1MB
local asyncWrite=false
local writeQueue={}
local isWriting=false
local includeTimestamp=true
local includeLevel=true
local includeTag=true
local colorOutput=true
local timestampFormat="%Y-%m-%d %H:%M:%S"
local tags={}
local tagLevels={}
local filters={}
local logCounts={DEBUG=0,INFO=0,WARN=0,ERROR=0,FATAL=0}
local function getTimestamp()
    return os.date(timestampFormat)
end
local function getLevelName(level)
    for name,lvl in pairs(logLevels) do
        if lvl==level then return name end
    end
    return "UNKNOWN"
end
local function getLevelColor(level)
    if level==logLevels.DEBUG then return "\27[36m" end
    if level==logLevels.INFO then return "\27[32m" end
    if level==logLevels.WARN then return "\27[33m" end
    if level==logLevels.ERROR then return "\27[31m" end
    if level==logLevels.FATAL then return "\27[35m" end
    return "\27[0m"
end
local function resetColor()
    return "\27[0m"
end
local function formatMessage(level,message,tag)
    local parts={}
    if includeTimestamp then
        table.insert(parts,"["..getTimestamp().."]")
    end
    if includeLevel then
        table.insert(parts,"["..getLevelName(level).."]")
    end
    if includeTag and tag then
        table.insert(parts,"["..tag.."]")
    end
    table.insert(parts,message)
    return table.concat(parts," ")
end
local function shouldLog(level,tag)
    if level<currentLevel then return false end
    if tag and tagLevels[tag] and level<tagLevels[tag] then return false end
    if #filters>0 then
        for _,filter in ipairs(filters) do
            if filter.tag and filter.tag~=tag then
                if filter.allow==false then return false end
            end
            if filter.level and level~=filter.level then
                if filter.allow==false then return false end
            end
            if filter.message and not string.find(message,filter.message) then
                if filter.allow==false then return false end
            end
        end
    end
    return true
end
local function writeToFile(content)
    if not logToFile then return end
    local success,err=pcall(function()
        local existing=""
        if isfile(filePath) then
            existing=readfile(filePath)
        end
        if #existing+ #content>maxFileSize then
            local lines=string.split(existing,"\n")
            local newLines={}
            local totalSize=0
            for i=#lines,1,-1 do
                totalSize=totalSize+#lines[i]+1
                if totalSize>maxFileSize/2 then break end
                table.insert(newLines,1,lines[i])
            end
            existing=table.concat(newLines,"\n")
        end
        writefile(filePath,existing..content)
    end)
    if not success then
        warn("[Logger] Failed to write to file: "..tostring(err))
    end
end
local function processWriteQueue()
    if isWriting or #writeQueue==0 then return end
    isWriting=true
    task.spawn(function()
        while #writeQueue>0 do
            local entry=table.remove(writeQueue,1)
            if entry then
                writeToFile(entry)
            end
            if #writeQueue>0 then task.wait(0.05) end
        end
        isWriting=false
    end)
end
local function addLogEntry(level,message,tag)
    if not shouldLog(level,tag) then return end
    local formatted=formatMessage(level,message,tag)
    if logToConsole then
        if colorOutput then
            local color=getLevelColor(level)
            print(color..formatted..resetColor())
        else
            print(formatted)
        end
    end
    table.insert(logEntries,{level=level,message=message,tag=tag,timestamp=os.time(),formatted=formatted})
    if #logEntries>maxLogEntries then
        table.remove(logEntries,1)
    end
    logCounts[getLevelName(level)]=(logCounts[getLevelName(level)] or 0)+1
    if logToFile then
        if asyncWrite then
            table.insert(writeQueue,formatted.."\n")
            processWriteQueue()
        else
            writeToFile(formatted.."\n")
        end
    end
end
function logger.SetLevel(level)
    if type(level)=="string" then
        local lvl=logLevels[level:upper()]
        if lvl then currentLevel=lvl end
    elseif type(level)=="number" then
        currentLevel=level
    end
    return currentLevel
end
function logger.GetLevel()
    return currentLevel
end
function logger.SetTagLevel(tag,level)
    if type(level)=="string" then
        local lvl=logLevels[level:upper()]
        if lvl then tagLevels[tag]=lvl end
    elseif type(level)=="number" then
        tagLevels[tag]=level
    end
end
function logger.RemoveTagLevel(tag)
    tagLevels[tag]=nil
end
function logger.SetConsoleOutput(enabled)
    logToConsole=enabled
end
function logger.SetFileOutput(enabled,path)
    logToFile=enabled
    if path then filePath=path end
end
function logger.SetMaxFileSize(size)
    maxFileSize=size
end
function logger.SetAsyncWrite(enabled)
    asyncWrite=enabled
end
function logger.SetMaxEntries(max)
    maxLogEntries=max
end
function logger.SetTimestampFormat(format)
    timestampFormat=format
end
function logger.SetIncludeTimestamp(include)
    includeTimestamp=include
end
function logger.SetIncludeLevel(include)
    includeLevel=include
end
function logger.SetIncludeTag(include)
    includeTag=include
end
function logger.SetColorOutput(enabled)
    colorOutput=enabled
end
function logger.AddFilter(filter)
    table.insert(filters,filter)
end
function logger.RemoveFilter(index)
    if index then
        table.remove(filters,index)
    else
        filters={}
    end
end
function logger.ClearFilters()
    filters={}
end
function logger.GetFilters()
    return filters
end
function logger.Debug(message,tag)
    addLogEntry(logLevels.DEBUG,message,tag)
end
function logger.Info(message,tag)
    addLogEntry(logLevels.INFO,message,tag)
end
function logger.Warn(message,tag)
    addLogEntry(logLevels.WARN,message,tag)
end
function logger.Error(message,tag)
    addLogEntry(logLevels.ERROR,message,tag)
end
function logger.Fatal(message,tag)
    addLogEntry(logLevels.FATAL,message,tag)
end
function logger.Log(level,message,tag)
    if type(level)=="string" then
        local lvl=logLevels[level:upper()]
        if lvl then addLogEntry(lvl,message,tag) end
    else
        addLogEntry(level,message,tag)
    end
end
function logger.GetEntries(level,tag)
    local result={}
    for _,entry in ipairs(logEntries) do
        if (not level or entry.level==level) and (not tag or entry.tag==tag) then
            table.insert(result,entry)
        end
    end
    return result
end
function logger.GetRecentEntries(count)
    count=count or 10
    local result={}
    local start=math.max(1,#logEntries-count+1)
    for i=start,#logEntries do
        table.insert(result,logEntries[i])
    end
    return result
end
function logger.Clear()
    logEntries={}
    logCounts={DEBUG=0,INFO=0,WARN=0,ERROR=0,FATAL=0}
    if logToFile and isfile(filePath) then
        pcall(function()writefile(filePath,"")end)
    end
end
function logger.GetCounts()
    return logCounts
end
function logger.GetTotalCount()
    local total=0
    for _,c in pairs(logCounts) do total=total+c end
    return total
end
function logger.GetFileContent()
    if logToFile and isfile(filePath) then
        return readfile(filePath)
    end
    return nil
end
function logger.ClearFile()
    if logToFile and isfile(filePath) then
        pcall(function()writefile(filePath,"")end)
    end
end
function logger.GetFilePath()
    return filePath
end
function logger.SetFilePath(path)
    filePath=path
end
function logger.ExportToJSON()
    local data={
        entries=logEntries,
        counts=logCounts,
        timestamp=os.time(),
        version="4.0.0"
    }
    return httpService:JSONEncode(data)
end
function logger.ImportFromJSON(json)
    local success,data=pcall(function()return httpService:JSONDecode(json)end)
    if success and data then
        if data.entries then
            logEntries=data.entries
        end
        if data.counts then
            logCounts=data.counts
        end
        return true
    end
    return false
end
function logger.ExportToFile(path)
    if not path then path=filePath..".bak" end
    local content=""
    for _,entry in ipairs(logEntries) do
        content=content..entry.formatted.."\n"
    end
    local success,err=pcall(function()writefile(path,content)end)
    if success then return true else return false,err end
end
function logger.ImportFromFile(path)
    if not path then path=filePath..".bak" end
    if not isfile(path) then return false end
    local content=readfile(path)
    local lines=string.split(content,"\n")
    for _,line in ipairs(lines) do
        if line~="" then
            table.insert(logEntries,{formatted=line,level=logLevels.INFO,timestamp=os.time()})
        end
    end
    return true
end
function logger.SetTag(tagName,enabled)
    if enabled then
        tags[tagName]=true
    else
        tags[tagName]=nil
    end
end
function logger.IsTagEnabled(tag)
    return tags[tag]~=nil
end
function logger.GetTags()
    local result={}
    for k,_ in pairs(tags) do
        table.insert(result,k)
    end
    return result
end
function logger.GetTagLevel(tag)
    return tagLevels[tag]
end
function logger.GetAllLevels()
    local result={}
    for name,lvl in pairs(logLevels) do
        table.insert(result,{name=name,level=lvl})
    end
    return result
end
function logger.SetLevelNameMapping(name,level)
    logLevels[name]=level
end
function logger.RemoveLevelNameMapping(name)
    logLevels[name]=nil
end
function logger.GetLevelByName(name)
    return logLevels[name:upper()]
end
function logger.GetNameByLevel(level)
    for name,lvl in pairs(logLevels) do
        if lvl==level then return name end
    end
    return nil
end
function logger.StartAutoFlush(interval)
    interval=interval or 5
    task.spawn(function()
        while true do
            task.wait(interval)
            if #writeQueue>0 then
                processWriteQueue()
            end
        end
    end)
end
function logger.Flush()
    processWriteQueue()
    while isWriting do task.wait(0.01) end
end
function logger.Stop()
    isRunning=false
    logger.Flush()
end
function logger.Initialize(data)
    dataRef=data
    if data and data.logger then
        local cfg=data.logger
        if cfg.level then logger.SetLevel(cfg.level) end
        if cfg.consoleOutput~=nil then logger.SetConsoleOutput(cfg.consoleOutput) end
        if cfg.fileOutput~=nil then logger.SetFileOutput(cfg.fileOutput,cfg.filePath) end
        if cfg.maxFileSize then logger.SetMaxFileSize(cfg.maxFileSize) end
        if cfg.asyncWrite~=nil then logger.SetAsyncWrite(cfg.asyncWrite) end
        if cfg.maxEntries then logger.SetMaxEntries(cfg.maxEntries) end
        if cfg.timestampFormat then logger.SetTimestampFormat(cfg.timestampFormat) end
        if cfg.includeTimestamp~=nil then logger.SetIncludeTimestamp(cfg.includeTimestamp) end
        if cfg.includeLevel~=nil then logger.SetIncludeLevel(cfg.includeLevel) end
        if cfg.includeTag~=nil then logger.SetIncludeTag(cfg.includeTag) end
        if cfg.colorOutput~=nil then logger.SetColorOutput(cfg.colorOutput) end
        if cfg.tagLevels then
            for tag,lvl in pairs(cfg.tagLevels) do
                logger.SetTagLevel(tag,lvl)
            end
        end
        if cfg.tags then
            for tag,enabled in pairs(cfg.tags) do
                logger.SetTag(tag,enabled)
            end
        end
        if cfg.filters then
            for _,filter in ipairs(cfg.filters) do
                logger.AddFilter(filter)
            end
        end
    end
    isRunning=true
    logger.Info("Logger initialized","System")
    return true
end
function logger.SetLevelFromString(levelStr)
    local lvl=logLevels[levelStr:upper()]
    if lvl then currentLevel=lvl end
    return currentLevel
end
function logger.LogObject(obj,tag)
    if type(obj)=="table" then
        local json=httpService:JSONEncode(obj)
        logger.Info("Object: "..json,tag)
    else
        logger.Info(tostring(obj),tag)
    end
end
function logger.LogError(err,tag)
    if type(err)=="string" then
        logger.Error(err,tag)
    elseif type(err)=="table" and err.message then
        logger.Error(err.message,tag)
        if err.stack then
            logger.Debug(err.stack,tag)
        end
    else
        logger.Error(tostring(err),tag)
    end
end
function logger.LogStackTrace(tag)
    local stack=debug.traceback()
    logger.Debug("Stack trace:\n"..stack,tag)
end
function logger.LogMemoryUsage(tag)
    local mem=game:GetService("MemoryService"):GetMemoryUsage() or 0
    logger.Info("Memory usage: "..tostring(mem).." MB",tag)
end
function logger.LogPerformance(tag)
    local start=tick()
    task.wait(0.001)
    local elapsed=(tick()-start)*1000
    logger.Info("Performance: "..string.format("%.2fms",elapsed),tag)
end
function logger.LogSystemInfo(tag)
    local info={
        player=player.Name,
        userId=player.UserId,
        gameId=game.GameId,
        placeId=game.PlaceId,
        jobId=game.JobId,
        time=os.date(),
        ping=math.floor(player:GetPing()*1000),
        fps=60 -- approximate
    }
    logger.LogObject(info,tag)
end
function logger.LogNetworkStats(tag)
    local stats=game:GetService("NetworkClient"):GetStats()
    logger.Info("Network: "..tostring(stats),tag)
end
function logger.LogScripts(tag)
    local scripts={}
    for _,v in pairs(game:GetDescendants()) do
        if v:IsA("Script") or v:IsA("LocalScript") then
            table.insert(scripts,v.Name)
        end
    end
    logger.Info("Scripts count: "..#scripts,tag)
end
function logger.CreateEntry(level,message,tag,timestamp)
    return {
        level=level,
        message=message,
        tag=tag,
        timestamp=timestamp or os.time(),
        formatted=formatMessage(level,message,tag)
    }
end
function logger.AppendEntry(entry)
    if entry then
        table.insert(logEntries,entry)
        if #logEntries>maxLogEntries then
            table.remove(logEntries,1)
        end
        if logToFile then
            local content=entry.formatted.."\n"
            if asyncWrite then
                table.insert(writeQueue,content)
                processWriteQueue()
            else
                writeToFile(content)
            end
        end
        logCounts[getLevelName(entry.level)]=(logCounts[getLevelName(entry.level)] or 0)+1
    end
end
function logger.SearchEntries(pattern,caseSensitive)
    caseSensitive=caseSensitive or false
    local result={}
    local search=caseSensitive and pattern or pattern:lower()
    for _,entry in ipairs(logEntries) do
        local msg=caseSensitive and entry.message or entry.message:lower()
        if string.find(msg,search) then
            table.insert(result,entry)
        end
    end
    return result
end
function logger.SearchByTag(tag)
    local result={}
    for _,entry in ipairs(logEntries) do
        if entry.tag==tag then
            table.insert(result,entry)
        end
    end
    return result
end
function logger.SearchByLevel(level)
    local result={}
    for _,entry in ipairs(logEntries) do
        if entry.level==level then
            table.insert(result,entry)
        end
    end
    return result
end
function logger.GetEntry(index)
    return logEntries[index]
end
function logger.GetEntryCount()
    return #logEntries
end
function logger.RemoveEntry(index)
    if index and index>=1 and index<=#logEntries then
        table.remove(logEntries,index)
        return true
    end
    return false
end
function logger.ClearEntries(level,tag)
    local removed=0
    for i=#logEntries,1,-1 do
        local entry=logEntries[i]
        if (not level or entry.level==level) and (not tag or entry.tag==tag) then
            table.remove(logEntries,i)
            removed=removed+1
        end
    end
    return removed
end
function logger.GetLevelCount(levelName)
    return logCounts[levelName] or 0
end
function logger.ResetCounts()
    logCounts={DEBUG=0,INFO=0,WARN=0,ERROR=0,FATAL=0}
end
function logger.LogIf(condition,level,message,tag)
    if condition then
        logger.Log(level,message,tag)
        return true
    end
    return false
end
function logger.LogUnless(condition,level,message,tag)
    if not condition then
        logger.Log(level,message,tag)
        return true
    end
    return false
end
function logger.LogEveryN(n,level,message,tag)
    local counter=0
    return function()
        counter=counter+1
        if counter%n==0 then
            logger.Log(level,message,tag)
        end
    end
end
function logger.LogOnce(level,message,tag)
    local key=level..message..tostring(tag)
    if not logger._loggedOnce then logger._loggedOnce={} end
    if not logger._loggedOnce[key] then
        logger.Log(level,message,tag)
        logger._loggedOnce[key]=true
        return true
    end
    return false
end
function logger.ResetOnceLogs()
    logger._loggedOnce={}
end
function logger.SetDefaultTag(tag)
    logger.defaultTag=tag
end
function logger.GetDefaultTag()
    return logger.defaultTag
end
function logger.DebugDefault(message)
    logger.Debug(message,logger.defaultTag)
end
function logger.InfoDefault(message)
    logger.Info(message,logger.defaultTag)
end
function logger.WarnDefault(message)
    logger.Warn(message,logger.defaultTag)
end
function logger.ErrorDefault(message)
    logger.Error(message,logger.defaultTag)
end
function logger.FatalDefault(message)
    logger.Fatal(message,logger.defaultTag)
end
function logger.Profile(name,duration)
    duration=duration or 1
    logger.Info("Starting profile: "..name,"Profile")
    local start=tick()
    task.wait(duration)
    local elapsed=(tick()-start)*1000
    logger.Info("Profile "..name.." took "..string.format("%.2fms",elapsed),"Profile")
end
function logger.Measure(func,name)
    local start=tick()
    local result={pcall(func)}
    local elapsed=(tick()-start)*1000
    local tag=name or "Measure"
    if result[1] then
        logger.Info("Measure "..tag.." took "..string.format("%.2fms",elapsed),tag)
    else
        logger.Error("Measure "..tag.." failed: "..tostring(result[2]),tag)
    end
    return unpack(result)
end
function logger.Stacktrace(level,message,tag)
    level=level or "DEBUG"
    logger.Log(level,message.."\n"..debug.traceback(),tag)
end
function logger.Pause()
    isRunning=false
end
function logger.Resume()
    isRunning=true
end
function logger.Destroy()
    isRunning=false
    logger.Flush()
    logEntries={}
    logCounts={DEBUG=0,INFO=0,WARN=0,ERROR=0,FATAL=0}
    filters={}
    tagLevels={}
    tags={}
    writeQueue={}
    isWriting=false
    return true
end
return logger
