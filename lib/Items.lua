local items={}
items.__index=items
local player=game.Players.LocalPlayer
local runService=game:GetService("RunService")
local userInput=game:GetService("UserInputService")
local workspace=game:GetService("Workspace")
local replicatedStorage=game:GetService("ReplicatedStorage")
local players=game:GetService("Players")
local debris=game:GetService("Debris")
local collectionService=game:GetService("CollectionService")
local tweenService=game:GetService("TweenService")
local character=nil local humanoid=nil local rootPart=nil
local dataRef=nil local isRunning=false
local collectedItems={} local spawnQueue={}
local fruitList={
    "Bomb","Spike","Flame","Ice","Sand","Dark","Light","Magma","Quake","String",
    "Dough","Dragon","Leopard","Venom","Control","Gravity","Shadow","Rumble",
    "Buddha","Love","Spider","Rubber","Chop","Falcon","Smoke","Spring",
    "Ghost","Diamond","Revive","Door","Paw","Phoenix","Soul","Blizzard"
}
local weaponList={
    "Saber","Katana","Trident","Pole","Gun","Flintlock","Musket","Cannon",
    "Sword","Axe","Hammer","Spear","Dagger","Bow","Crossbow"
}
local itemList={
    "Money","Gem","Fragment","Token","Key","Chest","Potion","Scroll","Map","Compass"
}
local rarityColors={
    Common=Color3.fromRGB(200,200,200),
    Uncommon=Color3.fromRGB(0,255,0),
    Rare=Color3.fromRGB(0,0,255),
    Legendary=Color3.fromRGB(255,0,255),
    Mythical=Color3.fromRGB(255,0,0),
    Secret=Color3.fromRGB(255,255,0)
}
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
local function spawnPart(name,position,color,size,value)
    size=size or 3
    local part=Instance.new("Part")
    part.Size=Vector3.new(size,size,size)
    part.Position=position or rootPart.Position+Vector3.new(0,5,0)
    part.Anchored=true
    part.CanCollide=false
    part.BrickColor=BrickColor.new(color or "Bright red")
    part.Name=name or "ItemSpawn"
    local tag=Instance.new("StringValue")
    tag.Name="ItemTag"
    tag.Value=value or ""
    tag.Parent=part
    local glow=Instance.new("SelectionBox")
    glow.Adornee=part
    glow.Color3=Color3.new(color or Color3.fromRGB(255,0,0))
    glow.Transparency=0.5
    glow.Parent=part
    local bill=Instance.new("BillboardGui")
    bill.Size=UDim2.new(0,200,0,50)
    bill.AlwaysOnTop=true
    bill.StudsOffset=Vector3.new(0,3,0)
    bill.Parent=part
    local label=Instance.new("TextLabel")
    label.Size=UDim2.new(1,0,1,0)
    label.BackgroundTransparency=1
    label.Text=name
    label.TextColor3=Color3.new(color or Color3.fromRGB(255,255,255))
    label.TextScaled=true
    label.Parent=bill
    part.Parent=workspace
    debris:AddItem(part,60)
    return part
end
local function spawnFruit(fruitName,position)
    position=position or rootPart.Position+Vector3.new(0,5,0)
    local part=Instance.new("Part")
    part.Size=Vector3.new(2,2,2)
    part.Position=position
    part.Anchored=true
    part.CanCollide=false
    part.BrickColor=BrickColor.new("Bright yellow")
    part.Name=fruitName.."Fruit"
    local tag=Instance.new("StringValue")
    tag.Name="FruitTag"
    tag.Value=fruitName
    tag.Parent=part
    local rarity=getFruitRarity(fruitName)
    local color=rarityColors[rarity] or Color3.fromRGB(255,255,0)
    local rarityLabel=Instance.new("StringValue")
    rarityLabel.Name="Rarity"
    rarityLabel.Value=rarity
    rarityLabel.Parent=part
    local glow=Instance.new("SelectionBox")
    glow.Adornee=part
    glow.Color3=color
    glow.Transparency=0.3
    glow.Parent=part
    local bill=Instance.new("BillboardGui")
    bill.Size=UDim2.new(0,150,0,40)
    bill.AlwaysOnTop=true
    bill.StudsOffset=Vector3.new(0,2.5,0)
    bill.Parent=part
    local label=Instance.new("TextLabel")
    label.Size=UDim2.new(1,0,1,0)
    label.BackgroundTransparency=1
    label.Text=fruitName.." ["..rarity.."]"
    label.TextColor3=color
    label.TextScaled=true
    label.Font=Enum.Font.GothamBold
    label.Parent=bill
    part.Parent=workspace
    debris:AddItem(part,90)
    return part
