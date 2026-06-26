local dracoRace={}
dracoRace.__index=dracoRace
local player=game.Players.LocalPlayer
local runService=game:GetService("RunService")
local tweenService=game:GetService("TweenService")
local workspace=game:GetService("Workspace")
local players=game:GetService("Players")
local lighting=game:GetService("Lighting")
local virtualUser=game:GetService("VirtualUser")
local coreGui=game:GetService("CoreGui")
local userInput=game:GetService("UserInputService")
local teleportService=game:GetService("TeleportService")
local httpService=game:GetService("HttpService")
local debris=game:GetService("Debris")
local replicatedStorage=game:GetService("ReplicatedStorage")
local character=nil local humanoid=nil local rootPart=nil
local dataRef=nil local isRunning=false
local currentRace="" local raceVersion=1
local dracoUnlocked=false local dracoV2=false local dracoV3=false local dracoV4=false
local dragonHeartReady=false local dragonStormReady=false
local dragonTalonMastery=0 local dragonHeartMastery=0 local dragonStormMastery=0
local dragonEggs=0 local dinosaurBones=0 local dragonScales=0 local blazeEmbers=0
local leviathanHeart=false local volcanicOrb=false
local trialOfFlamesComplete=false local dojoBelts={}
local primordialReignCooldown=0 local dragonHeartCooldown=0
local transformationGauge=0 local isTransformed=false
local leviathanKills=0 local requiredLeviathanKillsV4=5
local levelRequired=2000
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
local function moveToPosition(pos,timeout)
    timeout=timeout or 10
    if not rootPart then return false end
    local dist=getDistance(rootPart.Position,pos)
    if dist<3 then return true end
    local tweenInfo=TweenInfo.new(dist/30,Enum.EasingStyle.Linear)
    local tween=tweenService:Create(rootPart,tweenInfo,{CFrame=CFrame.new(pos)})
    tween:Play()
    local start=tick()
    repeat wait(0.1) until not tween.PlaybackState==Enum.PlaybackState.Playing or tick()-start>timeout
    return getDistance(rootPart.Position,pos)<5
end
local function getCurrentRace()
    local race=player:FindFirstChild("Race")
    if race and race:IsA("StringValue") then
        return race.Value
    end
    return ""
end
local function getRaceVersion()
    local v1=player:FindFirstChild("RaceV1")
    local v2=player:FindFirstChild("RaceV2")
    local v3=player:FindFirstChild("RaceV3")
    local v4=player:FindFirstChild("RaceV4")
    if v4 and v4:IsA("BoolValue") and v4.Value then return 4
    elseif v3 and v3:IsA("BoolValue") and v3.Value then return 3
    elseif v2 and v2:IsA("BoolValue") and v2.Value then return 2
    else return 1 end
end
local function getMastery(itemName)
    for _,v in pairs(player:GetDescendants()) do
        if v:IsA("NumberValue") and v.Name:lower():match(itemName:lower()) and v.Name:lower():match("mastery") then
            return v.Value
        end
    end
    return 0
end
local function getItemCount(itemName)
    local count=0
    for _,v in pairs(player:GetDescendants()) do
        if v:IsA("NumberValue") or v:IsA("IntValue") then
            if v.Name:lower():match(itemName:lower()) then
                count=count+v.Value
            end
        end
        if v:IsA("StringValue") and v.Name:lower():match(itemName:lower()) then
            count=count+1
        end
    end
    for _,v in pairs(workspace:GetDescendants()) do
        if v:IsA("Part") and v.Name:lower():match(itemName:lower()) then
            count=count+1
        end
    end
    return count
end
local function findDragonWizard()
    for _,v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") then
            if v.Name:lower():find("dragon") and v.Name:lower():find("wizard") then
                return v
            end
        end
        if v:IsA("Model") and v:FindFirstChild("Head") then
            if v.Name:lower():find("dragon") and v.Name:lower():find("wizard") then
                return v
            end
        end
    end
    return nil
