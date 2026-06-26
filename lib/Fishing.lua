local fishing={}
fishing.__index=fishing
local player=game.Players.LocalPlayer
local runService=game:GetService("RunService")
local userInput=game:GetService("UserInputService")
local workspace=game:GetService("Workspace")
local players=game:GetService("Players")
local tweenService=game:GetService("TweenService")
local debris=game:GetService("Debris")
local collectionService=game:GetService("CollectionService")
local replicatedStorage=game:GetService("ReplicatedStorage")
local character=nil local humanoid=nil local rootPart=nil
local dataRef=nil local isRunning=false
local fishingSpot=nil local baitCount=0 local fishCaught=0
local fishingTimer=0 local castTime=0 local reelTime=0
local isCasting=false local isReeling=false local fishOnHook=false
local fishTypes={}
local fishRarity={}
local fishList={
    Common={"Tuna","Salmon","Cod","Trout","Bass"},
    Uncommon={"Red Snapper","Mackerel","Perch","Catfish","Pike"},
    Rare={"Kingfish","Marlin","Swordfish","Barracuda","Sturgeon"},
    Legendary={"Golden Carp","Dragon Fish","Sea Serpent","Kraken","Leviathan"},
    Mythical={"Moby Dick","Nessie","Cthulhu","Poseidon","Neptune"}
}
local fishWeights={
    Common=1,Uncommon=2,Rare=3,Legendary=4,Mythical=5
}
local fishPrices={
    Common=50,Uncommon=100,Rare=250,Legendary=500,Mythical=1000
}
local fishingSpots={}
local currentSpotIndex=1
local autoCast=true
local autoReel=true
local autoMove=true
local moveRadius=50
local fishCaughtList={}
local totalFishWeight=0
local fishingExp=0
local fishingLevel=1
local fishingExpToNext=100
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
local function findNearestFishingSpot()
    local nearest=nil
    local minDist=math.huge
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Model") and v:FindFirstChild("Head") then
            if v.Name:lower():match("fishing") or v.Name:lower():match("spot") then
                local pos=v.Head.Position
                local dist=getDistance(rootPart.Position,pos)
                if dist<minDist then
                    minDist=dist
                    nearest=v
                end
            end
        end
        if v:IsA("Part") and v.Name:lower():match("fishing") then
            local dist=getDistance(rootPart.Position,v.Position)
            if dist<minDist then
                minDist=dist
                nearest=v
            end
        end
    end
    return nearest
end
local function moveToFishingSpot(spot)
    if not spot or not rootPart then return false end
    local targetPos
    if spot:IsA("Model") and spot:FindFirstChild("Head") then
        targetPos=spot.Head.Position+Vector3.new(0,2,0)
    elseif spot:IsA("Part") then
        targetPos=spot.Position+Vector3.new(0,2,0)
    else
        return false
    end
    local dist=getDistance(rootPart.Position,targetPos)
    if dist>3 then
        local tweenInfo=TweenInfo.new(dist/20,Enum.EasingStyle.Linear)
        local tween=tweenService:Create(rootPart,tweenInfo,{CFrame=CFrame.new(targetPos)})
        tween:Play()
        return true
    end
    return true
end
local function castFishingLine()
    if isCasting then return false end
    isCasting=true
    castTime=tick()
    local line=Instance.new("Part")
    line.Size=Vector3.new(0.1,0.1,10)
    line.Position=rootPart.Position+Vector3.new(0,2,0)+rootPart.CFrame.LookVector*5
    line.Anchored=true
    line.CanCollide=false
    line.BrickColor=BrickColor.new("Bright blue")
    line.Transparency=0.5
    line.Parent=workspace
    local bobber=Instance.new("Part")
    bobber.Size=Vector3.new(1,1,1)
    bobber.Position=line.Position+Vector3.new(0,0,5)
    bobber.Anchored=true
    bobber.CanCollide=false
    bobber.BrickColor=BrickColor.new("Bright red")
    bobber.Parent=workspace
    local splash=Instance.new("Part")
    splash.Size=Vector3.new(2,0.2,2)
    splash.Position=bobber.Position+Vector3.new(0,-0.5,0)
    splash.Anchored=true
    splash.CanCollide=false
    splash.BrickColor=BrickColor.new("White")
    splash.Transparency=0.5
    splash.Parent=workspace
    debris:AddItem(line,5)
    debris:AddItem(bobber,5)
    debris:AddItem(splash,5)
    isCasting=false
    fishOnHook=false
    return true
