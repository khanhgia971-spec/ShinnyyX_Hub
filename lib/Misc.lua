local misc={}
misc.__index=misc
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
local virtualUser=game:GetService("VirtualUser")
local guiService=game:GetService("GuiService")
local coreGui=game:GetService("CoreGui")
local starterGui=game:GetService("StarterGui")
local dataRef=nil
local isRunning=false
local autoSpin=false
local dailyReward=false
local giftCollect=false
local autoBuy=false
local autoBuyItem="Beli"
local autoBuyAmount=1
local autoSpinInterval=60
local dailyRewardInterval=86400
local giftCollectInterval=30
local autoBuyInterval=10
local lastSpinTime=0
local lastDailyTime=0
local lastGiftTime=0
local lastBuyTime=0
local spinCount=0
local dailyClaimed=false
local giftsCollected=0
local buyCount=0
local dailyRewardAvailable=false
local giftLocations={}
local shopItems={"Beli","Gems","Fruit","Weapon"}
local function updateCharacter()
    local character=player.Character or player.CharacterAdded:Wait()
    if character then
        return character:FindFirstChild("HumanoidRootPart")
    end
    return nil
end
local function getDistance(pos1,pos2)
    if not pos1 or not pos2 then return math.huge end
    return (pos1-pos2).Magnitude
end
local function findGiftObjects()
    local gifts={}
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Part") and v.Name:lower():match("gift") then
            table.insert(gifts,v)
        end
        if v:IsA("Model") and v:FindFirstChild("Head") and v.Name:lower():match("gift") then
            table.insert(gifts,v)
        end
    end
    return gifts
end
local function findNearestGift()
    local gifts=findGiftObjects()
    local nearest=nil
    local minDist=math.huge
    local rootPart=updateCharacter()
    if not rootPart then return nil end
    for _,g in ipairs(gifts) do
        local pos
        if g:IsA("Part") then pos=g.Position
        elseif g:IsA("Model") and g:FindFirstChild("Head") then pos=g.Head.Position
        else pos=g.Position end
        local dist=getDistance(rootPart.Position,pos)
        if dist<minDist then
            minDist=dist
            nearest=g
        end
    end
    return nearest
end
local function moveToGift(gift)
    local rootPart=updateCharacter()
    if not rootPart or not gift then return false end
    local pos
    if gift:IsA("Part") then pos=gift.Position+Vector3.new(0,2,0)
    elseif gift:IsA("Model") and gift:FindFirstChild("Head") then pos=gift.Head.Position+Vector3.new(0,2,0)
    else pos=gift.Position+Vector3.new(0,2,0) end
    local dist=getDistance(rootPart.Position,pos)
    if dist>3 then
        local tweenInfo=TweenInfo.new(dist/20,Enum.EasingStyle.Linear)
        local tween=tweenService:Create(rootPart,tweenInfo,{CFrame=CFrame.new(pos)})
        tween:Play()
        return true
    end
    return true
end
local function collectGift(gift)
    if not gift then return false end
    local rootPart=updateCharacter()
    if not rootPart then return false end
    moveToGift(gift)
    task.wait(0.3)
    if gift:IsA("Part") then
        gift:Destroy()
        giftsCollected=giftsCollected+1
        return true
    elseif gift:IsA("Model") then
        local part=gift:FindFirstChild("Part") or gift:FindFirstChild("Handle")
        if part then
            part:Destroy()
            giftsCollected=giftsCollected+1
            return true
        end
    end
    return false
end
local function performSpin()
    local rootPart=updateCharacter()
    if not rootPart then return false end
    local spin=Instance.new("Part")
    spin.Size=Vector3.new(5,1,5)
    spin.Position=rootPart.Position+Vector3.new(0,5,0)
    spin.Anchored=true
    spin.BrickColor=BrickColor.new("Bright red")
    spin.Transparency=0.5
    spin.Parent=workspace
    local tween=tweenService:Create(spin,TweenInfo.new(2,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,1),{Rotation=360})
    tween:Play()
    tween.Completed:Wait()
    spin:Destroy()
    spinCount=spinCount+1
    return true
end
local function claimDailyReward()
    local rootPart=updateCharacter()
    if not rootPart then return false end
    local reward=Instance.new("Part")
    reward.Size=Vector3.new(3,0.5,3)
    reward.Position=rootPart.Position+Vector3.new(0,2,0)
    reward.Anchored=true
    reward.BrickColor=BrickColor.new("Bright gold")
    reward.Parent=workspace
    debris:AddItem(reward,2)
    dailyClaimed=true
    dailyRewardAvailable=false
    lastDailyTime=os.time()
    return true
end
local function autoBuyItem(item,amount)
    if not item then item=autoBuyItem end
    if not amount then amount=autoBuyAmount end
    local rootPart=updateCharacter()
    if not rootPart then return false end
    local success=true
    for i=1,amount do
        local part=Instance.new("Part")
        part.Size=Vector3.new(1,1,1)
        part.Position=rootPart.Position+Vector3.new(0,3+i*2,0)
        part.Anchored=true
        part.BrickColor=BrickColor.new("Bright green")
        part.Transparency=0.3
        part.Parent=workspace
        local tag=Instance.new("StringValue")
        tag.Name="ItemTag"
        tag.Value=item
        tag.Parent=part
        debris:AddItem(part,5)
        buyCount=buyCount+1
    end
    return true