end
local function findDojoTrainer()
    for _,v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") then
            if v.Name:lower():find("dojo") and v.Name:lower():find("trainer") then
                return v
            end
        end
        if v:IsA("Model") and v:FindFirstChild("Head") then
            if v.Name:lower():find("dojo") and v.Name:lower():find("trainer") then
                return v
            end
        end
    end
    return nil
end
local function findDragonHunter()
    for _,v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") then
            if v.Name:lower():find("dragon") and v.Name:lower():find("hunter") then
                return v
            end
        end
        if v:IsA("Model") and v:FindFirstChild("Head") then
            if v.Name:lower():find("dragon") and v.Name:lower():find("hunter") then
                return v
            end
        end
    end
    return nil
end
local function findDragonEggs()
    local eggs={}
    for _,v in pairs(workspace:GetDescendants()) do
        if v:IsA("Part") and v.Name:lower():find("dragon") and v.Name:lower():find("egg") then
            table.insert(eggs,v)
        end
        if v:IsA("Model") and v.Name:lower():find("dragon") and v.Name:lower():find("egg") then
            table.insert(eggs,v)
        end
    end
    return eggs
end
local function findDinosaurBones()
    local bones={}
    for _,v in pairs(workspace:GetDescendants()) do
        if v:IsA("Part") and v.Name:lower():find("bone") then
            table.insert(bones,v)
        end
        if v:IsA("Model") and v.Name:lower():find("bone") then
            table.insert(bones,v)
        end
    end
    return bones
end
local function findDragonScales()
    local scales={}
    for _,v in pairs(workspace:GetDescendants()) do
        if v:IsA("Part") and v.Name:lower():find("dragon") and v.Name:lower():find("scale") then
            table.insert(scales,v)
        end
        if v:IsA("Model") and v.Name:lower():find("dragon") and v.Name:lower():find("scale") then
            table.insert(scales,v)
        end
    end
    return scales
end
local function findBlazeEmbers()
    local embers={}
    for _,v in pairs(workspace:GetDescendants()) do
        if v:IsA("Part") and v.Name:lower():find("blaze") and v.Name:lower():find("ember") then
            table.insert(embers,v)
        end
        if v:IsA("Model") and v.Name:lower():find("blaze") and v.Name:lower():find("ember") then
            table.insert(embers,v)
        end
    end
    return embers
end
local function findFireFlowers()
    local flowers={}
    for _,v in pairs(workspace:GetDescendants()) do
        if v:IsA("Part") and v.Name:lower():find("fire") and v.Name:lower():find("flower") then
            table.insert(flowers,v)
        end
        if v:IsA("Model") and v.Name:lower():find("fire") and v.Name:lower():find("flower") then
            table.insert(flowers,v)
        end
    end
    return flowers
end
local function findLeviathan()
    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") then
            if v.Name:lower():find("leviathan") then
                return v
            end
        end
    end
    return nil
end
local function findLeviathanHeart()
    for _,v in pairs(workspace:GetDescendants()) do
        if v:IsA("Part") and v.Name:lower():find("leviathan") and v.Name:lower():find("heart") then
            return v
        end
        if v:IsA("Model") and v.Name:lower():find("leviathan") and v.Name:lower():find("heart") then
            return v
        end
    end
    return nil
end
local function findVolcanicOrb()
    for _,v in pairs(workspace:GetDescendants()) do
        if v:IsA("Part") and v.Name:lower():find("volcanic") and v.Name:lower():find("orb") then
            return v
        end
        if v:IsA("Model") and v.Name:lower():find("volcanic") and v.Name:lower():find("orb") then
            return v
        end
    end
    return nil
end
local function findTrialOfFlames()
    for _,v in pairs(workspace:GetDescendants()) do
        if v:IsA("Part") and v.Name:lower():find("trial") and v.Name:lower():find("flames") then
            return v
        end
        if v:IsA("Model") and v.Name:lower():find("trial") and v.Name:lower():find("flames") then
            return v
        end
    end
    return nil
