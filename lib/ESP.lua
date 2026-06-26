local esp={}
esp.__index=esp
local player=game.Players.LocalPlayer
local runService=game:GetService("RunService")
local workspace=game:GetService("Workspace")
local players=game:GetService("Players")
local collectionService=game:GetService("CollectionService")
local debris=game:GetService("Debris")
local tweenService=game:GetService("TweenService")
local lighting=game:GetService("Lighting")
local guiService=game:GetService("GuiService")
local coreGui=game:GetService("CoreGui")
local character=nil local humanoid=nil local rootPart=nil
local dataRef=nil local isRunning=false
local espObjects={} local espLines={} local espBoxes={} local espNames={}
local fruitColors={
    Common=Color3.fromRGB(200,200,200),
    Uncommon=Color3.fromRGB(0,255,0),
    Rare=Color3.fromRGB(0,0,255),
    Legendary=Color3.fromRGB(255,0,255),
    Mythical=Color3.fromRGB(255,0,0),
    Secret=Color3.fromRGB(255,255,0)
}
local playerColors={}
local bossList={} local fruitList={} local npcList={} local itemList={}
local updateInterval=0.2 local maxDistance=1000
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
local function getRandomColor(seed)
    local colors={Color3.fromRGB(255,0,0),Color3.fromRGB(0,255,0),Color3.fromRGB(0,0,255),Color3.fromRGB(255,255,0),Color3.fromRGB(255,0,255),Color3.fromRGB(0,255,255),Color3.fromRGB(255,128,0),Color3.fromRGB(128,0,255)}
    return colors[seed%#colors+1]
end
local function createBillboard(parent,text,color,size)
    size=size or 2
    local bill=Instance.new("BillboardGui")
    bill.Size=UDim2.new(0,size*100,0,size*30)
    bill.AlwaysOnTop=true
    bill.StudsOffset=Vector3.new(0,3,0)
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
local function getPlayerLevel(p)
    local level=p:FindFirstChild("Level")
    if level and level:IsA("NumberValue") then
        return level.Value
    end
    return 0
end
local function getPlayerHealth(p)
    local char=p.Character
    if char and char:FindFirstChild("Humanoid") then
        return char.Humanoid.Health
    end
    return 0
end
local function getPlayerMaxHealth(p)
    local char=p.Character
    if char and char:FindFirstChild("Humanoid") then
        return char.Humanoid.MaxHealth
    end
    return 100
end
local function getFruitRarity(fruitName)
    local rarities={
        ["Bomb"]="Common",["Spike"]="Common",["Flame"]="Uncommon",["Ice"]="Uncommon",
        ["Sand"]="Uncommon",["Dark"]="Rare",["Light"]="Rare",["Magma"]="Rare",
        ["Quake"]="Legendary",["String"]="Legendary",["Dough"]="Legendary",
        ["Dragon"]="Mythical",["Leopard"]="Mythical",["Venom"]="Mythical",
        ["Control"]="Mythical",["Gravity"]="Legendary",["Shadow"]="Legendary",
        ["Rumble"]="Legendary",["Buddha"]="Rare",["Love"]="Rare",
        ["Spider"]="Uncommon",["Rubber"]="Common",["Chop"]="Common",
        ["Falcon"]="Common",["Smoke"]="Common",["Spring"]="Common",
        ["Ghost"]="Uncommon",["Diamond"]="Uncommon"
    }
    return rarities[fruitName] or "Common"
end
local function isBoss(model)
    if model:FindFirstChild("IsBoss") and model:FindFirstChild("Humanoid") then
        return true
    end
    if model.Name:lower():match("boss") or model.Name:lower():match("king") then
        return true
    end
    return false
end
local function isNPC(model)
    if model:FindFirstChild("IsNPC") then
        return true
    end
    if model:FindFirstChild("Humanoid") and model:FindFirstChild("Head") then
        if not model:FindFirstChild("IsPlayer") and not isBoss(model) then
            return true
        end
    end
    return false
end
local function isFruit(part)
    if part:FindFirstChild("FruitTag") then
        return true
    end
    if part.Name:lower():match("fruit") or part.Name:lower():match("apple") then
        return true
    end
    return false
end
local function isItem(part)
    if part:FindFirstChild("ItemTag") then
        return true
    end
    if part.Name:lower():match("money") or part.Name:lower():match("coin") or part.Name:lower():match("drop") then
        return true
    end
    return false
end
local function getFruitName(part)
    local tag=part:FindFirstChild("FruitTag")
    if tag and tag:IsA("StringValue") then
        return tag.Value
    end
    return part.Name
end
local function getItemName(part)
    local tag=part:FindFirstChild("ItemTag")
    if tag and tag:IsA("StringValue") then
        return tag.Value
    end
    return part.Name
end
local function cleanESP()
    for _,v in pairs(espObjects) do
        if v and v.Parent then v:Destroy() end
    end
    espObjects={}
    for _,v in pairs(espLines) do
        if v and v.Parent then v:Destroy() end
    end
    espLines={}
    for _,v in pairs(espBoxes) do
        if v and v.Parent then v:Destroy() end
    end
    espBoxes={}
    for _,v in pairs(espNames) do
        if v and v.Parent then v:Destroy() end
    end
    espNames={}
end
local function updateESP(data)
    if not rootPart then updateCharacter() end
    if not rootPart then return end
    local enabled=data.enabled or false
    if not enabled then
        cleanESP()
        return
    end
    local showPlayers=data.showPlayers or false
    local showFruits=data.showFruits or false
    local showItems=data.showItems or false
    local showBoss=data.showBoss or false
    local showNPC=data.showNPC or false
    local distance=data.distance or 1000
    local colorPlayer=data.colorPlayer or Color3.fromRGB(0,255,0)
    local colorFruit=data.colorFruit or Color3.fromRGB(255,255,0)
    local colorItem=data.colorItem or Color3.fromRGB(0,100,255)
    local colorBoss=data.colorBoss or Color3.fromRGB(255,0,0)
    local colorNPC=data.colorNPC or Color3.fromRGB(200,200,200)
    maxDistance=distance
    cleanESP()
    if showPlayers then
        for _,p in pairs(players:GetPlayers()) do
            if p~=player and p.Character and p.Character:FindFirstChild("Head") then
                local head=p.Character.Head
                local dist=getDistance(rootPart.Position,head.Position)
                if dist<distance then
                    local level=getPlayerLevel(p)
                    local health=getPlayerHealth(p)
                    local maxHealth=getPlayerMaxHealth(p)
                    local hpPercent=math.floor((health/maxHealth)*100)
                    local nameText=p.Name.." ["..level.."] "..hpPercent.."%"
                    local bill=createBillboard(head,nameText,colorPlayer,1.5)
                    table.insert(espObjects,bill)
                    local box=createBox(head,colorPlayer,2)
                    table.insert(espBoxes,box)
                    table.insert(espObjects,box)
                    local line=Instance.new("SelectionPartLasso")
                    line.Humanoid=humanoid
                    line.Part=head.Parent:FindFirstChild("HumanoidRootPart") or head
                    line.Color=colorPlayer
                    line.Transparency=0.3
                    line.Parent=workspace
                    table.insert(espLines,line)
                    table.insert(espObjects,line)
                    local healthBar=Instance.new("BillboardGui")
                    healthBar.Size=UDim2.new(0,100,0,10)
                    healthBar.StudsOffset=Vector3.new(0,-1,0)
                    healthBar.AlwaysOnTop=true
                    healthBar.Parent=head
                    local bar=Instance.new("Frame")
                    bar.Size=UDim2.new(hpPercent/100,0,1,0)
                    bar.BackgroundColor3=Color3.fromRGB(0,255,0)
                    if hpPercent<50 then bar.BackgroundColor3=Color3.fromRGB(255,255,0) end
                    if hpPercent<25 then bar.BackgroundColor3=Color3.fromRGB(255,0,0) end
                    bar.Parent=healthBar
                    table.insert(espObjects,healthBar)
                end
            end
        end
    end
    if showFruits then
        for _,v in pairs(workspace:GetChildren()) do
            if v:IsA("Part") and isFruit(v) then
                local dist=getDistance(rootPart.Position,v.Position)
                if dist<distance then
                    local fruitName=getFruitName(v)
                    local rarity=getFruitRarity(fruitName)
                    local color=fruitColors[rarity] or Color3.fromRGB(255,255,255)
                    local bill=createBillboard(v,fruitName.." ["..rarity.."]",color,1.2)
                    table.insert(espObjects,bill)
                    local glow=Instance.new("SelectionBox")
                    glow.Adornee=v
                    glow.Color3=color
                    glow.Transparency=0.5
                    glow.Parent=v
                    table.insert(espObjects,glow)
                    local distText=Instance.new("BillboardGui")
                    distText.Size=UDim2.new(0,50,0,20)
                    distText.StudsOffset=Vector3.new(0,-1.5,0)
                    distText.AlwaysOnTop=true
                    distText.Parent=v
                    local label=Instance.new("TextLabel")
                    label.Size=UDim2.new(1,0,1,0)
                    label.BackgroundTransparency=1
                    label.Text=math.floor(dist).."m"
                    label.TextColor3=color
                    label.TextScaled=true
                    label.Parent=distText
                    table.insert(espObjects,distText)
                end
            end
        end
    end
    if showItems then
        for _,v in pairs(workspace:GetChildren()) do
            if v:IsA("Part") and isItem(v) then
                local dist=getDistance(rootPart.Position,v.Position)
                if dist<distance then
                    local itemName=getItemName(v)
                    local bill=createBillboard(v,itemName.." $"..math.floor(dist),colorItem,1)
                    table.insert(espObjects,bill)
                end
            end
        end
    end
    if showBoss then
        for _,v in pairs(workspace:GetChildren()) do
            if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("Head") then
                if isBoss(v) then
                    local head=v.Head
                    local dist=getDistance(rootPart.Position,head.Position)
                    if dist<distance then
                        local health=v.Humanoid.Health
                        local maxHealth=v.Humanoid.MaxHealth
                        local hpPercent=math.floor((health/maxHealth)*100)
                        local nameText=v.Name.." [BOSS] "..hpPercent.."%"
                        local bill=createBillboard(head,nameText,colorBoss,2)
                        table.insert(espObjects,bill)
                        local box=createBox(head,colorBoss,3)
                        table.insert(espBoxes,box)
                        table.insert(espObjects,box)
                        local healthBar=Instance.new("BillboardGui")
                        healthBar.Size=UDim2.new(0,150,0,15)
                        healthBar.StudsOffset=Vector3.new(0,-2,0)
                        healthBar.AlwaysOnTop=true
                        healthBar.Parent=head
                        local bar=Instance.new("Frame")
                        bar.Size=UDim2.new(hpPercent/100,0,1,0)
                        bar.BackgroundColor3=Color3.fromRGB(255,0,0)
                        if hpPercent<50 then bar.BackgroundColor3=Color3.fromRGB(255,165,0) end
                        if hpPercent<25 then bar.BackgroundColor3=Color3.fromRGB(255,0,0) end
                        bar.Parent=healthBar
                        table.insert(espObjects,healthBar)
                    end
                end
            end
        end
    end
    if showNPC then
        for _,v in pairs(workspace:GetChildren()) do
            if v:IsA("Model") and v:FindFirstChild("Head") then
                if isNPC(v) and not isBoss(v) then
                    local head=v.Head
                    local dist=getDistance(rootPart.Position,head.Position)
                    if dist<distance then
                        local bill=createBillboard(head,v.Name.." [NPC]",colorNPC,1)
                        table.insert(espObjects,bill)
                    end
                end
            end
        end
    end
end
local function startLoop(data)
    if isRunning then return end
    isRunning=true
    task.spawn(function()
        while isRunning do
            wait(updateInterval)
            pcall(function()updateESP(data)end)
        end
    end)
end
function esp.Stop()
    isRunning=false
    cleanESP()
    return true
end
function esp.Update(data)
    if not data then return false end
    dataRef=data
    if not isRunning then
        startLoop(data)
    end
    return true
end
function esp.Toggle()
    if dataRef then
        dataRef.enabled=not dataRef.enabled
        return dataRef.enabled
    end
    return false
end
function esp.SetDistance(dist)
    if dataRef then
        dataRef.distance=dist
        return true
    end
    return false
end
function esp.SetColor(type,color)
    if dataRef then
        if type=="Player" then dataRef.colorPlayer=color
        elseif type=="Fruit" then dataRef.colorFruit=color
        elseif type=="Item" then dataRef.colorItem=color
        elseif type=="Boss" then dataRef.colorBoss=color
        elseif type=="NPC" then dataRef.colorNPC=color end
        return true
    end
    return false
end
function esp.TogglePlayers()
    if dataRef then dataRef.showPlayers=not dataRef.showPlayers return dataRef.showPlayers end
    return false
end
function esp.ToggleFruits()
    if dataRef then dataRef.showFruits=not dataRef.showFruits return dataRef.showFruits end
    return false
end
function esp.ToggleItems()
    if dataRef then dataRef.showItems=not dataRef.showItems return dataRef.showItems end
    return false
end
function esp.ToggleBoss()
    if dataRef then dataRef.showBoss=not dataRef.showBoss return dataRef.showBoss end
    return false
end
function esp.ToggleNPC()
    if dataRef then dataRef.showNPC=not dataRef.showNPC return dataRef.showNPC end
    return false
end
function esp.GetStatus()
    return{
        enabled=dataRef and dataRef.enabled or false,
        showPlayers=dataRef and dataRef.showPlayers or false,
        showFruits=dataRef and dataRef.showFruits or false,
        showItems=dataRef and dataRef.showItems or false,
        showBoss=dataRef and dataRef.showBoss or false,
        showNPC=dataRef and dataRef.showNPC or false,
        distance=dataRef and dataRef.distance or 1000,
        isRunning=isRunning
    }
end
function esp.GetAllPlayers()
    local list={}
    for _,p in pairs(players:GetPlayers()) do
        if p~=player then table.insert(list,p.Name) end
    end
    return list
end
function esp.GetAllFruits()
    local list={}
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Part") and isFruit(v) then
            table.insert(list,getFruitName(v))
        end
    end
    return list
end
function esp.GetAllBosses()
    local list={}
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Model") and isBoss(v) then
            table.insert(list,v.Name)
        end
    end
    return list
end
function esp.GetAllNPCs()
    local list={}
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Model") and isNPC(v) then
            table.insert(list,v.Name)
        end
    end
    return list
end
function esp.GetNearestPlayer()
    local nearest=nil
    local minDist=math.huge
    for _,p in pairs(players:GetPlayers()) do
        if p~=player and p.Character and p.Character:FindFirstChild("Head") then
            local dist=getDistance(rootPart.Position,p.Character.Head.Position)
            if dist<minDist then
                minDist=dist
                nearest=p
            end
        end
    end
    return nearest
end
function esp.GetNearestFruit()
    local nearest=nil
    local minDist=math.huge
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Part") and isFruit(v) then
            local dist=getDistance(rootPart.Position,v.Position)
            if dist<minDist then
                minDist=dist
                nearest=v
            end
        end
    end
    return nearest
end
function esp.GetNearestBoss()
    local nearest=nil
    local minDist=math.huge
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Model") and isBoss(v) and v:FindFirstChild("Head") then
            local dist=getDistance(rootPart.Position,v.Head.Position)
            if dist<minDist then
                minDist=dist
                nearest=v
            end
        end
    end
    return nearest
end
function esp.GetNearestNPC()
    local nearest=nil
    local minDist=math.huge
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Model") and isNPC(v) and v:FindFirstChild("Head") then
            local dist=getDistance(rootPart.Position,v.Head.Position)
            if dist<minDist then
                minDist=dist
                nearest=v
            end
        end
    end
    return nearest
end
function esp.EnableAll()
    if dataRef then
        dataRef.showPlayers=true
        dataRef.showFruits=true
        dataRef.showItems=true
        dataRef.showBoss=true
        dataRef.showNPC=true
        return true
    end
    return false
end
function esp.DisableAll()
    if dataRef then
        dataRef.showPlayers=false
        dataRef.showFruits=false
        dataRef.showItems=false
        dataRef.showBoss=false
        dataRef.showNPC=false
        return true
    end
    return false
end
function esp.SetUpdateInterval(interval)
    updateInterval=interval
    return true
end
function esp.Pause()
    isRunning=false
    return true
end
function esp.Resume()
    if dataRef then
        isRunning=true
        startLoop(dataRef)
        return true
    end
    return false
end
function esp.Destroy()
    isRunning=false
    cleanESP()
    dataRef=nil
    return true
end
function esp.Initialize(data)
    dataRef=data
    updateCharacter()
    return true
end
return esp
