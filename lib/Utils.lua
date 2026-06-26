local utils={}
utils.__index=utils
local player=game.Players.LocalPlayer
local runService=game:GetService("RunService")
local workspace=game:GetService("Workspace")
local players=game:GetService("Players")
local tweenService=game:GetService("TweenService")
local debris=game:GetService("Debris")
local collectionService=game:GetService("CollectionService")
local replicatedStorage=game:GetService("ReplicatedStorage")
local lighting=game:GetService("Lighting")
local userInput=game:GetService("UserInputService")
local guiService=game:GetService("GuiService")
local coreGui=game:GetService("CoreGui")
local httpService=game:GetService("HttpService")
local stringService=game:GetService("StringService")
local dataRef=nil
local function getDistance(pos1,pos2)
    if not pos1 or not pos2 then return math.huge end
    return (pos1-pos2).Magnitude
end
local function getClosest(origin,objects,key)
    local closest=nil
    local minDist=math.huge
    for _,obj in pairs(objects) do
        local pos
        if type(obj)=="Instance" then
            pos=obj:FindFirstChild(key or "Head") and obj[key or "Head"].Position or obj.Position
        else
            pos=obj
        end
        local dist=getDistance(origin,pos)
        if dist<minDist then
            minDist=dist
            closest=obj
        end
    end
    return closest,minDist
end
local function getRandomPosition(radius,center)
    center=center or Vector3.new(0,0,0)
    radius=radius or 100
    local angle=math.random()*2*math.pi
    local r=math.random()*radius
    local x=center.X+r*math.cos(angle)
    local z=center.Z+r*math.sin(angle)
    local y=center.Y+math.random()*10
    return Vector3.new(x,y,z)