end
local function findDragonDojo()
    for _,v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("Head") then
            if v.Name:lower():find("dragon") and v.Name:lower():find("dojo") then
                return v
            end
        end
    end
    return nil
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
local function collectDragonEggs()
    local eggs=findDragonEggs()
    local count=0
    for _,egg in ipairs(eggs) do
        if rootPart then
            local pos=egg.Position or (egg:IsA("Model") and egg:FindFirstChild("Head") and egg.Head.Position) or egg.Position
            if pos then
                moveToPosition(pos+Vector3.new(0,2,0),3)
                wait(0.2)
                if egg:IsA("Part") then egg:Destroy() end
                if egg:IsA("Model") then
                    for _,p in pairs(egg:GetChildren()) do
                        if p:IsA("Part") then p:Destroy() end
                    end
                    egg:Destroy()
                end
                dragonEggs=dragonEggs+1
                count=count+1
            end
        end
        wait(0.1)
    end
    return count
end
local function collectDinosaurBones()
    local bones=findDinosaurBones()
    local count=0
    for _,bone in ipairs(bones) do
        if rootPart then
            local pos=bone.Position or (bone:IsA("Model") and bone:FindFirstChild("Head") and bone.Head.Position) or bone.Position
            if pos then
                moveToPosition(pos+Vector3.new(0,2,0),3)
                wait(0.2)
                if bone:IsA("Part") then bone:Destroy() end
                if bone:IsA("Model") then
                    for _,p in pairs(bone:GetChildren()) do
                        if p:IsA("Part") then p:Destroy() end
                    end
                    bone:Destroy()
                end
                dinosaurBones=dinosaurBones+1
                count=count+1
            end
        end
        wait(0.1)
    end
    return count
end
local function collectDragonScales()
    local scales=findDragonScales()
    local count=0
    for _,scale in ipairs(scales) do
        if rootPart then
            local pos=scale.Position or (scale:IsA("Model") and scale:FindFirstChild("Head") and scale.Head.Position) or scale.Position
            if pos then
                moveToPosition(pos+Vector3.new(0,2,0),3)
                wait(0.2)
                if scale:IsA("Part") then scale:Destroy() end
                if scale:IsA("Model") then scale:Destroy() end
                dragonScales=dragonScales+1
                count=count+1
            end
        end
        wait(0.1)
    end
    return count
end
local function collectBlazeEmbers()
    local embers=findBlazeEmbers()
    local count=0
    for _,ember in ipairs(embers) do
        if rootPart then
            local pos=ember.Position or (ember:IsA("Model") and ember:FindFirstChild("Head") and ember.Head.Position) or ember.Position
            if pos then
                moveToPosition(pos+Vector3.new(0,2,0),3)
                wait(0.2)
                if ember:IsA("Part") then ember:Destroy() end
                if ember:IsA("Model") then ember:Destroy() end
                blazeEmbers=blazeEmbers+1
                count=count+1
            end
        end
        wait(0.1)
    end
    return count
end
local function collectFireFlowers()
    local flowers=findFireFlowers()
    local count=0
    for _,flower in ipairs(flowers) do
        if rootPart then
            local pos=flower.Position or (flower:IsA("Model") and flower:FindFirstChild("Head") and flower.Head.Position) or flower.Position
            if pos then
                moveToPosition(pos+Vector3.new(0,2,0),3)
                wait(0.2)
                if flower:IsA("Part") then flower:Destroy() end
                if flower:IsA("Model") then flower:Destroy() end
                count=count+1
            end
        end
        wait(0.1)
    end
    return count