end
local function reelFishingLine()
    if isReeling then return false end
    if not fishOnHook then return false end
    isReeling=true
    reelTime=tick()
    local waitTime=math.random(1,3)
    task.wait(waitTime)
    local fishRarityRoll=math.random(1,100)
    local rarity
    if fishRarityRoll<=50 then rarity="Common"
    elseif fishRarityRoll<=75 then rarity="Uncommon"
    elseif fishRarityRoll<=90 then rarity="Rare"
    elseif fishRarityRoll<=98 then rarity="Legendary"
    else rarity="Mythical" end
    local fishTable=fishList[rarity]
    local fishName=fishTable[math.random(1,#fishTable)]
    local weight=math.random(1,10)+fishWeights[rarity]*2
    local price=fishPrices[rarity]*(1+math.random(0,50)/100)
    local fishData={
        name=fishName,
        rarity=rarity,
        weight=weight,
        price=math.floor(price),
        time=os.time()
    }
    table.insert(fishCaughtList,fishData)
    fishCaught=fishCaught+1
    totalFishWeight=totalFishWeight+weight
    fishingExp=fishingExp+fishWeights[rarity]*10
    if fishingExp>=fishingExpToNext then
        fishingExp=fishingExp-fishingExpToNext
        fishingLevel=fishingLevel+1
        fishingExpToNext=math.floor(fishingExpToNext*1.2)
    end
    fishOnHook=false
    isReeling=false
    return true
end
local function checkFishBite()
    if not fishOnHook and not isCasting and not isReeling then
        if math.random()<0.05 then
            fishOnHook=true
            return true
        end
    end
    return false
end
local function autoFishing(data)
    if not rootPart or not humanoid then updateCharacter() end
    if not rootPart or not humanoid then return end
    fishingTimer=fishingTimer+0.1
    if not fishingSpot or not fishingSpot.Parent then
        fishingSpot=findNearestFishingSpot()
        if not fishingSpot then return end
    end
    if autoMove and getDistance(rootPart.Position,fishingSpot.Position)>3 then
        moveToFishingSpot(fishingSpot)
        return
    end
    if autoCast and not isCasting and not isReeling and not fishOnHook then
        castFishingLine()
        return
    end
    if fishOnHook and autoReel then
        reelFishingLine()
        return
    end
    if not fishOnHook and not isCasting and fishingTimer%5==0 then
        checkFishBite()
    end
end
local function startFishingLoop(data)
    if isRunning then return end
    isRunning=true
    task.spawn(function()
        while isRunning do
            wait(0.1)
            pcall(function()autoFishing(data)end)
        end
    end)
end
function fishing.Stop()
    isRunning=false
    return true
end
function fishing.Run(data)
    if not data then return false end
    dataRef=data
    if not data.enabled then
        if isRunning then fishing.Stop() end
        return false
    end
    if not isRunning then
        startFishingLoop(data)
    end
    return true
end
function fishing.SetAutoCast(enabled)
    if dataRef then dataRef.autoCast=enabled end
    autoCast=enabled
    return true
end
function fishing.SetAutoReel(enabled)
    if dataRef then dataRef.autoReel=enabled end
    autoReel=enabled
    return true
end
function fishing.SetAutoMove(enabled)
    if dataRef then dataRef.autoMove=enabled end
    autoMove=enabled
    return true
end
function fishing.SetMoveRadius(radius)
    if dataRef then dataRef.moveRadius=radius end
    moveRadius=radius
    return true
end
function fishing.GetStatus()
    return{
        isRunning=isRunning,
        fishCaught=fishCaught,
        totalFishWeight=totalFishWeight,
        fishingLevel=fishingLevel,
        fishingExp=fishingExp,
        expToNext=fishingExpToNext,
        baitCount=baitCount,
        fishOnHook=fishOnHook,
        isCasting=isCasting,
        isReeling=isReeling,
        currentSpot=fishingSpot and fishingSpot.Name or "None"
    }
end
function fishing.GetFishCaught()
    return fishCaughtList
end
function fishing.ClearFishCaught()
    fishCaughtList={}
    return true
end
function fishing.GetFishTypes()
    return fishList
end
function fishing.GetFishPrices()
    return fishPrices
end
function fishing.GetFishWeights()
    return fishWeights
end
function fishing.CastLine()
    return castFishingLine()
end
function fishing.ReelLine()
    return reelFishingLine()
end
function fishing.MoveToNearestSpot()
    local spot=findNearestFishingSpot()
    if spot then
        return moveToFishingSpot(spot)
    end
    return false
end
function fishing.SetBaitCount(count)
    baitCount=count
    return true
end
function fishing.AddBait(amount)
    baitCount=baitCount+amount
    return true
end
function fishing.GetBaitCount()
    return baitCount
end
function fishing.GetTotalFish()
    return fishCaught
end
function fishing.GetTotalWeight()
    return totalFishWeight
end
function fishing.GetLevel()
    return fishingLevel
end
function fishing.GetExp()
    return fishingExp
end
function fishing.GetExpToNext()
    return fishingExpToNext
end
function fishing.GetFishPrice(fishName,rarity)
    local r=rarity or "Common"
    return fishPrices[r] or 50
end
function fishing.GetFishWeight(fishName,rarity)
    local r=rarity or "Common"
    local base=fishWeights[r] or 1
    return math.random(1,10)+base*2
end
function fishing.CalculateTotalPrice()
    local total=0
    for _,fish in ipairs(fishCaughtList) do
        total=total+fish.price
    end
    return total
end
function fishing.SellAllFish()
    local total=0
    for _,fish in ipairs(fishCaughtList) do
        total=total+fish.price
    end
    fishCaughtList={}
    fishCaught=0
    totalFishWeight=0
    return total
end
function fishing.AddFishToInventory(fishData)
    table.insert(fishCaughtList,fishData)
    fishCaught=fishCaught+1
    totalFishWeight=totalFishWeight+fishData.weight
    return true
end
function fishing.GetFishByRarity(rarity)
    local result={}
    for _,fish in ipairs(fishCaughtList) do
        if fish.rarity==rarity then
            table.insert(result,fish)
        end
    end
    return result
end
function fishing.GetFishByName(name)
    local result={}
    for _,fish in ipairs(fishCaughtList) do
        if fish.name==name then
            table.insert(result,fish)
        end
    end
    return result
end
function fishing.GetRarestFish()
    local rarest=nil
    local maxRarity=-1
    local rarityOrder={Common=1,Uncommon=2,Rare=3,Legendary=4,Mythical=5}
    for _,fish in ipairs(fishCaughtList) do
        local r=rarityOrder[fish.rarity] or 0
        if r>maxRarity then
            maxRarity=r
            rarest=fish
        end
    end
    return rarest
end
function fishing.GetHeaviestFish()
    local heaviest=nil
    local maxWeight=0
    for _,fish in ipairs(fishCaughtList) do
        if fish.weight>maxWeight then
            maxWeight=fish.weight
            heaviest=fish
        end
    end
    return heaviest
end
function fishing.GetAverageWeight()
    if #fishCaughtList==0 then return 0 end
    local total=0
    for _,fish in ipairs(fishCaughtList) do
        total=total+fish.weight
    end
    return total/#fishCaughtList
end
function fishing.GetTotalPrice()
    return fishing.CalculateTotalPrice()
end
function fishing.ResetFishing()
    fishCaught=0
    totalFishWeight=0
    fishCaughtList={}
    fishingExp=0
    fishingLevel=1
    fishingExpToNext=100
    baitCount=0
    fishOnHook=false
    isCasting=false
    isReeling=false
    return true
end
function fishing.SetFishingSpot(spot)
    fishingSpot=spot
    return true
end
function fishing.FindAllFishingSpots()
    local spots={}
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Model") and v:FindFirstChild("Head") then
            if v.Name:lower():match("fishing") or v.Name:lower():match("spot") then
                table.insert(spots,v)
            end
        end
        if v:IsA("Part") and v.Name:lower():match("fishing") then
            table.insert(spots,v)
        end
    end
    return spots
end
function fishing.MoveToSpot(spot)
    return moveToFishingSpot(spot)
end
function fishing.SetFishTypeRarity(fishType,rarity)
    fishRarity[fishType]=rarity
    return true
end
function fishing.GetFishTypeRarity(fishType)
    return fishRarity[fishType] or "Common"
end
function fishing.AddFishType(name,rarity)
    if not fishList[rarity] then fishList[rarity]={} end
    table.insert(fishList[rarity],name)
    return true
end
function fishing.RemoveFishType(name)
    for r,list in pairs(fishList) do
        for i,v in ipairs(list) do
            if v==name then
                table.remove(list,i)
                return true
            end
        end
    end
    return false
end
function fishing.GetAllFishNames()
    local names={}
    for _,list in pairs(fishList) do
        for _,name in ipairs(list) do
            table.insert(names,name)
        end
    end
    return names
end
function fishing.IsFishAvailable(name)
    for _,list in pairs(fishList) do
        for _,v in ipairs(list) do
            if v==name then return true end
        end
    end
    return false
end
function fishing.GetFishCountByRarity(rarity)
    local count=0
    for _,fish in ipairs(fishCaughtList) do
        if fish.rarity==rarity then count=count+1 end
    end
    return count
end
function fishing.GetTotalFishByRarity()
    local result={}
    for r,_ in pairs(fishList) do
        result[r]=fishing.GetFishCountByRarity(r)
    end
    return result
end
function fishing.GetFishStatistics()
    return{
        totalCaught=fishCaught,
        totalWeight=totalFishWeight,
        averageWeight=fishing.GetAverageWeight(),
        rarest=fishing.GetRarestFish(),
        heaviest=fishing.GetHeaviestFish(),
        totalPrice=fishing.GetTotalPrice(),
        level=fishingLevel,
        exp=fishingExp,
        expToNext=fishingExpToNext
    }
end
function fishing.SellFishByRarity(rarity)
    local total=0
    local newList={}
    for _,fish in ipairs(fishCaughtList) do
        if fish.rarity==rarity then
            total=total+fish.price
        else
            table.insert(newList,fish)
        end
    end
    fishCaughtList=newList
    fishCaught=#newList
    return total
end
function fishing.SellFishByName(name)
    local total=0
    local newList={}
    for _,fish in ipairs(fishCaughtList) do
        if fish.name==name then
            total=total+fish.price
        else
            table.insert(newList,fish)
        end
    end
    fishCaughtList=newList
    fishCaught=#newList
    return total
end
function fishing.SellAllCommonFish()
    return fishing.SellFishByRarity("Common")
end
function fishing.SellAllUncommonFish()
    return fishing.SellFishByRarity("Uncommon")
end
function fishing.SellAllRareFish()
    return fishing.SellFishByRarity("Rare")
end
function fishing.SellAllLegendaryFish()
    return fishing.SellFishByRarity("Legendary")
end
function fishing.SellAllMythicalFish()
    return fishing.SellFishByRarity("Mythical")
end
function fishing.ClearAllFish()
    return fishing.ResetFishing()
end
function fishing.ExportFishData()
    return httpService:JSONEncode({
        fishCaught=fishCaught,
        totalWeight=totalFishWeight,
        level=fishingLevel,
        exp=fishingExp,
        fishList=fishCaughtList
    })
end
function fishing.ImportFishData(json)
    local success,data=pcall(function()return httpService:JSONDecode(json)end)
    if success and data then
        if data.fishCaught then fishCaught=data.fishCaught end
        if data.totalWeight then totalFishWeight=data.totalWeight end
        if data.level then fishingLevel=data.level end
        if data.exp then fishingExp=data.exp end
        if data.fishList then fishCaughtList=data.fishList end
        return true
    end
    return false
end
function fishing.Pause()
    isRunning=false
    return true
end
function fishing.Resume()
    if dataRef and dataRef.enabled then
        isRunning=true
        startFishingLoop(dataRef)
        return true
    end
    return false
end
function fishing.Destroy()
    isRunning=false
    fishCaughtList={}
    fishCaught=0
    totalFishWeight=0
    fishingLevel=1
    fishingExp=0
    fishingExpToNext=100
    baitCount=0
    dataRef=nil
    return true
end
function fishing.Initialize(data)
    dataRef=data
    updateCharacter()
    if data then
        if data.autoCast~=nil then autoCast=data.autoCast end
        if data.autoReel~=nil then autoReel=data.autoReel end
        if data.autoMove~=nil then autoMove=data.autoMove end
        if data.moveRadius then moveRadius=data.moveRadius end
        if data.fishList then
            for r,list in pairs(data.fishList) do
                if fishList[r] then
                    for _,name in ipairs(list) do
                        table.insert(fishList[r],name)
                    end
                end
            end
        end
    end
    return true
end
return fishing