end
local function spawnWeapon(weaponName,position)
    position=position or rootPart.Position+Vector3.new(0,5,0)
    local part=Instance.new("Part")
    part.Size=Vector3.new(3,1,1)
    part.Position=position
    part.Anchored=true
    part.CanCollide=false
    part.BrickColor=BrickColor.new("Bright blue")
    part.Name=weaponName.."Weapon"
    local tag=Instance.new("StringValue")
    tag.Name="WeaponTag"
    tag.Value=weaponName
    tag.Parent=part
    local rarity=getWeaponRarity(weaponName)
    local color=rarityColors[rarity] or Color3.fromRGB(0,100,255)
    local rarityLabel=Instance.new("StringValue")
    rarityLabel.Name="Rarity"
    rarityLabel.Value=rarity
    rarityLabel.Parent=part
    local glow=Instance.new("SelectionBox")
    glow.Adornee=part
    glow.Color3=color
    glow.Transparency=0.3
    glow.Parent=part
    local bill=Instance.new("BillboardGui")
    bill.Size=UDim2.new(0,150,0,40)
    bill.AlwaysOnTop=true
    bill.StudsOffset=Vector3.new(0,2.5,0)
    bill.Parent=part
    local label=Instance.new("TextLabel")
    label.Size=UDim2.new(1,0,1,0)
    label.BackgroundTransparency=1
    label.Text=weaponName.." ["..rarity.."]"
    label.TextColor3=color
    label.TextScaled=true
    label.Font=Enum.Font.GothamBold
    label.Parent=bill
    part.Parent=workspace
    debris:AddItem(part,60)
    return part
end
local function spawnMoney(amount,position)
    position=position or rootPart.Position+Vector3.new(0,5,0)
    local part=Instance.new("Part")
    part.Size=Vector3.new(1,1,1)
    part.Position=position
    part.Anchored=true
    part.CanCollide=false
    part.BrickColor=BrickColor.new("Bright green")
    part.Name="MoneyDrop"
    local tag=Instance.new("NumberValue")
    tag.Name="MoneyTag"
    tag.Value=amount
    tag.Parent=part
    local bill=Instance.new("BillboardGui")
    bill.Size=UDim2.new(0,100,0,30)
    bill.AlwaysOnTop=true
    bill.StudsOffset=Vector3.new(0,2,0)
    bill.Parent=part
    local label=Instance.new("TextLabel")
    label.Size=UDim2.new(1,0,1,0)
    label.BackgroundTransparency=1
    label.Text="$"..tostring(amount)
    label.TextColor3=Color3.fromRGB(0,255,0)
    label.TextScaled=true
    label.Parent=bill
    part.Parent=workspace
    debris:AddItem(part,30)
    return part
end
local function spawnChest(position,rarity)
    rarity=rarity or "Common"
    position=position or rootPart.Position+Vector3.new(0,5,0)
    local part=Instance.new("Part")
    part.Size=Vector3.new(4,3,4)
    part.Position=position
    part.Anchored=true
    part.CanCollide=false
    part.BrickColor=BrickColor.new("Brown")
    part.Name="Chest"
    local tag=Instance.new("StringValue")
    tag.Name="ChestTag"
    tag.Value=rarity
    tag.Parent=part
    local color=rarityColors[rarity] or Color3.fromRGB(200,200,200)
    local glow=Instance.new("SelectionBox")
    glow.Adornee=part
    glow.Color3=color
    glow.Transparency=0.4
    glow.Parent=part
    local bill=Instance.new("BillboardGui")
    bill.Size=UDim2.new(0,200,0,50)
    bill.AlwaysOnTop=true
    bill.StudsOffset=Vector3.new(0,3,0)
    bill.Parent=part
    local label=Instance.new("TextLabel")
    label.Size=UDim2.new(1,0,1,0)
    label.BackgroundTransparency=1
    label.Text="Chest ["..rarity.."]"
    label.TextColor3=color
    label.TextScaled=true
    label.Parent=bill
    local anim=Instance.new("Animation")
    -- giả lập animation
    part.Parent=workspace
    debris:AddItem(part,120)
    return part
end
local function collectItemPart(part,filter)
    if not part or not rootPart then return false end
    local dist=getDistance(rootPart.Position,part.Position)
    if dist<5 then
        if filter=="All" or filter=="Fruit" and part:FindFirstChild("FruitTag") then
            part:Destroy()
            return true
        elseif filter=="Weapon" and part:FindFirstChild("WeaponTag") then
            part:Destroy()
            return true
        elseif filter=="Money" and part:FindFirstChild("MoneyTag") then
            part:Destroy()
            return true
        elseif filter=="All" then
            part:Destroy()
            return true
        end
    else
        if dist<100 then
            local tweenInfo=TweenInfo.new(dist/80,Enum.EasingStyle.Linear)
            local tween=tweenService:Create(rootPart,tweenInfo,{CFrame=CFrame.new(part.Position+Vector3.new(0,2,0))})
            tween:Play()
            wait(0.1)
        end
    end
    return false