end
local function fightLeviathan()
    local levi=findLeviathan()
    if not levi then return false end
    local head=levi:FindFirstChild("Head")
    if not head then return false end
    moveToPosition(head.Position+Vector3.new(0,10,0),5)
    wait(0.3)
    if humanoid then
        humanoid:BreakJoints()
        wait(0.5)
        leviathanKills=leviathanKills+1
        local heart=findLeviathanHeart()
        if heart then
            moveToPosition(heart.Position+Vector3.new(0,2,0),3)
            wait(0.2)
            leviathanHeart=true
            heart:Destroy()
        end
        return true
    end
    return false
end
local function collectVolcanicOrb()
    local orb=findVolcanicOrb()
    if not orb then return false end
    local pos=orb.Position or (orb:IsA("Model") and orb:FindFirstChild("Head") and orb.Head.Position) or orb.Position
    if pos then
        moveToPosition(pos+Vector3.new(0,2,0),3)
        wait(0.2)
        if orb:IsA("Part") then orb:Destroy() end
        if orb:IsA("Model") then orb:Destroy() end
        volcanicOrb=true
        return true
    end
    return false
end
local function upgradeToV2()
    if dracoV2 then return true end
    if not dracoV3 then -- V2 trước V3
        if not leviathanHeart then
            fightLeviathan()
            wait(1)
        end
        if not volcanicOrb then
            collectVolcanicOrb()
            wait(1)
        end
        if dinosaurBones<10 then
            collectDinosaurBones()
            wait(1)
        end
        local wizard=findDragonWizard()
        if wizard then
            interactWithNPC(wizard)
            wait(0.5)
            dracoV2=true
            raceVersion=2
            print("[DracoRace] Đã nâng cấp lên V2!")
            return true
        end
    end
    return false
end
local function upgradeToV3()
    if dracoV3 then return true end
    if not dracoV2 then
        upgradeToV2()
        wait(1)
    end
    dragonTalonMastery=getMastery("DragonTalon")
    dragonHeartMastery=getMastery("Dragonheart")
    dragonStormMastery=getMastery("Dragonstorm")
    if dragonTalonMastery>=50 and dragonHeartMastery>=50 and dragonStormMastery>=50 then
        local wizard=findDragonWizard()
        if wizard then
            interactWithNPC(wizard)
            wait(0.5)
            dracoV3=true
            raceVersion=3
            print("[DracoRace] Đã nâng cấp lên V3!")
            return true
        end
    else
        print("[DracoRace] Cần Mastery 50 cho Dragon Talon, Dragonheart, Dragonstorm")
    end
    return false
end
local function upgradeToV4()
    if dracoV4 then return true end
    if not dracoV3 then
        upgradeToV3()
        wait(1)
    end
    if leviathanKills<requiredLeviathanKillsV4 then
        fightLeviathan()
        wait(1)
    end
    if blazeEmbers<25 then
        collectBlazeEmbers()
        wait(1)
    end
    if dragonScales<5 then
        collectDragonScales()
        wait(1)
    end
    if not trialOfFlamesComplete then
        local trial=findTrialOfFlames()
        if trial then
            moveToPosition(trial.Position+Vector3.new(0,3,0),5)
            wait(0.5)
            if humanoid then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                wait(0.2)
            end
            trialOfFlamesComplete=true
        end
    end
    if leviathanKills>=requiredLeviathanKillsV4 and trialOfFlamesComplete and blazeEmbers>=25 and dragonScales>=5 then
        local wizard=findDragonWizard()
        if wizard then
            interactWithNPC(wizard)
            wait(0.5)
            dracoV4=true
            raceVersion=4
            print("[DracoRace] Đã nâng cấp lên V4!")
            return true
        end
    end
    return false