end
local function getRandomColor(seed)
    local colors={
        Color3.fromRGB(255,0,0),Color3.fromRGB(0,255,0),Color3.fromRGB(0,0,255),
        Color3.fromRGB(255,255,0),Color3.fromRGB(255,0,255),Color3.fromRGB(0,255,255),
        Color3.fromRGB(255,128,0),Color3.fromRGB(128,0,255),Color3.fromRGB(0,128,255),
        Color3.fromRGB(255,0,128),Color3.fromRGB(128,255,0),Color3.fromRGB(0,255,128)
    }
    seed=seed or math.random(1,#colors)
    return colors[seed%#colors+1]
end
local function getCharacter(model)
    if model:IsA("Model") and model:FindFirstChild("Humanoid") then
        return model
    end
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") then
            if v.Name==model.Name then return v end
        end
    end
    return nil
end
local function getHumanoid(model)
    if model and model:IsA("Model") then
        return model:FindFirstChild("Humanoid")
    end
    return nil
end
local function getHead(model)
    if model and model:IsA("Model") then
        return model:FindFirstChild("Head")
    end
    return nil
end
local function getRootPart(model)
    if model and model:IsA("Model") then
        return model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso") or model:FindFirstChild("Head")
    end
    return nil
end
local function isAlive(model)
    local hum=getHumanoid(model)
    if hum then
        return hum.Health>0
    end
    return false
end
local function isPlayer(model)
    if model:IsA("Model") and model:FindFirstChild("Humanoid") then
        for _,p in pairs(players:GetPlayers()) do
            if p.Character==model then return true end
        end
    end
    return false
end
local function isNPC(model)
    if model:IsA("Model") and model:FindFirstChild("Humanoid") and not isPlayer(model) then
        if not model:FindFirstChild("IsBoss") then
            return true
        end
    end
    return false
end
local function isBoss(model)
    if model:IsA("Model") and model:FindFirstChild("Humanoid") then
        if model:FindFirstChild("IsBoss") then return true end
        if model.Name:lower():match("boss") or model.Name:lower():match("king") then return true end
    end
    return false
end
local function isFruit(part)
    if part:IsA("Part") and part:FindFirstChild("FruitTag") then
        return true
    end
    return false
end
local function isItem(part)
    if part:IsA("Part") and part:FindFirstChild("ItemTag") then
        return true
    end
    return false
end
local function isWeapon(part)
    if part:IsA("Part") and part:FindFirstChild("WeaponTag") then
        return true
    end
    return false
end
local function getFruitName(part)
    local tag=part:FindFirstChild("FruitTag")
    if tag then
        if tag:IsA("StringValue") then return tag.Value end
        if tag:IsA("NumberValue") then return tostring(tag.Value) end
    end
    return part.Name
end
local function getItemName(part)
    local tag=part:FindFirstChild("ItemTag")
    if tag then
        if tag:IsA("StringValue") then return tag.Value end
        if tag:IsA("NumberValue") then return tostring(tag.Value) end
    end
    return part.Name
end
local function getWeaponName(part)
    local tag=part:FindFirstChild("WeaponTag")
    if tag then
        if tag:IsA("StringValue") then return tag.Value end
        if tag:IsA("NumberValue") then return tostring(tag.Value) end
    end
    return part.Name
end
local function getBeli(playerObj)
    local beli=playerObj:FindFirstChild("Beli")
    if beli and beli:IsA("NumberValue") then
        return beli.Value
    end
    return 0
end
local function getGems(playerObj)
    local gems=playerObj:FindFirstChild("Gems")
    if gems and gems:IsA("NumberValue") then
        return gems.Value
    end
    return 0
end
local function getLevel(playerObj)
    local level=playerObj:FindFirstChild("Level")
    if level and level:IsA("NumberValue") then
        return level.Value
    end
    return 0
end
local function getExp(playerObj)
    local exp=playerObj:FindFirstChild("Exp")
    if exp and exp:IsA("NumberValue") then
        return exp.Value
    end
    return 0
end
local function getMaxExp(playerObj)
    local maxExp=playerObj:FindFirstChild("MaxExp")
    if maxExp and maxExp:IsA("NumberValue") then
        return maxExp.Value
    end
    return 100
end
local function getFruit(playerObj)
    local fruit=playerObj:FindFirstChild("Fruit")
    if fruit and fruit:IsA("StringValue") then
        return fruit.Value
    end
    return "None"
end
local function getWeapon(playerObj)
    local weapon=playerObj:FindFirstChild("Weapon")
    if weapon and weapon:IsA("StringValue") then
        return weapon.Value
    end
    return "None"
end
local function getStatPoints(playerObj)
    local sp=playerObj:FindFirstChild("StatPoints")
    if sp and sp:IsA("NumberValue") then
        return sp.Value
    end
    return 0
end
local function getStat(playerObj,statName)
    local stat=playerObj:FindFirstChild(statName)
    if stat and stat:IsA("NumberValue") then
        return stat.Value
    end
    return 0
end
local function getAllStats(playerObj)
    local stats={}
    for _,v in pairs(playerObj:GetChildren()) do
        if v:IsA("NumberValue") and v.Name:match("Stat") then
            stats[v.Name]=v.Value
        end
    end
    return stats
end
local function getPlayerCount()
    return #players:GetPlayers()
end
local function getAlivePlayers()
    local alive={}
    for _,p in pairs(players:GetPlayers()) do
        if p.Character and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health>0 then
            table.insert(alive,p)
        end
    end
    return alive
end
local function getDeadPlayers()
    local dead={}
    for _,p in pairs(players:GetPlayers()) do
        if not p.Character or not p.Character:FindFirstChild("Humanoid") or p.Character.Humanoid.Health<=0 then
            table.insert(dead,p)
        end
    end
    return dead
end
local function getNearestPlayer(origin)
    local nearest=nil
    local minDist=math.huge
    for _,p in pairs(players:GetPlayers()) do
        if p~=player then
            local char=p.Character
            if char and char:FindFirstChild("Head") then
                local dist=getDistance(origin,char.Head.Position)
                if dist<minDist then
                    minDist=dist
                    nearest=p
                end
            end
        end
    end
    return nearest,minDist
end
local function getNearestNPC(origin)
    local nearest=nil
    local minDist=math.huge
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Model") and v:FindFirstChild("Head") and isNPC(v) then
            local dist=getDistance(origin,v.Head.Position)
            if dist<minDist then
                minDist=dist
                nearest=v
            end
        end
    end
    return nearest,minDist
end
local function getNearestBoss(origin)
    local nearest=nil
    local minDist=math.huge
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Model") and v:FindFirstChild("Head") and isBoss(v) then
            local dist=getDistance(origin,v.Head.Position)
            if dist<minDist then
                minDist=dist
                nearest=v
            end
        end
    end
    return nearest,minDist
end
local function getNearestFruit(origin)
    local nearest=nil
    local minDist=math.huge
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Part") and isFruit(v) then
            local dist=getDistance(origin,v.Position)
            if dist<minDist then
                minDist=dist
                nearest=v
            end
        end
    end
    return nearest,minDist
end
local function getNearestItem(origin)
    local nearest=nil
    local minDist=math.huge
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Part") and isItem(v) then
            local dist=getDistance(origin,v.Position)
            if dist<minDist then
                minDist=dist
                nearest=v
            end
        end
    end
    return nearest,minDist
end
local function getPlayersInRadius(origin,radius)
    local list={}
    for _,p in pairs(players:GetPlayers()) do
        if p~=player then
            local char=p.Character
            if char and char:FindFirstChild("Head") then
                local dist=getDistance(origin,char.Head.Position)
                if dist<radius then
                    table.insert(list,{player=p,distance=dist})
                end
            end
        end
    end
    table.sort(list,function(a,b)return a.distance<b.distance end)
    return list
end
local function getNPCsInRadius(origin,radius)
    local list={}
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Model") and v:FindFirstChild("Head") and isNPC(v) then
            local dist=getDistance(origin,v.Head.Position)
            if dist<radius then
                table.insert(list,{npc=v,distance=dist})
            end
        end
    end
    table.sort(list,function(a,b)return a.distance<b.distance end)
    return list
end
local function getBossesInRadius(origin,radius)
    local list={}
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Model") and v:FindFirstChild("Head") and isBoss(v) then
            local dist=getDistance(origin,v.Head.Position)
            if dist<radius then
                table.insert(list,{boss=v,distance=dist})
            end
        end
    end
    table.sort(list,function(a,b)return a.distance<b.distance end)
    return list
end
local function getFruitsInRadius(origin,radius)
    local list={}
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Part") and isFruit(v) then
            local dist=getDistance(origin,v.Position)
            if dist<radius then
                table.insert(list,{fruit=v,distance=dist})
            end
        end
    end
    table.sort(list,function(a,b)return a.distance<b.distance end)
    return list
end
local function getItemsInRadius(origin,radius)
    local list={}
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Part") and isItem(v) then
            local dist=getDistance(origin,v.Position)
            if dist<radius then
                table.insert(list,{item=v,distance=dist})
            end
        end
    end
    table.sort(list,function(a,b)return a.distance<b.distance end)
    return list
end
local function getWeaponsInRadius(origin,radius)
    local list={}
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Part") and isWeapon(v) then
            local dist=getDistance(origin,v.Position)
            if dist<radius then
                table.insert(list,{weapon=v,distance=dist})
            end
        end
    end
    table.sort(list,function(a,b)return a.distance<b.distance end)
    return list
end
local function getAllObjectsInRadius(origin,radius)
    local list={}
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Part") or v:IsA("Model") then
            local pos
            if v:IsA("Part") then pos=v.Position
            elseif v:IsA("Model") and v:FindFirstChild("Head") then pos=v.Head.Position
            else pos=v:FindFirstChild("HumanoidRootPart") and v.HumanoidRootPart.Position or v:FindFirstChild("Torso") and v.Torso.Position or v.Position end
            if pos then
                local dist=getDistance(origin,pos)
                if dist<radius then
                    table.insert(list,{obj=v,distance=dist})
                end
            end
        end
    end
    table.sort(list,function(a,b)return a.distance<b.distance end)
    return list
end
local function getTimeOfDay()
    return lighting.TimeOfDay
end
local function getHour()
    local time=lighting.TimeOfDay
    local hour=tonumber(string.sub(time,1,2))
    return hour or 0
end
local function isNight()
    local h=getHour()
    return h>=18 or h<6
end
local function isDay()
    return not isNight()
end
local function getWeather()
    local brightness=lighting.Brightness
    if brightness>=0.8 then return "Clear"
    elseif brightness>=0.5 then return "Rain"
    elseif brightness>=0.2 then return "Storm"
    else return "Fog" end
end
local function getSeaLevel()
    local sea=workspace:FindFirstChild("Sea")
    if sea then
        return sea.Position.Y
    end
    return 0
end
local function getRandomString(length)
    length=length or 10
    local chars="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    local result=""
    for i=1,length do
        result=result..string.sub(chars,math.random(1,#chars),math.random(1,#chars))
    end
    return result
end
local function getUniqueId()
    return httpService:GenerateGUID(false)
end
local function getTimestamp()
    return os.time()
end
local function getDate()
    return os.date("%Y-%m-%d %H:%M:%S")
end
local function getFormattedTime()
    return os.date("%H:%M:%S")
end
local function getFormattedDate()
    return os.date("%d/%m/%Y")
end
local function sleep(seconds)
    task.wait(seconds)
end
local function waitFor(condition,timeout)
    timeout=timeout or 5
    local start=tick()
    while tick()-start<timeout do
        if condition() then return true end
        task.wait(0.1)
    end
    return false
end
local function retry(func,maxAttempts,delay)
    maxAttempts=maxAttempts or 3
    delay=delay or 0.5
    local attempts=0
    while attempts<maxAttempts do
        local success,result=pcall(func)
        if success then return result end
        attempts=attempts+1
        task.wait(delay)
    end
    return nil
end
local function safeCall(func,...)
    local success,result=pcall(func,...)
    if success then
        return result
    else
        warn("[Utils] Safe call failed: "..tostring(result))
        return nil
    end
end
local function toTableString(tbl)
    local result="{"
    for k,v in pairs(tbl) do
        if type(v)=="table" then
            result=result..k.."="..toTableString(v)..","
        else
            result=result..k.."="..tostring(v)..","
        end
    end
    result=result.."}"
    return result
end
local function printTable(tbl)
    print(toTableString(tbl))
end
local function cloneTable(tbl)
    local r={}
    for k,v in pairs(tbl) do
        if type(v)=="table" then
            r[k]=cloneTable(v)
        else
            r[k]=v
        end
    end
    return r
end
local function mergeTables(t1,t2)
    for k,v in pairs(t2) do
        if type(v)=="table" and type(t1[k])=="table" then
            mergeTables(t1[k],v)
        else
            t1[k]=v
        end
    end
    return t1
end
local function findKey(tbl,value)
    for k,v in pairs(tbl) do
        if v==value then return k end
    end
    return nil
end
local function findValue(tbl,key)
    return tbl[key]
end
local function tableSize(tbl)
    local count=0
    for _,_ in pairs(tbl) do count=count+1 end
    return count
end
local function tableIsEmpty(tbl)
    return tableSize(tbl)==0
end
local function tableContains(tbl,value)
    for _,v in pairs(tbl) do
        if v==value then return true end
    end
    return false
end
local function tableRemoveValue(tbl,value)
    for i,v in ipairs(tbl) do
        if v==value then
            table.remove(tbl,i)
            return true
        end
    end
    return false
end
local function tableInsertUnique(tbl,value)
    if not tableContains(tbl,value) then
        table.insert(tbl,value)
        return true
    end
    return false
end
local function stringSplit(str,delimiter)
    local result={}
    for part in string.gmatch(str,"([^"..delimiter.."]+)") do
        table.insert(result,part)
    end
    return result
end
local function stringStartsWith(str,prefix)
    return string.sub(str,1,string.len(prefix))==prefix
end
local function stringEndsWith(str,suffix)
    return string.sub(str,-string.len(suffix))==suffix
end
local function stringContains(str,sub)
    return string.find(str,sub)~=nil
end
local function stringReplace(str,from,to)
    return string.gsub(str,from,to)
end
local function stringToLower(str)
    return string.lower(str)
end
local function stringToUpper(str)
    return string.upper(str)
end
local function stringTrim(str)
    return string.gsub(str,"^%s*(.-)%s*$","%1")
end
local function createBillboard(parent,text,color,size,offset)
    size=size or 2
    offset=offset or Vector3.new(0,3,0)
    local bill=Instance.new("BillboardGui")
    bill.Size=UDim2.new(0,size*100,0,size*30)
    bill.AlwaysOnTop=true
    bill.StudsOffset=offset
    bill.Parent=parent
    local label=Instance.new("TextLabel")
    label.Size=UDim2.new(1,0,1,0)
    label.BackgroundTransparency=1
    label.Text=text
    label.TextColor3=color
    label.TextScaled=true
    label.Font=Enum.Font.GothamBold
    label.Parent=bill
    return bill
end
local function createBox(parent,color,size)
    size=size or 3
    local box=Instance.new("BoxHandleAdornment")
    box.Size=Vector3.new(size,size*2,size)
    box.Adornee=parent
    box.Color3=color
    box.Transparency=0.3
    box.AlwaysOnTop=true
    box.ZIndex=5
    box.Parent=parent
    return box
end
local function createLine(from,to,color)
    local line=Instance.new("SelectionPartLasso")
    line.Humanoid=from
    line.Part=to
    line.Color=color
    line.Transparency=0.5
    line.Visible=true
    line.Parent=workspace
    return line
end
local function createGlow(part,color,size)
    size=size or 1
    local glow=Instance.new("SelectionBox")
    glow.Adornee=part
    glow.Color3=color
    glow.Transparency=0.5
    glow.Parent=part
    return glow
end
local function createBeam(part1,part2,color)
    local beam=Instance.new("Beam")
    beam.Attachment0=Instance.new("Attachment",part1)
    beam.Attachment1=Instance.new("Attachment",part2)
    beam.Color=ColorSequence.new(color)
    beam.Transparency=NumberSequence.new(0.5)
    beam.Parent=workspace
    return beam
end
local function createParticles(part,color,size,count)
    local emitter=Instance.new("ParticleEmitter")
    emitter.Texture="rbxassetid://13824669834"
    emitter.Color=ColorSequence.new(color)
    emitter.Size=NumberSequence.new(size)
    emitter.Rate=count or 100
    emitter.Parent=part
    emitter:Emit(count or 100)
    debris:AddItem(emitter,1)
    return emitter
end
local function createTween(obj,properties,duration,style,direction)
    style=style or Enum.EasingStyle.Linear
    direction=direction or Enum.EasingDirection.Out
    local tweenInfo=TweenInfo.new(duration or 0.5,style,direction)
    local tween=tweenService:Create(obj,tweenInfo,properties)
    tween:Play()
    return tween
end
local function createNotification(title,message,duration)
    duration=duration or 3
    local gui=Instance.new("ScreenGui")
    gui.Parent=coreGui
    local frame=Instance.new("Frame")
    frame.Size=UDim2.new(0,300,0,100)
    frame.Position=UDim2.new(0.5,-150,0.1,0)
    frame.BackgroundColor3=Color3.fromRGB(10,10,20)
    frame.BackgroundTransparency=0.3
    frame.BorderSizePixel=0
    frame.Parent=gui
    local titleLabel=Instance.new("TextLabel")
    titleLabel.Size=UDim2.new(1,0,0,30)
    titleLabel.Text=title
    titleLabel.TextColor3=Color3.fromRGB(0,200,255)
    titleLabel.TextScaled=true
    titleLabel.Font=Enum.Font.GothamBold
    titleLabel.Parent=frame
    local msgLabel=Instance.new("TextLabel")
    msgLabel.Size=UDim2.new(1,0,0,50)
    msgLabel.Position=UDim2.new(0,0,0,35)
    msgLabel.Text=message
    msgLabel.TextColor3=Color3.fromRGB(255,255,255)
    msgLabel.TextScaled=true
    msgLabel.Parent=frame
    createTween(frame,{BackgroundTransparency=1},duration,Enum.EasingStyle.Linear)
    debris:AddItem(gui,duration+0.5)
    return gui
end
local function createProgressBar(parent,width,height,color,text)
    local frame=Instance.new("Frame")
    frame.Size=UDim2.new(0,width or 200,0,height or 20)
    frame.BackgroundColor3=Color3.fromRGB(30,30,30)
    frame.Parent=parent
    local fill=Instance.new("Frame")
    fill.Size=UDim2.new(0,0,1,0)
    fill.BackgroundColor3=color or Color3.fromRGB(0,255,0)
    fill.Parent=frame
    local label=Instance.new("TextLabel")
    label.Size=UDim2.new(1,0,1,0)
    label.BackgroundTransparency=1
    label.Text=text or "0%"
    label.TextColor3=Color3.fromRGB(255,255,255)
    label.TextScaled=true
    label.Parent=frame
    return {frame=frame,fill=fill,label=label}
end
local function updateProgressBar(bar,progress)
    bar.fill.Size=UDim2.new(math.clamp(progress,0,1),0,1,0)
    bar.label.Text=math.floor(progress*100).."%"
end
local function createButton(parent,text,callback)
    local btn=Instance.new("TextButton")
    btn.Size=UDim2.new(0,100,0,30)
    btn.Text=text
    btn.BackgroundColor3=Color3.fromRGB(40,40,80)
    btn.TextColor3=Color3.fromRGB(255,255,255)
    btn.Parent=parent
    btn.MouseButton1Click:Connect(callback)
    return btn
end
local function createToggle(parent,text,default,callback)
    local frame=Instance.new("Frame")
    frame.Size=UDim2.new(0,200,0,30)
    frame.BackgroundTransparency=1
    frame.Parent=parent
    local label=Instance.new("TextLabel")
    label.Size=UDim2.new(0.7,0,1,0)
    label.BackgroundTransparency=1
    label.Text=text
    label.TextColor3=Color3.fromRGB(255,255,255)
    label.TextXAlignment=Enum.TextXAlignment.Left
    label.Parent=frame
    local toggle=Instance.new("TextButton")
    toggle.Size=UDim2.new(0.2,0,1,0)
    toggle.Position=UDim2.new(0.8,0,0,0)
    toggle.BackgroundColor3=default and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0)
    toggle.Text=default and "ON" or "OFF"
    toggle.TextColor3=Color3.fromRGB(255,255,255)
    toggle.Parent=frame
    toggle.MouseButton1Click:Connect(function()
        default=not default
        toggle.BackgroundColor3=default and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0)
        toggle.Text=default and "ON" or "OFF"
        callback(default)
    end)
    return {frame=frame,toggle=toggle}
end
local function createSlider(parent,text,min,max,default,callback)
    local frame=Instance.new("Frame")
    frame.Size=UDim2.new(0,200,0,40)
    frame.BackgroundTransparency=1
    frame.Parent=parent
    local label=Instance.new("TextLabel")
    label.Size=UDim2.new(1,0,0.5,0)
    label.BackgroundTransparency=1
    label.Text=text..": "..string.format("%.1f",default)
    label.TextColor3=Color3.fromRGB(255,255,255)
    label.Parent=frame
    local sliderBg=Instance.new("Frame")
    sliderBg.Size=UDim2.new(0.8,0,0.3,0)
    sliderBg.Position=UDim2.new(0.1,0,0.5,0)
    sliderBg.BackgroundColor3=Color3.fromRGB(50,50,50)
    sliderBg.Parent=frame
    local fill=Instance.new("Frame")
    fill.Size=UDim2.new((default-min)/(max-min),0,1,0)
    fill.BackgroundColor3=Color3.fromRGB(0,200,255)
    fill.Parent=sliderBg
    local drag=Instance.new("TextButton")
    drag.Size=UDim2.new(0,20,1,0)
    drag.Position=UDim2.new(fill.Size.X.Scale,-10,0,0)
    drag.BackgroundColor3=Color3.fromRGB(255,255,255)
    drag.Text=""
    drag.Parent=sliderBg
    local dragging=false
    drag.MouseButton1Down:Connect(function()dragging=true end)
    userInput.InputEnded:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
    end)
    runService.RenderStepped:Connect(function()
        if dragging then
            local mouse=player:GetMouse()
            local relX=(mouse.X-sliderBg.AbsolutePosition.X)/sliderBg.AbsoluteSize.X
            relX=math.clamp(relX,0,1)
            fill.Size=UDim2.new(relX,0,1,0)
            drag.Position=UDim2.new(relX,-10,0,0)
            local val=min+(max-min)*relX
            label.Text=text..": "..string.format("%.1f",val)
            callback(val)
        end
    end)
    return {frame=frame,sliderBg=sliderBg,fill=fill,drag=drag}
end
local function createDropdown(parent,text,items,default,callback)
    local frame=Instance.new("Frame")
    frame.Size=UDim2.new(0,200,0,30)
    frame.BackgroundTransparency=1
    frame.Parent=parent
    local label=Instance.new("TextLabel")
    label.Size=UDim2.new(0.4,0,1,0)
    label.BackgroundTransparency=1
    label.Text=text
    label.TextColor3=Color3.fromRGB(255,255,255)
    label.TextXAlignment=Enum.TextXAlignment.Left
    label.Parent=frame
    local dropdown=Instance.new("TextButton")
    dropdown.Size=UDim2.new(0.5,0,1,0)
    dropdown.Position=UDim2.new(0.5,0,0,0)
    dropdown.BackgroundColor3=Color3.fromRGB(30,30,60)
    dropdown.Text=default
    dropdown.TextColor3=Color3.fromRGB(255,255,255)
    dropdown.Parent=frame
    local listFrame=Instance.new("Frame")
    listFrame.Size=UDim2.new(0.5,0,0,0)
    listFrame.Position=UDim2.new(0.5,0,0,30)
    listFrame.BackgroundColor3=Color3.fromRGB(20,20,40)
    listFrame.ClipsDescendants=true
    listFrame.Parent=frame
    listFrame.Visible=false
    local listLayout=Instance.new("UIListLayout")
    listLayout.Parent=listFrame
    for _,item in ipairs(items) do
        local btn=Instance.new("TextButton")
        btn.Size=UDim2.new(1,0,0,25)
        btn.BackgroundTransparency=1
        btn.Text=item
        btn.TextColor3=Color3.fromRGB(255,255,255)
        btn.Parent=listFrame
        btn.MouseButton1Click:Connect(function()
            dropdown.Text=item
            listFrame.Visible=false
            callback(item)
        end)
    end
    dropdown.MouseButton1Click:Connect(function()
        listFrame.Visible=not listFrame.Visible
        if listFrame.Visible then
            listFrame.Size=UDim2.new(0.5,0,0,#items*25)
        else
            listFrame.Size=UDim2.new(0.5,0,0,0)
        end
    end)
    return {frame=frame,dropdown=dropdown,listFrame=listFrame}
end
local function createInput(parent,text,default,callback)
    local frame=Instance.new("Frame")
    frame.Size=UDim2.new(0,200,0,30)
    frame.BackgroundTransparency=1
    frame.Parent=parent
    local label=Instance.new("TextLabel")
    label.Size=UDim2.new(0.3,0,1,0)
    label.BackgroundTransparency=1
    label.Text=text
    label.TextColor3=Color3.fromRGB(255,255,255)
    label.TextXAlignment=Enum.TextXAlignment.Left
    label.Parent=frame
    local box=Instance.new("TextBox")
    box.Size=UDim2.new(0.6,0,1,0)
    box.Position=UDim2.new(0.4,0,0,0)
    box.BackgroundColor3=Color3.fromRGB(30,30,60)
    box.Text=default
    box.TextColor3=Color3.fromRGB(255,255,255)
    box.Parent=frame
    box.FocusLost:Connect(function(enter)
        if enter then callback(box.Text) end
    end)
    return {frame=frame,box=box}
end
local function createKeybind(parent,text,default,callback)
    local frame=Instance.new("Frame")
    frame.Size=UDim2.new(0,200,0,30)
    frame.BackgroundTransparency=1
    frame.Parent=parent
    local label=Instance.new("TextLabel")
    label.Size=UDim2.new(0.5,0,1,0)
    label.BackgroundTransparency=1
    label.Text=text
    label.TextColor3=Color3.fromRGB(255,255,255)
    label.TextXAlignment=Enum.TextXAlignment.Left
    label.Parent=frame
    local btn=Instance.new("TextButton")
    btn.Size=UDim2.new(0.3,0,1,0)
    btn.Position=UDim2.new(0.7,0,0,0)
    btn.BackgroundColor3=Color3.fromRGB(30,30,60)
    btn.Text=tostring(default)
    btn.TextColor3=Color3.fromRGB(255,255,255)
    btn.Parent=frame
    local listening=false
    btn.MouseButton1Click:Connect(function()
        listening=true
        btn.Text="Nhấn phím..."
    end)
    userInput.InputBegan:Connect(function(input,gameProcessed)
        if listening and not gameProcessed then
            local key=input.KeyCode
            if key~=Enum.KeyCode.Unknown then
                btn.Text=tostring(key)
                listening=false
                callback(key)
            end
        end
    end)
    return {frame=frame,btn=btn}
end
local function createSpacer(parent,height)
    height=height or 10
    local spacer=Instance.new("Frame")
    spacer.Size=UDim2.new(1,0,0,height)
    spacer.BackgroundTransparency=1
    spacer.Parent=parent
    return spacer
end
local function createDivider(parent,color,height)
    height=height or 2
    color=color or Color3.fromRGB(100,100,100)
    local div=Instance.new("Frame")
    div.Size=UDim2.new(1,0,0,height)
    div.BackgroundColor3=color
    div.Parent=parent
    return div
end
local function createScrollFrame(parent,size)
    local scroll=Instance.new("ScrollingFrame")
    scroll.Size=size or UDim2.new(1,0,1,0)
    scroll.BackgroundColor3=Color3.fromRGB(20,20,40)
    scroll.BackgroundTransparency=0.5
    scroll.BorderSizePixel=0
    scroll.Parent=parent
    scroll.CanvasSize=UDim2.new(0,0,0,0)
    scroll.ScrollBarThickness=6
    local layout=Instance.new("UIListLayout")
    layout.Parent=scroll
    layout.SortOrder=Enum.SortOrder.LayoutOrder
    layout.Padding=UDim.new(0,5)
    return scroll
end
local function createText(parent,text,color,size,font)
    size=size or 20
    font=font or Enum.Font.Gotham
    local label=Instance.new("TextLabel")
    label.Size=UDim2.new(1,0,0,size)
    label.BackgroundTransparency=1
    label.Text=text
    label.TextColor3=color or Color3.fromRGB(255,255,255)
    label.TextScaled=true
    label.Font=font
    label.Parent=parent
    return label
end
local function createImage(parent,image,size,pos)
    local img=Instance.new("ImageLabel")
    img.Size=size or UDim2.new(0,50,0,50)
    img.Position=pos or UDim2.new(0,0,0,0)
    img.Image=image
    img.BackgroundTransparency=1
    img.Parent=parent
    return img
end
local function getFruitRarity(fruitName)
    local rarities={
        ["Bomb"]="Common",["Spike"]="Common",["Rubber"]="Common",["Chop"]="Common",
        ["Falcon"]="Common",["Smoke"]="Common",["Spring"]="Common",
        ["Flame"]="Uncommon",["Ice"]="Uncommon",["Sand"]="Uncommon",["Ghost"]="Uncommon",
        ["Diamond"]="Uncommon",["Spider"]="Uncommon",
        ["Dark"]="Rare",["Light"]="Rare",["Magma"]="Rare",["Buddha"]="Rare",
        ["Love"]="Rare",
        ["Quake"]="Legendary",["String"]="Legendary",["Gravity"]="Legendary",
        ["Shadow"]="Legendary",["Rumble"]="Legendary",
        ["Dragon"]="Mythical",["Leopard"]="Mythical",["Venom"]="Mythical",
        ["Control"]="Mythical",["Soul"]="Mythical",["Blizzard"]="Mythical",
        ["Dough"]="Mythical",["Phoenix"]="Legendary"
    }
    return rarities[fruitName] or "Common"
end
local function getWeaponRarity(weaponName)
    local rarities={
        ["Saber"]="Rare",["Katana"]="Common",["Trident"]="Uncommon",
        ["Pole"]="Common",["Gun"]="Common",["Flintlock"]="Uncommon",
        ["Musket"]="Rare",["Cannon"]="Legendary",["Sword"]="Common",
        ["Axe"]="Uncommon",["Hammer"]="Rare",["Spear"]="Common",
        ["Dagger"]="Common",["Bow"]="Uncommon",["Crossbow"]="Rare"
    }
    return rarities[weaponName] or "Common"
end
local function getFruitColor(fruitName)
    local colors={
        ["Bomb"]=Color3.fromRGB(200,200,200),["Spike"]=Color3.fromRGB(150,150,150),
        ["Flame"]=Color3.fromRGB(255,100,0),["Ice"]=Color3.fromRGB(0,200,255),
        ["Sand"]=Color3.fromRGB(200,180,100),["Dark"]=Color3.fromRGB(80,0,120),
        ["Light"]=Color3.fromRGB(255,255,200),["Magma"]=Color3.fromRGB(255,50,0),
        ["Quake"]=Color3.fromRGB(100,100,255),["String"]=Color3.fromRGB(200,200,255),
        ["Dough"]=Color3.fromRGB(255,200,100),["Dragon"]=Color3.fromRGB(255,0,200),
        ["Leopard"]=Color3.fromRGB(255,150,0),["Venom"]=Color3.fromRGB(0,200,0),
        ["Control"]=Color3.fromRGB(100,100,200),["Gravity"]=Color3.fromRGB(150,50,200),
        ["Shadow"]=Color3.fromRGB(100,0,100),["Rumble"]=Color3.fromRGB(255,200,0),
        ["Buddha"]=Color3.fromRGB(255,200,100),["Love"]=Color3.fromRGB(255,100,100),
        ["Spider"]=Color3.fromRGB(100,100,100),["Rubber"]=Color3.fromRGB(255,0,0),
        ["Chop"]=Color3.fromRGB(0,150,0),["Falcon"]=Color3.fromRGB(150,150,255),
        ["Smoke"]=Color3.fromRGB(100,100,100),["Spring"]=Color3.fromRGB(0,255,0),
        ["Ghost"]=Color3.fromRGB(200,200,255),["Diamond"]=Color3.fromRGB(0,255,255),
        ["Revive"]=Color3.fromRGB(0,255,150),["Door"]=Color3.fromRGB(100,50,0),
        ["Paw"]=Color3.fromRGB(255,150,150),["Phoenix"]=Color3.fromRGB(255,100,0),
        ["Soul"]=Color3.fromRGB(150,0,255),["Blizzard"]=Color3.fromRGB(0,200,255)
    }
    return colors[fruitName] or Color3.fromRGB(255,255,255)
end
local function getRarityColor(rarity)
    local colors={
        ["Common"]=Color3.fromRGB(200,200,200),
        ["Uncommon"]=Color3.fromRGB(0,255,0),
        ["Rare"]=Color3.fromRGB(0,0,255),
        ["Legendary"]=Color3.fromRGB(255,0,255),
        ["Mythical"]=Color3.fromRGB(255,0,0),
        ["Secret"]=Color3.fromRGB(255,255,0)
    }
    return colors[rarity] or Color3.fromRGB(255,255,255)
end
local function getIslandName(position)
    local islands={
        Jungle=Vector3.new(-1000,50,0),
        Pirate=Vector3.new(0,50,1000),
        Marine=Vector3.new(1000,50,0),
        Sky=Vector3.new(0,500,0),
        Magma=Vector3.new(-500,50,-500),
        Ice=Vector3.new(500,50,-500),
        Desert=Vector3.new(0,50,-1000),
        Volcano=Vector3.new(-1000,100,-1000),
        Underwater=Vector3.new(0,-100,0),
        Kingdom=Vector3.new(2000,50,2000)
    }
    local closest=nil
    local minDist=math.huge
    for name,pos in pairs(islands) do
        local dist=getDistance(position,pos)
        if dist<minDist then
            minDist=dist
            closest=name
        end
    end
    return closest
end
local function getIslandPosition(name)
    local islands={
        Jungle=Vector3.new(-1000,50,0),
        Pirate=Vector3.new(0,50,1000),
        Marine=Vector3.new(1000,50,0),
        Sky=Vector3.new(0,500,0),
        Magma=Vector3.new(-500,50,-500),
        Ice=Vector3.new(500,50,-500),
        Desert=Vector3.new(0,50,-1000),
        Volcano=Vector3.new(-1000,100,-1000),
        Underwater=Vector3.new(0,-100,0),
        Kingdom=Vector3.new(2000,50,2000)
    }
    return islands[name]
end
local function getAllIslands()
    return {"Jungle","Pirate","Marine","Sky","Magma","Ice","Desert","Volcano","Underwater","Kingdom"}
end
local function getAllFruits()
    return {"Bomb","Spike","Flame","Ice","Sand","Dark","Light","Magma","Quake","String","Dough","Dragon","Leopard","Venom","Control","Gravity","Shadow","Rumble","Buddha","Love","Spider","Rubber","Chop","Falcon","Smoke","Spring","Ghost","Diamond","Revive","Door","Paw","Phoenix","Soul","Blizzard"}
end
local function getAllWeapons()
    return {"Saber","Katana","Trident","Pole","Gun","Flintlock","Musket","Cannon","Sword","Axe","Hammer","Spear","Dagger","Bow","Crossbow"}
end
local function getGameVersion()
    local version=replicatedStorage:FindFirstChild("Version")
    if version and version:IsA("StringValue") then
        return version.Value
    end
    return "Unknown"
end
local function getPing()
    return math.floor(player:GetPing()*1000)
end
local function getFps()
    local fps=runService:GetRenderStepped():Wait() and 60 or 60
    return fps
end
local function isMobile()
    return runService:IsMobile()
end
local function isStudio()
    return runService:IsStudio()
end
local function getScreenSize()
    return guiService:GetScreenSize()
end
local function getMousePosition()
    return player:GetMouse().X,player:GetMouse().Y
end
local function getKeyPressed()
    local key=userInput:GetKeysPressed()
    if #key>0 then
        return key[1].KeyCode
    end
    return nil
end
local function isKeyDown(key)
    return userInput:IsKeyDown(key)
end
local function waitForKeyPress()
    local event
    local done=false
    local keyPressed=nil
    event=userInput.InputBegan:Connect(function(input,gameProcessed)
        if not gameProcessed then
            keyPressed=input.KeyCode
            done=true
            event:Disconnect()
        end
    end)
    repeat task.wait(0.1) until done
    return keyPressed
end
local function getClipboard()
    return guiService:GetClipboard()
end
local function setClipboard(text)
    guiService:SetClipboard(text)
    return true
end
local function takeScreenshot()
    return guiService:TakeScreenshot()
end
local function getSystemInfo()
    return {
        gameVersion=getGameVersion(),
        ping=getPing(),
        fps=getFps(),
        isMobile=isMobile(),
        isStudio=isStudio(),
        screenSize=getScreenSize(),
        playerCount=getPlayerCount(),
        time=getFormattedTime(),
        date=getFormattedDate()
    }
end
local function log(message)
    print("[Utils] "..message)
    return true
end
local function warnLog(message)
    warn("[Utils] "..message)
    return true
end
local function errorLog(message)
    error("[Utils] "..message)
    return true
end
local function debugLog(message)
    if dataRef and dataRef.debug then
        print("[Utils Debug] "..message)
    end
    return true
end
local function setDebugMode(state)
    if not dataRef then dataRef={} end
    dataRef.debug=state
    return true
end
local function isDebugMode()
    return dataRef and dataRef.debug or false
end
local function getDataRef()
    return dataRef
end
local function setDataRef(data)
    dataRef=data
    return true
end
local function initialize(data)
    dataRef=data
    return true
end
utils.Initialize=initialize
utils.getDistance=getDistance
utils.getClosest=getClosest
utils.getRandomPosition=getRandomPosition
utils.getRandomColor=getRandomColor
utils.getCharacter=getCharacter
utils.getHumanoid=getHumanoid
utils.getHead=getHead
utils.getRootPart=getRootPart
utils.isAlive=isAlive
utils.isPlayer=isPlayer
utils.isNPC=isNPC
utils.isBoss=isBoss
utils.isFruit=isFruit
utils.isItem=isItem
utils.isWeapon=isWeapon
utils.getFruitName=getFruitName
utils.getItemName=getItemName
utils.getWeaponName=getWeaponName
utils.getBeli=getBeli
utils.getGems=getGems
utils.getLevel=getLevel
utils.getExp=getExp
utils.getMaxExp=getMaxExp
utils.getFruit=getFruit
utils.getWeapon=getWeapon
utils.getStatPoints=getStatPoints
utils.getStat=getStat
utils.getAllStats=getAllStats
utils.getPlayerCount=getPlayerCount
utils.getAlivePlayers=getAlivePlayers
utils.getDeadPlayers=getDeadPlayers
utils.getNearestPlayer=getNearestPlayer
utils.getNearestNPC=getNearestNPC
utils.getNearestBoss=getNearestBoss
utils.getNearestFruit=getNearestFruit
utils.getNearestItem=getNearestItem
utils.getPlayersInRadius=getPlayersInRadius
utils.getNPCsInRadius=getNPCsInRadius
utils.getBossesInRadius=getBossesInRadius
utils.getFruitsInRadius=getFruitsInRadius
utils.getItemsInRadius=getItemsInRadius
utils.getWeaponsInRadius=getWeaponsInRadius
utils.getAllObjectsInRadius=getAllObjectsInRadius
utils.getTimeOfDay=getTimeOfDay
utils.getHour=getHour
utils.isNight=isNight
utils.isDay=isDay
utils.getWeather=getWeather
utils.getSeaLevel=getSeaLevel
utils.getRandomString=getRandomString
utils.getUniqueId=getUniqueId
utils.getTimestamp=getTimestamp
utils.getDate=getDate
utils.getFormattedTime=getFormattedTime
utils.getFormattedDate=getFormattedDate
utils.sleep=sleep
utils.waitFor=waitFor
utils.retry=retry
utils.safeCall=safeCall
utils.toTableString=toTableString
utils.printTable=printTable
utils.cloneTable=cloneTable
utils.mergeTables=mergeTables
utils.findKey=findKey
utils.findValue=findValue
utils.tableSize=tableSize
utils.tableIsEmpty=tableIsEmpty
utils.tableContains=tableContains
utils.tableRemoveValue=tableRemoveValue
utils.tableInsertUnique=tableInsertUnique
utils.stringSplit=stringSplit
utils.stringStartsWith=stringStartsWith
utils.stringEndsWith=stringEndsWith
utils.stringContains=stringContains
utils.stringReplace=stringReplace
utils.stringToLower=stringToLower
utils.stringToUpper=stringToUpper
utils.stringTrim=stringTrim
utils.createBillboard=createBillboard
utils.createBox=createBox
utils.createLine=createLine
utils.createGlow=createGlow
utils.createBeam=createBeam
utils.createParticles=createParticles
utils.createTween=createTween
utils.createNotification=createNotification
utils.createProgressBar=createProgressBar
utils.updateProgressBar=updateProgressBar
utils.createButton=createButton
utils.createToggle=createToggle
utils.createSlider=createSlider
utils.createDropdown=createDropdown
utils.createInput=createInput
utils.createKeybind=createKeybind
utils.createSpacer=createSpacer
utils.createDivider=createDivider
utils.createScrollFrame=createScrollFrame
utils.createText=createText
utils.createImage=createImage
utils.getFruitRarity=getFruitRarity
utils.getWeaponRarity=getWeaponRarity
utils.getFruitColor=getFruitColor
utils.getRarityColor=getRarityColor
utils.getIslandName=getIslandName
utils.getIslandPosition=getIslandPosition
utils.getAllIslands=getAllIslands
utils.getAllFruits=getAllFruits
utils.getAllWeapons=getAllWeapons
utils.getGameVersion=getGameVersion
utils.getPing=getPing
utils.getFps=getFps
utils.isMobile=isMobile
utils.isStudio=isStudio
utils.getScreenSize=getScreenSize
utils.getMousePosition=getMousePosition
utils.getKeyPressed=getKeyPressed
utils.isKeyDown=isKeyDown
utils.waitForKeyPress=waitForKeyPress
utils.getClipboard=getClipboard
utils.setClipboard=setClipboard
utils.takeScreenshot=takeScreenshot
utils.getSystemInfo=getSystemInfo
utils.log=log
utils.warnLog=warnLog
utils.errorLog=errorLog
utils.debugLog=debugLog
utils.setDebugMode=setDebugMode
utils.isDebugMode=isDebugMode
utils.getDataRef=getDataRef
utils.setDataRef=setDataRef
return utils