end
local function checkDailyReward()
    if not dailyReward then return false end
    if dailyClaimed then
        if os.time()-lastDailyTime>=dailyRewardInterval then
            dailyClaimed=false
            dailyRewardAvailable=true
        end
    else
        dailyRewardAvailable=true
    end
    if dailyRewardAvailable then
        claimDailyReward()
        return true
    end
    return false
end
local function processMisc(data)
    local rootPart=updateCharacter()
    if not rootPart then return end
    if data.autoSpin and autoSpin then
        if os.time()-lastSpinTime>=autoSpinInterval then
            performSpin()
            lastSpinTime=os.time()
        end
    end
    if data.dailyReward and dailyReward then
        checkDailyReward()
    end
    if data.giftCollect and giftCollect then
        if os.time()-lastGiftTime>=giftCollectInterval then
            local gift=findNearestGift()
            if gift then
                collectGift(gift)
                lastGiftTime=os.time()
            end
        end
    end
    if data.autoBuy and autoBuy then
        if os.time()-lastBuyTime>=autoBuyInterval then
            autoBuyItem(data.autoBuyItem or "Beli",data.autoBuyAmount or 1)
            lastBuyTime=os.time()
        end
    end
end
local function startMiscLoop(data)
    if isRunning then return end
    isRunning=true
    task.spawn(function()
        while isRunning do
            wait(0.5)
            pcall(function()processMisc(data)end)
        end
    end)
end
function misc.Stop()
    isRunning=false
    return true
end
function misc.Run(data)
    if not data then return false end
    dataRef=data
    if data.autoSpin~=nil then autoSpin=data.autoSpin end
    if data.dailyReward~=nil then dailyReward=data.dailyReward end
    if data.giftCollect~=nil then giftCollect=data.giftCollect end
    if data.autoBuy~=nil then autoBuy=data.autoBuy end
    if data.autoBuyItem then autoBuyItem=data.autoBuyItem end
    if data.autoBuyAmount then autoBuyAmount=data.autoBuyAmount end
    if data.autoSpinInterval then autoSpinInterval=data.autoSpinInterval end
    if data.dailyRewardInterval then dailyRewardInterval=data.dailyRewardInterval end
    if data.giftCollectInterval then giftCollectInterval=data.giftCollectInterval end
    if data.autoBuyInterval then autoBuyInterval=data.autoBuyInterval end
    if not data.enabled then
        if isRunning then misc.Stop() end
        return false
    end
    if not isRunning then
        startMiscLoop(data)
    end
    return true
end
function misc.ToggleAutoSpin()
    autoSpin=not autoSpin
    if dataRef then dataRef.autoSpin=autoSpin end
    return autoSpin
end
function misc.ToggleDailyReward()
    dailyReward=not dailyReward
    if dataRef then dataRef.dailyReward=dailyReward end
    return dailyReward
end
function misc.ToggleGiftCollect()
    giftCollect=not giftCollect
    if dataRef then dataRef.giftCollect=giftCollect end
    return giftCollect
end
function misc.ToggleAutoBuy()
    autoBuy=not autoBuy
    if dataRef then dataRef.autoBuy=autoBuy end
    return autoBuy
end
function misc.SetAutoBuyItem(item)
    autoBuyItem=item
    if dataRef then dataRef.autoBuyItem=item end
    return true
end
function misc.SetAutoBuyAmount(amount)
    autoBuyAmount=amount
    if dataRef then dataRef.autoBuyAmount=amount end
    return true
end
function misc.SetAutoSpinInterval(interval)
    autoSpinInterval=interval
    if dataRef then dataRef.autoSpinInterval=interval end
    return true
end
function misc.SetDailyRewardInterval(interval)
    dailyRewardInterval=interval
    if dataRef then dataRef.dailyRewardInterval=interval end
    return true
end
function misc.SetGiftCollectInterval(interval)
    giftCollectInterval=interval
    if dataRef then dataRef.giftCollectInterval=interval end
    return true
end
function misc.SetAutoBuyInterval(interval)
    autoBuyInterval=interval
    if dataRef then dataRef.autoBuyInterval=interval end
    return true
end
function misc.GetStatus()
    return{
        isRunning=isRunning,
        autoSpin=autoSpin,
        dailyReward=dailyReward,
        giftCollect=giftCollect,
        autoBuy=autoBuy,
        spinCount=spinCount,
        dailyClaimed=dailyClaimed,
        dailyRewardAvailable=dailyRewardAvailable,
        giftsCollected=giftsCollected,
        buyCount=buyCount,
        autoBuyItem=autoBuyItem,
        autoBuyAmount=autoBuyAmount,
        lastSpinTime=lastSpinTime,
        lastDailyTime=lastDailyTime,
        lastGiftTime=lastGiftTime,
        lastBuyTime=lastBuyTime
    }
end
function misc.PerformSpin()
    return performSpin()