end
local function activatePrimordialReign()
    if primordialReignCooldown>tick() then return false end
    if not dracoV3 then return false end
    if humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        wait(0.1)
        humanoid:ChangeState(Enum.HumanoidStateType.Landed)
        primordialReignCooldown=tick()+35
        for _,p in pairs(players:GetPlayers()) do
            if p~=player and p.Character and p.Character:FindFirstChild("Head") then
                local dist=getDistance(rootPart.Position,p.Character.Head.Position)
                if dist<50 then
                    p.Character.Humanoid.WalkSpeed=p.Character.Humanoid.WalkSpeed*0.8
                    wait(0.5)
                    p.Character.Humanoid.WalkSpeed=p.Character.Humanoid.WalkSpeed/0.8
                end
            end
        end
        return true
    end
    return false
end
local function activateDragonHeart()
    if dragonHeartCooldown>tick() then return false end
    if not dracoV3 then return false end
    if humanoid then
        local def=humanoid:FindFirstChild("Defense")
        if def and def:IsA("NumberValue") then
            def.Value=def.Value*1.15
            wait(5)
            def.Value=def.Value/1.15
        end
        dragonHeartCooldown=tick()+35
        return true
    end
    return false
end
local function activateDragonStorm()
    if not dracoV4 then return false end
    if humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        wait(0.1)
        humanoid:ChangeState(Enum.HumanoidStateType.Landed)
        for _,p in pairs(players:GetPlayers()) do
            if p~=player and p.Character and p.Character:FindFirstChild("Head") then
                local dist=getDistance(rootPart.Position,p.Character.Head.Position)
                if dist<50 then
                    p.Character.Humanoid:TakeDamage(50)
                end
            end
        end
        return true
    end
    return false
end
local function fillTransformationGauge(amount)
    transformationGauge=math.min(transformationGauge+amount,100)
    return transformationGauge
end
local function transform()
    if transformationGauge<100 then return false end
    if isTransformed then return false end
    isTransformed=true
    transformationGauge=0
    if humanoid then
        humanoid.WalkSpeed=humanoid.WalkSpeed*1.5
        humanoid.JumpPower=humanoid.JumpPower*1.5
        wait(30)
        humanoid.WalkSpeed=humanoid.WalkSpeed/1.5
        humanoid.JumpPower=humanoid.JumpPower/1.5
        isTransformed=false
    end
    return true
end
local function processDracoRace(data)
    if not data or not data.enabled then
        if isRunning then dracoRace.Stop() end
        return
    end
    if not rootPart or not humanoid then updateCharacter() end
    if not rootPart or not humanoid then return end
    local level=getPlayerLevel()
    local sea=getCurrentSea()
    if level<levelRequired then
        print("[DracoRace] Cần level "..levelRequired.." để mở khóa Draco Race")
        return
    end
    if sea<3 then
        print("[DracoRace] Cần Sea 3 để mở khóa Draco Race")
        return
    end
    currentRace=getCurrentRace()
    raceVersion=getRaceVersion()
    dragonTalonMastery=getMastery("DragonTalon")
    dragonHeartMastery=getMastery("Dragonheart")
    dragonStormMastery=getMastery("Dragonstorm")
    if currentRace~="Draco" then
        if data.autoUnlock then
            local wizard=findDragonWizard()
            if wizard then
                interactWithNPC(wizard)
                wait(0.5)
                if dragonEggs<1 then
                    collectDragonEggs()
                end
                local flowers=collectFireFlowers()
                if dragonEggs>=1 and flowers>=5 then
                    if humanoid then
                        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                        wait(0.3)
                    end
                    dracoUnlocked=true
                    currentRace="Draco"
                    print("[DracoRace] Đã mở khóa Draco Race!")
                end
            else
                local dojo=findDragonDojo()
                if dojo then
                    moveToPosition(dojo.Position+Vector3.new(0,3,0),5)
                end
            end
        end
        return
    end
    if data.autoCollectMaterials then
        if data.collectEggs then collectDragonEggs() end
        if data.collectBones then collectDinosaurBones() end
        if data.collectScales then collectDragonScales() end
        if data.collectEmbers then collectBlazeEmbers() end
        if data.collectFireFlowers then collectFireFlowers() end
    end
    if data.autoLeviathan then
        fightLeviathan()
    end
    if data.autoOrb then
        collectVolcanicOrb()
    end
    if data.autoTrial then
        local trial=findTrialOfFlames()
        if trial then
            moveToPosition(trial.Position+Vector3.new(0,3,0),5)
        end
    end
    if raceVersion<2 and data.autoUpgradeV2 then
        upgradeToV2()
    end
    if raceVersion<3 and data.autoUpgradeV3 then
        upgradeToV3()
    end
    if raceVersion<4 and data.autoUpgradeV4 then
        upgradeToV4()
    end
    if data.autoPrimordialReign then
        activatePrimordialReign()
    end
    if data.autoDragonHeart then
        activateDragonHeart()
    end
    if data.autoDragonStorm and dracoV4 then
        activateDragonStorm()
    end
    if data.autoTransform and transformationGauge>=100 then
        transform()
    end
    if data.autoFillGauge then
        fillTransformationGauge(1)
    end
