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
local httpService=game:GetService("HttpService")
local character=nil local humanoid=nil local rootPart=nil
local dataRef=nil local isRunning=false
local fishingSpot=nil local baitCount=0 local fishCaught=0
local fishingTimer=0 local castTime=0 local reelTime=0
local isCasting=false local isReeling=false local fishOnHook=false
local fishingLevel=0 local fishingExp=0 local fishingExpToNext=100
local totalFishWeight=0 local fishCaughtList={}
local currentRod="Fishing Rod" local currentBait="Basic Bait"
local rodsUnlocked={"Fishing Rod"}
local baitsUnlocked={"Basic Bait"}
local anglerTrust=0
local FISH_DATA={
    -- Common (Main World, Sea 1, 2, 3)
    {name="Catfish", rarity="Common", locations={"Any"}, baits={"Basic","Kelp","Good"}, minWeight=3, maxWeight=37, exp=10, price=50},
    {name="Carp", rarity="Common", locations={"Any"}, baits={"Basic","Kelp","Good"}, minWeight=2, maxWeight=19, exp=8, price=40},
    {name="Redfin", rarity="Common", locations={"Any"}, baits={"Basic","Kelp","Good"}, minWeight=4, maxWeight=30, exp=10, price=45},
    {name="Tidegill", rarity="Common", locations={"Any"}, baits={"Basic","Kelp","Good"}, minWeight=3, maxWeight=27, exp=9, price=42},
    {name="Saltwater Salmon", rarity="Common", locations={"Any"}, baits={"Basic","Kelp","Good"}, minWeight=5, maxWeight=40, exp=12, price=55},
    {name="Goldfish", rarity="Common", locations={"Any"}, baits={"Basic","Kelp","Good"}, minWeight=2, maxWeight=20, exp=8, price=35},
    {name="Mossback", rarity="Common", locations={"Any"}, baits={"Basic","Kelp","Good"}, minWeight=5, maxWeight=38, exp=11, price=50},
    {name="Grouper", rarity="Common", locations={"Any"}, baits={"Basic","Kelp","Good"}, minWeight=4, maxWeight=44, exp=12, price=55},
    {name="Tuna", rarity="Common", locations={"Any"}, baits={"Basic","Kelp","Good"}, minWeight=6, maxWeight=50, exp=14, price=60},
    {name="Sand Bass", rarity="Common", locations={"Any"}, baits={"Basic","Kelp","Good"}, minWeight=3, maxWeight=25, exp=9, price=40},
    {name="Crab", rarity="Common", locations={"Any"}, baits={"Basic","Kelp","Good"}, minWeight=2, maxWeight=15, exp=7, price=30},
    {name="Sea Sturgeon", rarity="Common", locations={"Any"}, baits={"Basic","Kelp","Good"}, minWeight=8, maxWeight=55, exp=15, price=65},
    -- Uncommon
    {name="Angelfish", rarity="Uncommon", locations={"Any"}, baits={"Basic","Kelp","Good"}, minWeight=6, maxWeight=46, exp=20, price=100},
    {name="Flatfish", rarity="Uncommon", locations={"Any"}, baits={"Basic","Kelp","Good"}, minWeight=7, maxWeight=50, exp=22, price=110},
    {name="Kelp Bass", rarity="Uncommon", locations={"Any"}, baits={"Basic","Kelp","Good"}, minWeight=5, maxWeight=42, exp=18, price=90},
    {name="Clownfish", rarity="Uncommon", locations={"Any"}, baits={"Basic","Kelp","Good"}, minWeight=3, maxWeight=25, exp=15, price=75},
    {name="Amber Trout", rarity="Uncommon", locations={"Any"}, baits={"Basic","Kelp","Good"}, minWeight=4, maxWeight=35, exp=17, price=85},
    {name="Colossal Shrimp", rarity="Uncommon", locations={"Any"}, baits={"Basic","Kelp","Good"}, minWeight=5, maxWeight=40, exp=19, price=95},
    {name="Pufferfish", rarity="Uncommon", locations={"Any"}, baits={"Basic","Kelp","Good"}, minWeight=3, maxWeight=28, exp=16, price=80},
    {name="Barracuda", rarity="Uncommon", locations={"Any"}, baits={"Basic","Kelp","Good"}, minWeight=6, maxWeight=45, exp=21, price=105},
    {name="Bullfish", rarity="Uncommon", locations={"Prehistoric Island"}, baits={"Kelp","Good","Epic"}, minWeight=8, maxWeight=55, exp=25, price=130},
    {name="Parrotfish", rarity="Uncommon", locations={"Green Zone","Tiki Outpost"}, baits={"Basic","Kelp","Good"}, minWeight=4, maxWeight=32, exp=16, price=80},
    -- Rare
    {name="Candyfish", rarity="Rare", locations={"Sea of Treats"}, baits={"Basic","Kelp","Good"}, minWeight=6, maxWeight=47, exp=35, price=200},
    {name="Ghostfish", rarity="Rare", locations={"Cursed Ship","Haunted Castle","Haunted Shipwreck","Mirage Island"}, baits={"Abyssal"}, minWeight=5, maxWeight=40, exp=40, price=250},
    {name="Gliderfish", rarity="Rare", locations={"Any"}, baits={"Basic","Kelp","Good"}, minWeight=5, maxWeight=42, exp=30, price=180},
    {name="Sea Horse", rarity="Rare", locations={"Any"}, baits={"Basic","Kelp","Good"}, minWeight=4, maxWeight=38, exp=28, price=170},
    {name="Leafy Trout", rarity="Rare", locations={"Green Zone"}, baits={"Basic","Kelp","Good"}, minWeight=4, maxWeight=36, exp=30, price=180},
    {name="Molten Trout", rarity="Rare", locations={"Prehistoric Island"}, baits={"Kelp","Good","Epic"}, minWeight=5, maxWeight=45, exp=35, price=220},
    {name="Crystal Fish", rarity="Rare", locations={"Frozen Dimension"}, baits={"Frozen","Epic"}, minWeight=6, maxWeight=50, exp=38, price=240},
    -- Legendary
    {name="Abyssal Serpent", rarity="Legendary", locations={"Sea of Treats","Frozen Dimension"}, baits={"Abyssal","Frozen","Epic"}, minWeight=10, maxWeight=80, exp=60, price=500},
    {name="Leviathan Spawn", rarity="Legendary", locations={"Frozen Dimension","Sea of Treats"}, baits={"Frozen","Carnivore"}, minWeight=15, maxWeight=100, exp=70, price=600},
    {name="Dragon Koi", rarity="Legendary", locations={"Prehistoric Island","Sea of Treats"}, baits={"Epic","Carnivore"}, minWeight=12, maxWeight=90, exp=65, price=550},
    {name="Celestial Fish", rarity="Legendary", locations={"Sky Island","Sea of Treats"}, baits={"Good","Epic"}, minWeight=8, maxWeight=70, exp=55, price=450},
    -- Mythical
    {name="Kraken Tentacle", rarity="Mythical", locations={"Sea of Treats","Frozen Dimension"}, baits={"Carnivore","Abyssal"}, minWeight=20, maxWeight=150, exp=100, price=1000},
    {name="Sea Emperor", rarity="Mythical", locations={"Sea of Treats","Prehistoric Island"}, baits={"Carnivore","Epic"}, minWeight=25, maxWeight=200, exp=120, price=1500},
    {name="Predator Fish", rarity="Mythical", locations={"Submerged Island","Sea of Treats"}, baits={"Carnivore","Abyssal"}, minWeight=18, maxWeight=130, exp=90, price=1200}
}
local ROD_DATA={
    {name="Fishing Rod", sea=1, requiredTrust=0, price=0, masteryBonus=1, catchRate=1},
    {name="Gold Rod", sea=1, requiredTrust=10, price=5000, masteryBonus=1.2, catchRate=1.3},
    {name="Shark Rod", sea=2, requiredTrust=15, price=15000, masteryBonus=1.5, catchRate=1.6},
    {name="Shell Rod", sea=3, requiredTrust=40, price=30000, masteryBonus=2.0, catchRate=2.0},
    {name="Treasure Rod", sea=3, requiredTrust=50, price=50000, masteryBonus=2.5, catchRate=2.5}
}
local BAIT_DATA={
    {name="Basic Bait", sea=1, requiredTrust=0, price=100, catchBonus=1, quantity=10},
    {name="Kelp Bait", sea=1, requiredTrust=3, price=300, catchBonus=1.3, quantity=10},
    {name="Good Bait", sea=1, requiredTrust=15, price=500, catchBonus=1.5, quantity=10},
    {name="Abyssal Bait", sea=2, requiredTrust=5, price=800, catchBonus=1.8, quantity=5},
    {name="Frozen Bait", sea=2, requiredTrust=20, price=1000, catchBonus=2.0, quantity=5},
    {name="Epic Bait", sea=3, requiredTrust=9, price=1500, catchBonus=2.3, quantity=3},
    {name="Carnivore Bait", sea=3, requiredTrust=13, price=2000, catchBonus=2.5, quantity=3}
}
local LOCATIONS={
    {name="Frozen Village", sea=1, pos=Vector3.new(-200,10,600)},
    {name="Sky Island", sea=1, pos=Vector3.new(200,200,0)},
    {name="Kingdom of Rose", sea=2, pos=Vector3.new(0,10,0)},
    {name="Green Zone", sea=2, pos=Vector3.new(300,10,400)},
    {name="Port Town", sea=3, pos=Vector3.new(0,10,0)},
    {name="Hydra Island", sea=3, pos=Vector3.new(200,20,300)},
    {name="Tiki Outpost", sea=3, pos=Vector3.new(400,15,500)},
    {name="Sea of Treats", sea=3, pos=Vector3.new(800,10,900)},
    {name="Prehistoric Island", sea=3, pos=Vector3.new(300,10,400)},
    {name="Frozen Dimension", sea=3, pos=Vector3.new(200,10,200)}
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
local function getPlayerLevel()
    local lvl=player:FindFirstChild("Level")
    if lvl and lvl:IsA("NumberValue") then return lvl.Value end
    return 0
end
local function getCurrentSea()
    local sea=player:FindFirstChild("CurrentSea")
    if sea and sea:IsA("NumberValue") then return sea.Value end
    return 1
end
local function findFishingSpot()
    local nearest=nil
    local minDist=math.huge
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Model") and v:FindFirstChild("Head") then
            if v.Name:lower():match("fishing") or v.Name:lower():match("dock") or v.Name:lower():match("spot") then
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
local function findFishermanNPC()
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Model") and v:FindFirstChild("Head") then
            if v.Name:lower():match("fisherman") then
                return v
            end
        end
    end
    return nil
end
local function findAnglerNPC()
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Model") and v:FindFirstChild("Head") then
            if v.Name:lower():match("angler") then
                return v
            end
        end
    end
    return nil
end
local function moveToPosition(pos,timeout)
    timeout=timeout or 10
    if not rootPart then return false end
    local dist=getDistance(rootPart.Position,pos)
    if dist<3 then return true end
    local tweenInfo=TweenInfo.new(dist/20,Enum.EasingStyle.Linear)
    local tween=tweenService:Create(rootPart,tweenInfo,{CFrame=CFrame.new(pos)})
    tween:Play()
    local start=tick()
    repeat wait(0.1) until not tween.PlaybackState==Enum.PlaybackState.Playing or tick()-start>timeout
    return getDistance(rootPart.Position,pos)<5
end
local function interactWithNPC(npc)
    if not npc or not rootPart then return false end
    local head=npc:FindFirstChild("Head")
    if head then
        rootPart.CFrame=CFrame.new(head.Position+Vector3.new(0,2,0))
        wait(0.3)
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            wait(0.1)
        end
        return true
    end
    return false
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
local function getAvailableFish(location,sea)
    local available={}
    for _,fish in ipairs(FISH_DATA) do
        local locMatch=false
        for _,loc in ipairs(fish.locations) do
            if loc=="Any" or loc:lower()==location:lower() then
                locMatch=true
                break
            end
        end
        if locMatch then
            local baitMatch=false
            for _,bait in ipairs(fish.baits) do
                if currentBait:lower():match(bait:lower()) then
                    baitMatch=true
                    break
                end
            end
            if baitMatch then
                table.insert(available,fish)
            end
        end
    end
    return available
end
local function getRandomFish(location,sea)
    local available=getAvailableFish(location,sea)
    if #available==0 then
        available=FISH_DATA
    end
    local weights={}
    local totalWeight=0
    for _,fish in ipairs(available) do
        local w=1
        if fish.rarity=="Common" then w=50
        elseif fish.rarity=="Uncommon" then w=30
        elseif fish.rarity=="Rare" then w=15
        elseif fish.rarity=="Legendary" then w=5
        elseif fish.rarity=="Mythical" then w=2 end
        table.insert(weights,w)
        totalWeight=totalWeight+w
    end
    local roll=math.random()*totalWeight
    local cum=0
    for i,fish in ipairs(available) do
        cum=cum+weights[i]
        if roll<=cum then
            return fish
        end
    end
    return available[1]
end
local function reelFishingLine()
    if isReeling then return false end
    if not fishOnHook then return false end
    isReeling=true
    reelTime=tick()
    local waitTime=math.random(1,3)
    task.wait(waitTime)
    local rodBonus=1
    for _,rod in ipairs(ROD_DATA) do
        if rod.name==currentRod then
            rodBonus=rod.catchRate
            break
        end
    end
    local baitBonus=1
    for _,bait in ipairs(BAIT_DATA) do
        if bait.name==currentBait then
            baitBonus=bait.catchBonus
            break
        end
    end
    local location="Any"
    if fishingSpot then
        location=fishingSpot.Name or "Any"
    end
    local sea=getCurrentSea()
    local fishData=getRandomFish(location,sea)
    local weight=math.random(fishData.minWeight*10,fishData.maxWeight*10)/10
    local expGain=fishData.exp*rodBonus*baitBonus
    local price=fishData.price*rodBonus*baitBonus
    local fishEntry={
        name=fishData.name,
        rarity=fishData.rarity,
        weight=weight,
        price=math.floor(price),
        exp=math.floor(expGain),
        time=os.time(),
        rod=currentRod,
        bait=currentBait,
        location=location
    }
    table.insert(fishCaughtList,fishEntry)
    fishCaught=fishCaught+1
    totalFishWeight=totalFishWeight+weight
    fishingExp=fishingExp+expGain
    while fishingExp>=fishingExpToNext do
        fishingExp=fishingExp-fishingExpToNext
        fishingLevel=fishingLevel+1
        fishingExpToNext=math.floor(fishingExpToNext*1.2)
        anglerTrust=anglerTrust+1
    end
    fishOnHook=false
    isReeling=false
    return true
end
local function checkFishBite()
    if not fishOnHook and not isCasting and not isReeling then
        local biteChance=0.05
        for _,rod in ipairs(ROD_DATA) do
            if rod.name==currentRod then
                biteChance=biteChance*rod.catchRate
                break
            end
        end
        if math.random()<biteChance then
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
        fishingSpot=findFishingSpot()
        if not fishingSpot then
            local fisherman=findFishermanNPC()
            if fisherman then
                interactWithNPC(fisherman)
            end
            return
        end
    end
    if data.autoMove and getDistance(rootPart.Position,fishingSpot.Position)>5 then
        moveToPosition(fishingSpot.Position+Vector3.new(0,2,0))
        return
    end
    if data.autoCast and not isCasting and not isReeling and not fishOnHook then
        if baitCount>0 or currentBait=="Basic Bait" then
            castFishingLine()
            if currentBait~="Basic Bait" then
                baitCount=baitCount-1
            end
        else
            local angler=findAnglerNPC()
            if angler then
                interactWithNPC(angler)
                local fisherman=findFishermanNPC()
                if fisherman then
                    interactWithNPC(fisherman)
                end
            end
        end
        return
    end
    if fishOnHook and data.autoReel then
        reelFishingLine()
        return
    end
    if not fishOnHook and not isCasting and fishingTimer%3==0 then
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
    return true
end
function fishing.SetAutoReel(enabled)
    if dataRef then dataRef.autoReel=enabled end
    return true
end
function fishing.SetAutoMove(enabled)
    if dataRef then dataRef.autoMove=enabled end
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
        currentRod=currentRod,
        currentBait=currentBait,
        anglerTrust=anglerTrust,
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
function fishing.CastLine()
    return castFishingLine()
end
function fishing.ReelLine()
    return reelFishingLine()
end
function fishing.MoveToNearestSpot()
    local spot=findFishingSpot()
    if spot then
        return moveToPosition(spot.Position+Vector3.new(0,2,0))
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
function fishing.GetAnglerTrust()
    return anglerTrust
end
function fishing.SetRod(rodName)
    for _,rod in ipairs(ROD_DATA) do
        if rod.name==rodName then
            if anglerTrust>=rod.requiredTrust then
                currentRod=rodName
                return true
            end
        end
    end
    return false
end
function fishing.GetCurrentRod()
    return currentRod
end
function fishing.SetBait(baitName)
    for _,bait in ipairs(BAIT_DATA) do
        if bait.name==baitName then
            if anglerTrust>=bait.requiredTrust then
                currentBait=baitName
                return true
            end
        end
    end
    return false
end
function fishing.GetCurrentBait()
    return currentBait
end
function fishing.GetAvailableRods()
    local available={}
    for _,rod in ipairs(ROD_DATA) do
        if anglerTrust>=rod.requiredTrust then
            table.insert(available,rod.name)
        end
    end
    return available
end
function fishing.GetAvailableBaits()
    local available={}
    for _,bait in ipairs(BAIT_DATA) do
        if anglerTrust>=bait.requiredTrust then
            table.insert(available,bait.name)
        end
    end
    return available
end
function fishing.GetAllRods()
    local list={}
    for _,rod in ipairs(ROD_DATA) do
        table.insert(list,rod.name)
    end
    return list
end
function fishing.GetAllBaits()
    local list={}
    for _,bait in ipairs(BAIT_DATA) do
        table.insert(list,bait.name)
    end
    return list
end
function fishing.GetAllFish()
    return FISH_DATA
end
function fishing.GetFishByRarity(rarity)
    local result={}
    for _,fish in ipairs(FISH_DATA) do
        if fish.rarity==rarity then
            table.insert(result,fish)
        end
    end
    return result
end
function fishing.GetFishByLocation(location)
    local result={}
    for _,fish in ipairs(FISH_DATA) do
        for _,loc in ipairs(fish.locations) do
            if loc=="Any" or loc:lower()==location:lower() then
                table.insert(result,fish)
                break
            end
        end
    end
    return result
end
function fishing.GetAllLocations()
    return LOCATIONS
end
function fishing.FindFishermanNPC()
    return findFishermanNPC()
end
function fishing.FindAnglerNPC()
    return findAnglerNPC()
end
function fishing.InteractWithFisherman()
    local npc=findFishermanNPC()
    if npc then
        return interactWithNPC(npc)
    end
    return false
end
function fishing.InteractWithAngler()
    local npc=findAnglerNPC()
    if npc then
        return interactWithNPC(npc)
    end
    return false
end
function fishing.BuyBait(baitName,quantity)
    quantity=quantity or 1
    for _,bait in ipairs(BAIT_DATA) do
        if bait.name==baitName then
            if anglerTrust>=bait.requiredTrust then
                local totalPrice=bait.price*quantity
                local money=player:FindFirstChild("Money")
                if money and money:IsA("NumberValue") and money.Value>=totalPrice then
                    money.Value=money.Value-totalPrice
                    baitCount=baitCount+bait.quantity*quantity
                    return true
                end
            end
        end
    end
    return false
end
function fishing.SellAllFish()
    local total=0
    for _,fish in ipairs(fishCaughtList) do
        total=total+fish.price
    end
    local money=player:FindFirstChild("Money")
    if money and money:IsA("NumberValue") then
        money.Value=money.Value+total
    end
    fishCaughtList={}
    fishCaught=0
    totalFishWeight=0
    return total
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
    local money=player:FindFirstChild("Money")
    if money and money:IsA("NumberValue") then
        money.Value=money.Value+total
    end
    fishCaughtList=newList
    fishCaught=#newList
    return total
end
function fishing.GetTotalPrice()
    local total=0
    for _,fish in ipairs(fishCaughtList) do
        total=total+fish.price
    end
    return total
end
function fishing.GetAverageWeight()
    if #fishCaughtList==0 then return 0 end
    local total=0
    for _,fish in ipairs(fishCaughtList) do
        total=total+fish.weight
    end
    return total/#fishCaughtList
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
function fishing.GetFishCountByRarity(rarity)
    local count=0
    for _,fish in ipairs(fishCaughtList) do
        if fish.rarity==rarity then count=count+1 end
    end
    return count
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
        expToNext=fishingExpToNext,
        anglerTrust=anglerTrust,
        currentRod=currentRod,
        currentBait=currentBait
    }