end
function misc.ClaimDailyReward()
    return claimDailyReward()
end
function misc.CollectGift()
    local gift=findNearestGift()
    if gift then
        return collectGift(gift)
    end
    return false
end
function misc.CollectAllGifts()
    local gifts=findGiftObjects()
    local count=0
    for _,g in ipairs(gifts) do
        if collectGift(g) then count=count+1 end
        task.wait(0.1)
    end
    return count
end
function misc.AutoBuy(item,amount)
    return autoBuyItem(item,amount)
end
function misc.FindGifts()
    return findGiftObjects()
end
function misc.FindNearestGift()
    return findNearestGift()
end
function misc.MoveToGift(gift)
    return moveToGift(gift)
end
function misc.GetSpinCount()
    return spinCount
end
function misc.GetGiftsCollected()
    return giftsCollected
end
function misc.GetBuyCount()
    return buyCount
end
function misc.ResetStats()
    spinCount=0
    giftsCollected=0
    buyCount=0
    dailyClaimed=false
    dailyRewardAvailable=false
    return true
end
function misc.SetShopItems(items)
    shopItems=items
    if dataRef then dataRef.shopItems=items end
    return true
end
function misc.GetShopItems()
    return shopItems
end
function misc.AddShopItem(item)
    table.insert(shopItems,item)
    if dataRef then dataRef.shopItems=shopItems end
    return true
end
function misc.RemoveShopItem(item)
    for i,v in ipairs(shopItems) do
        if v==item then
            table.remove(shopItems,i)
            if dataRef then dataRef.shopItems=shopItems end
            return true
        end
    end
    return false
end
function misc.ExportMiscData()
    return httpService:JSONEncode({
        autoSpin=autoSpin,
        dailyReward=dailyReward,
        giftCollect=giftCollect,
        autoBuy=autoBuy,
        autoBuyItem=autoBuyItem,
        autoBuyAmount=autoBuyAmount,
        spinCount=spinCount,
        giftsCollected=giftsCollected,
        buyCount=buyCount,
        dailyClaimed=dailyClaimed,
        dailyRewardAvailable=dailyRewardAvailable,
        shopItems=shopItems
    })
end
function misc.ImportMiscData(json)
    local success,data=pcall(function()return httpService:JSONDecode(json)end)
    if success and data then
        if data.autoSpin~=nil then autoSpin=data.autoSpin end
        if data.dailyReward~=nil then dailyReward=data.dailyReward end
        if data.giftCollect~=nil then giftCollect=data.giftCollect end
        if data.autoBuy~=nil then autoBuy=data.autoBuy end
        if data.autoBuyItem then autoBuyItem=data.autoBuyItem end
        if data.autoBuyAmount then autoBuyAmount=data.autoBuyAmount end
        if data.spinCount then spinCount=data.spinCount end
        if data.giftsCollected then giftsCollected=data.giftsCollected end
        if data.buyCount then buyCount=data.buyCount end
        if data.dailyClaimed~=nil then dailyClaimed=data.dailyClaimed end
        if data.dailyRewardAvailable~=nil then dailyRewardAvailable=data.dailyRewardAvailable end
        if data.shopItems then shopItems=data.shopItems end
        return true
    end
    return false
end
function misc.Pause()
    isRunning=false
    return true
end
function misc.Resume()
    if dataRef and dataRef.enabled then
        isRunning=true
        startMiscLoop(dataRef)
        return true
    end
    return false
end
function misc.Destroy()
    isRunning=false
    autoSpin=false
    dailyReward=false
    giftCollect=false
    autoBuy=false
    spinCount=0
    giftsCollected=0
    buyCount=0
    dailyClaimed=false
    dailyRewardAvailable=false
    dataRef=nil
    return true
end
function misc.Initialize(data)
    dataRef=data
    if data then
        if data.autoSpin~=nil then autoSpin=data.autoSpin end
        if data.dailyReward~=nil then dailyReward=data.dailyReward end
        if data.giftCollect~=nil then giftCollect=data.giftCollect end
        if data.autoBuy~=nil then autoBuy=data.autoBuy end
        if data.autoBuyItem then autoBuyItem=data.autoBuyItem end
        if data.autoBuyAmount then autoBuyAmount=data.autoBuyAmount end
        if data.autoSpinInterval then autoSpinInterval=data.autoSpinInterval end
        if data.dailyRewardInterval then dailyRewardInterval=data.dailyRewardInterval end
        if data.giftCollectInterval then giftCollectInterval=data.giftCollectInterval end
        if data.autoBuyInterval then autoBuyInterval=data.autoBuyInterval end
        if data.shopItems then shopItems=data.shopItems end
        if data.spinCount then spinCount=data.spinCount end
        if data.giftsCollected then giftsCollected=data.giftsCollected end
        if data.buyCount then buyCount=data.buyCount end
        if data.dailyClaimed~=nil then dailyClaimed=data.dailyClaimed end
        if data.dailyRewardAvailable~=nil then dailyRewardAvailable=data.dailyRewardAvailable end
    end
    if not dataRef then dataRef={enabled=false} end
    return true
end
return misc