end
local function startDracoLoop(data)
    if isRunning then return end
    isRunning=true
    task.spawn(function()
        while isRunning do
            wait(0.5)
            pcall(function()processDracoRace(data)end)
        end
    end)
end
function dracoRace.Stop()
    isRunning=false
    return true
end
function dracoRace.Run(data)
    if not data then return false end
    dataRef=data
    if not data.enabled then
        if isRunning then dracoRace.Stop() end
        return false
    end
    if not isRunning then
        updateCharacter()
        startDracoLoop(data)
    end
    return true
end
function dracoRace.GetStatus()
    return{
        isRunning=isRunning,
        currentRace=currentRace,
        raceVersion=raceVersion,
        dracoUnlocked=dracoUnlocked,
        dracoV2=dracoV2,
        dracoV3=dracoV3,
        dracoV4=dracoV4,
        dragonEggs=dragonEggs,
        dinosaurBones=dinosaurBones,
        dragonScales=dragonScales,
        blazeEmbers=blazeEmbers,
        leviathanHeart=leviathanHeart,
        volcanicOrb=volcanicOrb,
        trialOfFlamesComplete=trialOfFlamesComplete,
        leviathanKills=leviathanKills,
        requiredLeviathanKillsV4=requiredLeviathanKillsV4,
        dragonTalonMastery=dragonTalonMastery,
        dragonHeartMastery=dragonHeartMastery,
        dragonStormMastery=dragonStormMastery,
        transformationGauge=transformationGauge,
        isTransformed=isTransformed
    }
end
function dracoRace.UnlockRace()
    local wizard=findDragonWizard()
    if wizard then
        if dragonEggs<1 then collectDragonEggs() end
        if collectFireFlowers()<5 then collectFireFlowers() end
        interactWithNPC(wizard)
        return true
    end
    return false
end
function dracoRace.CollectAllMaterials()
    return{
        eggs=collectDragonEggs(),
        bones=collectDinosaurBones(),
        scales=collectDragonScales(),
        embers=collectBlazeEmbers(),
        flowers=collectFireFlowers()
    }
end
function dracoRace.FightLeviathan()
    return fightLeviathan()
end
function dracoRace.CollectVolcanicOrb()
    return collectVolcanicOrb()
end
function dracoRace.UpgradeToV2()
    return upgradeToV2()
end
function dracoRace.UpgradeToV3()
    return upgradeToV3()
end
function dracoRace.UpgradeToV4()
    return upgradeToV4()
end
function dracoRace.ActivatePrimordialReign()
    return activatePrimordialReign()
end
function dracoRace.ActivateDragonHeart()
    return activateDragonHeart()
end
function dracoRace.ActivateDragonStorm()
    return activateDragonStorm()
end
function dracoRace.Transform()
    return transform()
end
function dracoRace.FillGauge(amount)
    return fillTransformationGauge(amount or 1)
end
function dracoRace.FindDragonWizard()
    return findDragonWizard()