end
function fishing.ResetFishing()
    fishCaught=0
    totalFishWeight=0
    fishCaughtList={}
    fishingExp=0
    fishingLevel=0
    fishingExpToNext=100
    baitCount=0
    anglerTrust=0
    fishOnHook=false
    isCasting=false
    isReeling=false
    currentRod="Fishing Rod"
    currentBait="Basic Bait"
    return true
end
function fishing.ExportFishData()
    return httpService:JSONEncode({
        fishCaught=fishCaught,
        totalWeight=totalFishWeight,
        level=fishingLevel,
        exp=fishingExp,
        expToNext=fishingExpToNext,
        anglerTrust=anglerTrust,
        fishList=fishCaughtList,
        currentRod=currentRod,
        currentBait=currentBait
    })
end
function fishing.ImportFishData(json)
    local success,data=pcall(function()return httpService:JSONDecode(json)end)
    if success and data then
        if data.fishCaught then fishCaught=data.fishCaught end
        if data.totalWeight then totalFishWeight=data.totalWeight end
        if data.level then fishingLevel=data.level end
        if data.exp then fishingExp=data.exp end
        if data.expToNext then fishingExpToNext=data.expToNext end
        if data.anglerTrust then anglerTrust=data.anglerTrust end
        if data.fishList then fishCaughtList=data.fishList end
        if data.currentRod then currentRod=data.currentRod end
        if data.currentBait then currentBait=data.currentBait end
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
    fishingLevel=0
    fishingExp=0
    fishingExpToNext=100
    baitCount=0
    anglerTrust=0
    dataRef=nil
    return true
end
function fishing.Initialize(data)
    dataRef=data
    updateCharacter()
    if data then
        if data.autoCast~=nil then dataRef.autoCast=data.autoCast end
        if data.autoReel~=nil then dataRef.autoReel=data.autoReel end
        if data.autoMove~=nil then dataRef.autoMove=data.autoMove end
        if data.baitCount then baitCount=data.baitCount end
        if data.currentRod then
            for _,rod in ipairs(ROD_DATA) do
                if rod.name==data.currentRod then
                    currentRod=rod.name
                    break
                end
            end
        end
        if data.currentBait then
            for _,bait in ipairs(BAIT_DATA) do
                if bait.name==data.currentBait then
                    currentBait=bait.name
                    break
                end
            end
        end
    end
    if dataRef.autoCast==nil then dataRef.autoCast=true end
    if dataRef.autoReel==nil then dataRef.autoReel=true end
    if dataRef.autoMove==nil then dataRef.autoMove=true end
    return true
end
return fishing