end
local function autoCollectAll(data)
    local radius=data.collectRadius or 2000
    local filter=data.collectFilter or "All"
    local count=0
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Part") and v:FindFirstChild("TouchInterest") then
            if v:FindFirstChild("FruitTag") or v:FindFirstChild("WeaponTag") or v:FindFirstChild("MoneyTag") or v:FindFirstChild("ItemTag") then
                local dist=getDistance(rootPart.Position,v.Position)
                if dist<radius then
                    if collectItemPart(v,filter) then
                        count=count+1
                    end
                end
            end
        end
    end
    return count
end
local function startAutoCollect(data)
    isRunning=true
    task.spawn(function()
        while isRunning do
            wait(0.5)
            pcall(function()autoCollectAll(data)end)
        end
    end)
end
local function getPlayerInventory()
    local inv={}
    local folder=player:FindFirstChild("Inventory")
    if folder then
        for _,v in pairs(folder:GetChildren()) do
            if v:IsA("StringValue") or v:IsA("NumberValue") or v:IsA("IntValue") then
                table.insert(inv,{name=v.Name,value=v.Value})
            end
        end
    end
    return inv
end
local function getPlayerMoney()
    local money=player:FindFirstChild("Money")
    if money and money:IsA("NumberValue") then
        return money.Value
    end
    return 0
end
local function getPlayerGems()
    local gems=player:FindFirstChild("Gems")
    if gems and gems:IsA("NumberValue") then
        return gems.Value
    end
    return 0
end
local function addToInventory(itemName,value)
    local folder=player:FindFirstChild("Inventory")
    if not folder then
        folder=Instance.new("Folder")
        folder.Name="Inventory"
        folder.Parent=player
    end
    local item=Instance.new("StringValue")
    item.Name=itemName
    item.Value=tostring(value or "")
    item.Parent=folder
    return true
end
local function removeFromInventory(itemName)
    local folder=player:FindFirstChild("Inventory")
    if folder then
        local item=folder:FindFirstChild(itemName)
        if item then
            item:Destroy()
            return true
        end
    end
    return false
end
local function clearInventory()
    local folder=player:FindFirstChild("Inventory")
    if folder then
        for _,v in pairs(folder:GetChildren()) do
            v:Destroy()
        end
        return true
    end
    return false
end
local function getFruitsInInventory()
    local list={}
    local folder=player:FindFirstChild("Inventory")
    if folder then
        for _,v in pairs(folder:GetChildren()) do
            if v:IsA("StringValue") and v.Name:match("Fruit") then
                table.insert(list,v.Name)
            end
        end
    end
    return list
end
local function getWeaponsInInventory()
    local list={}
    local folder=player:FindFirstChild("Inventory")
    if folder then
        for _,v in pairs(folder:GetChildren()) do
            if v:IsA("StringValue") and v.Name:match("Weapon") then
                table.insert(list,v.Name)
            end
        end
    end
    return list