end
function dracoRace.FindDragonDojo()
    return findDragonDojo()
end
function dracoRace.FindDragonEggs()
    return findDragonEggs()
end
function dracoRace.FindDinosaurBones()
    return findDinosaurBones()
end
function dracoRace.FindDragonScales()
    return findDragonScales()
end
function dracoRace.FindBlazeEmbers()
    return findBlazeEmbers()
end
function dracoRace.FindFireFlowers()
    return findFireFlowers()
end
function dracoRace.FindLeviathan()
    return findLeviathan()
end
function dracoRace.FindVolcanicOrb()
    return findVolcanicOrb()
end
function dracoRace.FindTrialOfFlames()
    return findTrialOfFlames()
end
function dracoRace.GetRaceVersion()
    return getRaceVersion()
end
function dracoRace.GetCurrentRace()
    return getCurrentRace()
end
function dracoRace.GetMastery(item)
    return getMastery(item)
end
function dracoRace.SetRequiredLevel(level)
    levelRequired=level
    if dataRef then dataRef.levelRequired=level end
    return true
end
function dracoRace.SetRequiredLeviathanKills(count)
    requiredLeviathanKillsV4=count
    if dataRef then dataRef.requiredLeviathanKills=count end
    return true
end
function dracoRace.ToggleAutoCollect()
    if dataRef then
        dataRef.autoCollectMaterials=not dataRef.autoCollectMaterials
        return dataRef.autoCollectMaterials
    end
    return false
end
function dracoRace.ToggleAutoUpgrade()
    if dataRef then
        dataRef.autoUpgradeV2=not dataRef.autoUpgradeV2
        dataRef.autoUpgradeV3=not dataRef.autoUpgradeV3
        dataRef.autoUpgradeV4=not dataRef.autoUpgradeV4
        return dataRef.autoUpgradeV2
    end
    return false
end
function dracoRace.ToggleAutoTransform()
    if dataRef then
        dataRef.autoTransform=not dataRef.autoTransform
        return dataRef.autoTransform
    end
    return false
end
function dracoRace.Pause()
    isRunning=false
    return true
end
function dracoRace.Resume()
    if dataRef and dataRef.enabled then
        isRunning=true
        startDracoLoop(dataRef)
        return true
    end
    return false
end
function dracoRace.Destroy()
    dracoRace.Stop()
    dataRef=nil
    return true
end
function dracoRace.Initialize(data)
    dataRef=data
    updateCharacter()
    if data then
        if data.autoCollectMaterials==nil then data.autoCollectMaterials=true end
        if data.autoUpgradeV2==nil then data.autoUpgradeV2=true end
        if data.autoUpgradeV3==nil then data.autoUpgradeV3=true end
        if data.autoUpgradeV4==nil then data.autoUpgradeV4=true end
        if data.autoLeviathan==nil then data.autoLeviathan=true end
        if data.autoOrb==nil then data.autoOrb=true end
        if data.autoTrial==nil then data.autoTrial=true end
        if data.autoPrimordialReign==nil then data.autoPrimordialReign=true end
        if data.autoDragonHeart==nil then data.autoDragonHeart=true end
        if data.autoDragonStorm==nil then data.autoDragonStorm=true end
        if data.autoTransform==nil then data.autoTransform=true end
        if data.autoFillGauge==nil then data.autoFillGauge=true end
        if data.collectEggs==nil then data.collectEggs=true end
        if data.collectBones==nil then data.collectBones=true end
        if data.collectScales==nil then data.collectScales=true end
        if data.collectEmbers==nil then data.collectEmbers=true end
        if data.collectFireFlowers==nil then data.collectFireFlowers=true end
        if data.autoUnlock==nil then data.autoUnlock=true end
        if data.levelRequired then levelRequired=data.levelRequired end
        if data.requiredLeviathanKills then requiredLeviathanKillsV4=data.requiredLeviathanKills end
    end
    return true
end
return dracoRace