end
local function spawnRandomFruit()
    local fruit=fruitList[math.random(1,#fruitList)]
    return spawnFruit(fruit)
end
local function spawnRandomWeapon()
    local weapon=weaponList[math.random(1,#weaponList)]
    return spawnWeapon(weapon)
end
local function spawnRandomChest()
    local rarities={"Common","Uncommon","Rare","Legendary","Mythical"}
    local rarity=rarities[math.random(1,#rarities)]
    return spawnChest(rootPart.Position+Vector3.new(0,5,0),rarity)
end
local function spawnRandomItem()
    local item=itemList[math.random(1,#itemList)]
    return spawnPart(item,rootPart.Position+Vector3.new(0,5,0),Color3.fromRGB(255,255,255),2,item)
end
function items.Stop()
    isRunning=false
    return true
end
function items.Run(data)
    if not data then return false end
    dataRef=data
    if data.autoCollect and not isRunning then
        startAutoCollect(data)
    elseif not data.autoCollect and isRunning then
        items.Stop()
    end
    return true
end
function items.Initialize(data)
    dataRef=data
    updateCharacter()
    return true
end
function items.SpawnFruit(fruitName,position)
    return spawnFruit(fruitName,position)
end
function items.SpawnWeapon(weaponName,position)
    return spawnWeapon(weaponName,position)
end
function items.SpawnMoney(amount,position)
    return spawnMoney(amount,position)
end
function items.SpawnChest(position,rarity)
    return spawnChest(position,rarity)
end
function items.SpawnItem(itemName,position)
    return spawnPart(itemName,position,Color3.fromRGB(255,255,255),2,itemName)
end
function items.SpawnRandomFruit()
    return spawnRandomFruit()
end
function items.SpawnRandomWeapon()
    return spawnRandomWeapon()
end
function items.SpawnRandomChest()
    return spawnRandomChest()
end
function items.SpawnRandomItem()
    return spawnRandomItem()
end
function items.AutoCollect(data)
    if not data then data=dataRef end
    if not data or not data.autoCollect then return 0 end
    return autoCollectAll(data)
end
function items.ToggleAutoCollect()
    if dataRef then
        dataRef.autoCollect=not dataRef.autoCollect
        if dataRef.autoCollect then
            startAutoCollect(dataRef)
        else
            isRunning=false
        end
        return dataRef.autoCollect
    end
    return false
end
function items.SetCollectRadius(radius)
    if dataRef then
        dataRef.collectRadius=radius
        return true
    end
    return false
end
function items.SetCollectFilter(filter)
    if dataRef then
        dataRef.collectFilter=filter
        return true
    end
    return false
end
function items.GetInventory()
    return getPlayerInventory()
end
function items.GetMoney()
    return getPlayerMoney()
end
function items.GetGems()
    return getPlayerGems()
end
function items.AddToInventory(itemName,value)
    return addToInventory(itemName,value)
end
function items.RemoveFromInventory(itemName)
    return removeFromInventory(itemName)
end
function items.ClearInventory()
    return clearInventory()
end
function items.GetFruitsInInventory()
    return getFruitsInInventory()
end
function items.GetWeaponsInInventory()
    return getWeaponsInInventory()
end
function items.GetFruitList()
    return fruitList
end
function items.GetWeaponList()
    return weaponList
end
function items.GetItemList()
    return itemList
end
function items.GetFruitRarity(fruitName)
    return getFruitRarity(fruitName)
end
function items.GetWeaponRarity(weaponName)
    return getWeaponRarity(weaponName)
end
function items.CollectNearestFruit(radius)
    radius=radius or 100
    local nearest=nil
    local minDist=math.huge
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Part") and v:FindFirstChild("FruitTag") then
            local dist=getDistance(rootPart.Position,v.Position)
            if dist<radius and dist<minDist then
                minDist=dist
                nearest=v
            end
        end
    end
    if nearest then
        return collectItemPart(nearest,"Fruit")
    end
    return false
end
function items.CollectNearestWeapon(radius)
    radius=radius or 100
    local nearest=nil
    local minDist=math.huge
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Part") and v:FindFirstChild("WeaponTag") then
            local dist=getDistance(rootPart.Position,v.Position)
            if dist<radius and dist<minDist then
                minDist=dist
                nearest=v
            end
        end
    end
    if nearest then
        return collectItemPart(nearest,"Weapon")
    end
    return false
end
function items.CollectNearestMoney(radius)
    radius=radius or 100
    local nearest=nil
    local minDist=math.huge
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Part") and v:FindFirstChild("MoneyTag") then
            local dist=getDistance(rootPart.Position,v.Position)
            if dist<radius and dist<minDist then
                minDist=dist
                nearest=v
            end
        end
    end
    if nearest then
        return collectItemPart(nearest,"Money")
    end
    return false
end
function items.CollectAllInRadius(radius)
    radius=radius or 500
    local count=0
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Part") and v:FindFirstChild("TouchInterest") then
            local dist=getDistance(rootPart.Position,v.Position)
            if dist<radius then
                if collectItemPart(v,"All") then count=count+1 end
            end
        end
    end
    return count
end
function items.DropItem(itemName,value)
    local pos=rootPart.Position+Vector3.new(0,3,0)
    return spawnPart(itemName,pos,Color3.fromRGB(255,200,100),2,value)
end
function items.DropFruit(fruitName)
    local pos=rootPart.Position+Vector3.new(0,3,0)
    return spawnFruit(fruitName,pos)
end
function items.DropWeapon(weaponName)
    local pos=rootPart.Position+Vector3.new(0,3,0)
    return spawnWeapon(weaponName,pos)
end
function items.DropMoney(amount)
    local pos=rootPart.Position+Vector3.new(0,3,0)
    return spawnMoney(amount,pos)
end
function items.GetStatus()
    return{
        isRunning=isRunning,
        autoCollect=dataRef and dataRef.autoCollect or false,
        collectRadius=dataRef and dataRef.collectRadius or 2000,
        collectFilter=dataRef and dataRef.collectFilter or "All",
        inventorySize=#getPlayerInventory()
    }
end
function items.Pause()
    isRunning=false
    return true
end
function items.Resume()
    if dataRef and dataRef.autoCollect then
        isRunning=true
        startAutoCollect(dataRef)
        return true
    end
    return false
end
function items.Destroy()
    isRunning=false
    dataRef=nil
    collectedItems={}
    return true
end
return items
