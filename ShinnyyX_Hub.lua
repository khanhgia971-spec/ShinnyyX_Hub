local sh={}
sh.Version="6.0.0"
sh.Name="ShinnyyX Hub✨"
sh.Author="Em Khang"
sh.BaseUrl="https://raw.githubusercontent.com/khanhgia971-spec/ShinnyyX_Hub/main/lib/"
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local UserInputService=game:GetService("UserInputService")
local VirtualUser=game:GetService("VirtualUser")
local TweenService=game:GetService("TweenService")
local HttpService=game:GetService("HttpService")
local MarketplaceService=game:GetService("MarketplaceService")
local GuiService=game:GetService("GuiService")
local CoreGui=game:GetService("CoreGui")
local Lighting=game:GetService("Lighting")
local Workspace=game:GetService("Workspace")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local ServerScriptService=game:GetService("ServerScriptService")
local ServerStorage=game:GetService("ServerStorage")
local TeleportService=game:GetService("TeleportService")
local StarterGui=game:GetService("StarterGui")
local Debris=game:GetService("Debris")
local CollectionService=game:GetService("CollectionService")
local PhysicsService=game:GetService("PhysicsService")
local PathfindingService=game:GetService("PathfindingService")
local player=Players.LocalPlayer
local character=player.Character or player.CharacterAdded:Wait()
local humanoid=character:FindFirstChild("Humanoid")
local rootPart=character:FindFirstChild("HumanoidRootPart")
if not humanoid then repeat wait() humanoid=character:FindFirstChild("Humanoid") until humanoid end
if not rootPart then repeat wait() rootPart=character:FindFirstChild("HumanoidRootPart") until rootPart end
local function loadModule(name)
    local url=sh.BaseUrl..name..".lua"
    local success,result=pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    if success then
        return result
    else
        warn("[ShinnyX] Failed to load module: "..name.." - "..tostring(result))
        return nil
    end
end
local moduleNames={
    "GUI","Features","AutoFarm","AutoQuest","Teleport","ESP","Combat","Movement",
    "Items","Player","World","Settings","Utils","Animations","Notification","Keybind",
    "Logger","Library","AntiBan","Update","Fishing","Raid","SeaEvent","Stats","Misc",
    "MoonHop","MysteryIsland","VolcanoEvent","Leviathan","DracoRace"
}
local Modules={}
for _,name in ipairs(moduleNames) do
    local mod=loadModule(name)
    if mod then
        Modules[name]=mod
    else
        error("[ShinnyX] Cannot load "..name..", stopping script!")
    end
end
sh.Data={
    AutoFarm={
        enabled=false,targetType="Quái",targetName="",radius=500,speed=1,
        useSkill=true,collectItems=true,autoQuest=true,bossFarmEnabled=false,
        autoHealEnabled=false,autoBuyEnabled=false,autoStatsEnabled=false,
        healThreshold=30,autoCollectEnabled=true,autoSkillEnabled=true
    },
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
    Fishing={enabled=false,autoCast=true,autoReel=true,fishType="All",autoMove=true},
    Raid={enabled=false,autoStart=true,autoComplete=true,raidDifficulty="Normal",autoTeleport=true,autoFight=true,maxWaves=5,bossHealthThreshold=0.5},
    SeaEvent={enabled=false,autoFind=true,autoFight=true,autoCollect=true,autoTeleport=true,searchRadius=2000},
    Stats={enabled=false,autoAssign=true,statPriority="Melee",stats={Melee=0,Defense=0,Sword=0,Gun=0,Fruit=0}},
    Misc={autoSpin=false,dailyReward=false,giftCollect=false,autoBuy=false,autoBuyItem="Beli",autoBuyAmount=1},
    MoonHop={enabled=false,targetType="Full Moon",maxHops=50,hopDelay=2,checkInterval=1},
    MysteryIsland={enabled=false},
    VolcanoEvent={enabled=false,autoFind=true,autoStart=true,autoSealCracks=true,autoKillGolems=true,autoCollectBones=true,autoCollectEggs=true,autoMove=true},
    Leviathan={enabled=false,autoBribe=true,autoFindFrozen=true,autoSail=true,autoSpawn=true,autoFight=true,autoCollectHeart=true,autoReset=true,cooldown=1800,requiredGroupSize=5,requiredSeaEvents=10},
    Draco={enabled=false,autoCollectMaterials=true,autoUpgradeV2=true,autoUpgradeV3=true,autoUpgradeV4=true,autoLeviathan=true,autoOrb=true,autoTrial=true,autoPrimordialReign=true,autoDragonHeart=true,autoDragonStorm=true,autoTransform=true,autoFillGauge=true,collectEggs=true,collectBones=true,collectScales=true,collectEmbers=true,collectFireFlowers=true,autoUnlock=true}
}
local function initModules()
    for _,mod in pairs(Modules) do
        if mod and mod.Initialize then
            pcall(function()mod.Initialize(sh.Data)end)
        end
    end
    if Modules.GUI and Modules.GUI.Initialize then
        pcall(function()Modules.GUI.Initialize(sh.Data, Modules)end)
    end
end
local function startBackgroundTasks()
    task.spawn(function()
        while true do
            wait(0.1)
            if sh.Data.AutoFarm.enabled and Modules.AutoFarm and Modules.AutoFarm.Run then
                pcall(function()Modules.AutoFarm.Run(sh.Data.AutoFarm)end)
            end
            if sh.Data.AutoQuest.enabled and Modules.AutoQuest and Modules.AutoQuest.Run then
                pcall(function()Modules.AutoQuest.Run(sh.Data.AutoQuest)end)
            end
            if sh.Data.ESP.enabled and Modules.ESP and Modules.ESP.Update then
                pcall(function()Modules.ESP.Update(sh.Data.ESP)end)
            end
            if (sh.Data.Combat.autoAttack or sh.Data.Combat.spamSkill) and Modules.Combat and Modules.Combat.Run then
                pcall(function()Modules.Combat.Run(sh.Data.Combat)end)
            end
            if Modules.Movement and Modules.Movement.Apply then
                pcall(function()Modules.Movement.Apply(sh.Data.Movement)end)
            end
            if Modules.Player and Modules.Player.Apply then
                pcall(function()Modules.Player.Apply(sh.Data.Player)end)
            end
            if Modules.World and Modules.World.Apply then
                pcall(function()Modules.World.Apply(sh.Data.World)end)
            end
            if sh.Data.Items.autoCollect and Modules.Items and Modules.Items.AutoCollect then
                pcall(function()Modules.Items.AutoCollect(sh.Data.Items)end)
            end
            if sh.Data.Settings.antiAFK then
                pcall(function()
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton2(Vector2.new())
                end)
            end
            if Modules.Settings and Modules.Settings.Save then
                pcall(function()Modules.Settings.Save(sh.Data)end)
            end
            if sh.Data.Fishing.enabled and Modules.Fishing and Modules.Fishing.Run then
                pcall(function()Modules.Fishing.Run(sh.Data.Fishing)end)
            end
            if sh.Data.Raid.enabled and Modules.Raid and Modules.Raid.Run then
                pcall(function()Modules.Raid.Run(sh.Data.Raid)end)
            end
            if sh.Data.SeaEvent.enabled and Modules.SeaEvent and Modules.SeaEvent.Run then
                pcall(function()Modules.SeaEvent.Run(sh.Data.SeaEvent)end)
            end
            if sh.Data.Stats.enabled and Modules.Stats and Modules.Stats.Run then
                pcall(function()Modules.Stats.Run(sh.Data.Stats)end)
            end
            if sh.Data.Misc.autoSpin or sh.Data.Misc.dailyReward or sh.Data.Misc.giftCollect then
                if Modules.Misc and Modules.Misc.Run then
                    pcall(function()Modules.Misc.Run(sh.Data.Misc)end)
                end
            end
            if sh.Data.MoonHop.enabled and Modules.MoonHop and Modules.MoonHop.Run then
                pcall(function()Modules.MoonHop.Run(sh.Data.MoonHop)end)
            end
            if sh.Data.MysteryIsland.enabled and Modules.MysteryIsland and Modules.MysteryIsland.Run then
                pcall(function()Modules.MysteryIsland.Run(sh.Data.MysteryIsland)end)
            end
            if sh.Data.VolcanoEvent.enabled and Modules.VolcanoEvent and Modules.VolcanoEvent.Run then
                pcall(function()Modules.VolcanoEvent.Run(sh.Data.VolcanoEvent)end)
            end
            if sh.Data.Leviathan.enabled and Modules.Leviathan and Modules.Leviathan.Run then
                pcall(function()Modules.Leviathan.Run(sh.Data.Leviathan)end)
            end
            if sh.Data.Draco.enabled and Modules.DracoRace and Modules.DracoRace.Run then
                pcall(function()Modules.DracoRace.Run(sh.Data.Draco)end)
            end
        end
    end)
end
local function handleKeybinds()
    UserInputService.InputBegan:Connect(function(input,gameProcessed)
        if gameProcessed then return end
        local key=input.KeyCode
        if key==sh.Data.Keybind.toggleFarm then
            sh.Data.AutoFarm.enabled=not sh.Data.AutoFarm.enabled
        elseif key==sh.Data.Keybind.toggleFly then
            sh.Data.Movement.fly=not sh.Data.Movement.fly
        elseif key==sh.Data.Keybind.toggleESP then
            sh.Data.ESP.enabled=not sh.Data.ESP.enabled
        elseif key==sh.Data.Keybind.toggleGod then
            sh.Data.Player.godMode=not sh.Data.Player.godMode
        elseif key==sh.Data.Keybind.teleportHome then
            if Modules.Teleport and Modules.Teleport.TeleportHome then
                Modules.Teleport.TeleportHome()
            end
        elseif key==sh.Data.Keybind.toggleCombat then
            if Modules.Combat then sh.Data.Combat.autoAttack=not sh.Data.Combat.autoAttack end
        elseif key==sh.Data.Keybind.toggleNoclip then
            sh.Data.Movement.noclip=not sh.Data.Movement.noclip
        elseif key==sh.Data.Keybind.toggleSpeedHack then
            sh.Data.Movement.speedHack=not sh.Data.Movement.speedHack
        end
    end)
end
local function fallbackAll()
    task.spawn(function()
        while true do
            wait(0.5)
            if not Modules.ESP or not Modules.ESP.Update then
                if sh.Data.ESP.enabled then
                    for _,v in pairs(Workspace:GetChildren()) do
                        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("Head") then
                            if v.Name~=player.Name then
                                local bill=Instance.new("BillboardGui")
                                bill.Size=UDim2.new(0,2,0,2)
                                bill.AlwaysOnTop=true
                                bill.Parent=v.Head
                                local label=Instance.new("TextLabel")
                                label.Size=UDim2.new(1,0,1,0)
                                label.BackgroundTransparency=1
                                label.Text=v.Name
                                label.TextColor3=Color3.fromRGB(0,255,0)
                                label.TextScaled=true
                                label.Parent=bill
                                task.delay(0.1,function()bill:Destroy()end)
                            end
                        end
                    end
                end
            end
            if not Modules.AutoFarm or not Modules.AutoFarm.Run then
                if sh.Data.AutoFarm.enabled and rootPart then
                    local target=nil
                    local minDist=math.huge
                    for _,v in pairs(Workspace:GetChildren()) do
                        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("Head") and v.Name~=player.Name then
                            if sh.Data.AutoFarm.targetType=="Quái" and v:FindFirstChild("Humanoid").Health<1000 then
                                local dist=(rootPart.Position-v.Head.Position).Magnitude
                                if dist<minDist then
                                    minDist=dist
                                    target=v
                                end
                            end
                        end
                    end
                    if target and rootPart then
                        rootPart.CFrame=CFrame.new(target.Head.Position+Vector3.new(0,5,0))
                        if humanoid then humanoid:BreakJoints() end
                    end
                end
            end
            if not Modules.Movement or not Modules.Movement.Apply then
                if humanoid then
                    humanoid.WalkSpeed=sh.Data.Movement.walkSpeed
                    humanoid.JumpPower=sh.Data.Movement.jumpPower
                end
                if sh.Data.Movement.fly and rootPart then
                    rootPart.Velocity=Vector3.new(0,50,0)
                end
                if sh.Data.Movement.noclip then
                    for _,v in pairs(character:GetChildren()) do
                        if v:IsA("BasePart") then v.CanCollide=false end
                    end
                else
                    for _,v in pairs(character:GetChildren()) do
                        if v:IsA("BasePart") then v.CanCollide=true end
                    end
                end
            end
            if not Modules.Player or not Modules.Player.Apply then
                if sh.Data.Player.godMode and humanoid then
                    humanoid.Health=humanoid.MaxHealth
                    humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead,false)
                end
                if sh.Data.Player.infiniteEnergy and humanoid:FindFirstChild("Energy") then
                    humanoid.Energy.Value=999999
                end
                if sh.Data.Player.infiniteStamina and humanoid:FindFirstChild("Stamina") then
                    humanoid.Stamina.Value=999999
                end
            end
            if not Modules.World or not Modules.World.Apply then
                if sh.Data.World.timeOfDay=="Day" then Lighting.TimeOfDay="12:00:00"
                elseif sh.Data.World.timeOfDay=="Night" then Lighting.TimeOfDay="00:00:00"
                elseif sh.Data.World.timeOfDay=="Sunrise" then Lighting.TimeOfDay="06:00:00"
                elseif sh.Data.World.timeOfDay=="Sunset" then Lighting.TimeOfDay="18:00:00" end
                if sh.Data.World.weather=="Clear" then Lighting.Brightness=1
                elseif sh.Data.World.weather=="Rain" then Lighting.Brightness=0.5
                elseif sh.Data.World.weather=="Storm" then Lighting.Brightness=0.2
                elseif sh.Data.World.weather=="Fog" then Lighting.Brightness=0.3 end
                if sh.Data.World.fogEnabled then
                    Lighting.FogStart=sh.Data.World.fogStart
                    Lighting.FogEnd=sh.Data.World.fogEnd
                else
                    Lighting.FogStart=0
                    Lighting.FogEnd=10000
                end
            end
            if not Modules.Items or not Modules.Items.AutoCollect then
                if sh.Data.Items.autoCollect then
                    for _,v in pairs(Workspace:GetChildren()) do
                        if v:IsA("Part") and v:FindFirstChild("TouchInterest") then
                            if (rootPart.Position-v.Position).Magnitude<sh.Data.Items.collectRadius then
                                rootPart.CFrame=CFrame.new(v.Position)
                                wait(0.1)
                            end
                        end
                    end
                end
            end
            if not Modules.Combat or not Modules.Combat.Run then
                if sh.Data.Combat.autoAttack then
                    local target=nil
                    local minHealth=math.huge
                    for _,v in pairs(Workspace:GetChildren()) do
                        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("Head") and v.Name~=player.Name then
                            local health=v.Humanoid.Health
                            if health>0 and health<minHealth then
                                minHealth=health
                                target=v
                            end
                        end
                    end
                    if target and rootPart then
                        rootPart.CFrame=CFrame.new(target.Head.Position+Vector3.new(0,5,0))
                        wait(0.1)
                    end
                end
                if sh.Data.Combat.spamSkill then
                    local key=sh.Data.Combat.skillKey:lower()
                    UserInputService:SetKeyDown(Enum.KeyCode[key])
                    wait(0.05)
                    UserInputService:SetKeyUp(Enum.KeyCode[key])
                end
            end
            if not Modules.AutoQuest or not Modules.AutoQuest.Run then
                if sh.Data.AutoQuest.enabled then
                    local npc=nil
                    for _,v in pairs(Workspace:GetChildren()) do
                        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v.Name==sh.Data.AutoQuest.npcName then
                            npc=v
                            break
                        end
                    end
                    if npc and rootPart then
                        rootPart.CFrame=CFrame.new(npc.Head.Position+Vector3.new(0,3,0))
                        wait(0.5)
                        if humanoid then humanoid:BreakJoints() end
                    end
                end
            end
            if not Modules.Fishing or not Modules.Fishing.Run then
                if sh.Data.Fishing.enabled then
                    for _,v in pairs(Workspace:GetChildren()) do
                        if v:IsA("Model") and v.Name=="FishingSpot" then
                            rootPart.CFrame=CFrame.new(v.Position+Vector3.new(0,2,0))
                            wait(0.2)
                        end
                    end
                end
            end
            if not Modules.Raid or not Modules.Raid.Run then
                if sh.Data.Raid.enabled then
                    for _,v in pairs(Workspace:GetChildren()) do
                        if v:IsA("Model") and v.Name=="RaidPortal" then
                            rootPart.CFrame=CFrame.new(v.Position+Vector3.new(0,2,0))
                            if sh.Data.Raid.autoStart then
                                wait(0.5)
                            end
                        end
                    end
                    if sh.Data.Raid.autoComplete then
                        for _,v in pairs(Workspace:GetChildren()) do
                            if v:IsA("Model") and v:FindFirstChild("Humanoid") and v.Name:match("Boss") then
                                rootPart.CFrame=CFrame.new(v.Head.Position+Vector3.new(0,5,0))
                                if humanoid then humanoid:BreakJoints() end
                            end
                        end
                    end
                end
            end
            if not Modules.SeaEvent or not Modules.SeaEvent.Run then
                if sh.Data.SeaEvent.enabled then
                    for _,v in pairs(Workspace:GetChildren()) do
                        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v.Name:match("Sea") then
                            rootPart.CFrame=CFrame.new(v.Head.Position+Vector3.new(0,10,0))
                            if sh.Data.SeaEvent.autoFight then
                                if humanoid then humanoid:BreakJoints() end
                            end
                        end
                    end
                end
            end
            if not Modules.Stats or not Modules.Stats.Run then
                if sh.Data.Stats.enabled and sh.Data.Stats.autoAssign then
                    local priority=sh.Data.Stats.statPriority
                    local sp=player:FindFirstChild("StatPoints")
                    if sp and sp:IsA("NumberValue") and sp.Value>0 then
                        local stat=player:FindFirstChild(priority)
                        if stat and stat:IsA("NumberValue") then
                            stat.Value=stat.Value+sp.Value
                            sp.Value=0
                        end
                    end
                end
            end
            if not Modules.Misc or not Modules.Misc.Run then
                if sh.Data.Misc.autoSpin then
                    local gems=player:FindFirstChild("Gems")
                    if gems and gems:IsA("NumberValue") and gems.Value>=150 then
                        gems.Value=gems.Value-150
                    end
                end
                if sh.Data.Misc.dailyReward then
                    local b=Instance.new("Part")
                    b.Size=Vector3.new(1,1,1)
                    b.Position=rootPart.Position+Vector3.new(0,10,0)
                    b.Anchored=true
                    b.Parent=Workspace
                    wait(0.1)
                    b:Destroy()
                end
                if sh.Data.Misc.giftCollect then
                    for _,v in pairs(Workspace:GetChildren()) do
                        if v:IsA("Model") and v.Name:match("Gift") then
                            rootPart.CFrame=CFrame.new(v.Position+Vector3.new(0,2,0))
                        end
                    end
                end
            end
            if not Modules.MoonHop or not Modules.MoonHop.Run then
                if sh.Data.MoonHop.enabled then
                    local phase=math.floor((tonumber(string.sub(Lighting.TimeOfDay,1,2)) or 0)%8)
                    local targetPhases={}
                    if sh.Data.MoonHop.targetType=="Full Moon" then targetPhases={4}
                    elseif sh.Data.MoonHop.targetType=="Gần Full Moon" then targetPhases={2,3,4,5}
                    elseif sh.Data.MoonHop.targetType=="Trăng 1/5" then targetPhases={0,1}
                    elseif sh.Data.MoonHop.targetType=="Trăng 2/5" then targetPhases={2}
                    elseif sh.Data.MoonHop.targetType=="Trăng 3/5" then targetPhases={3} end
                    local isMatch=false
                    for _,p in ipairs(targetPhases) do
                        if phase==p then isMatch=true break end
                    end
                    if not isMatch then
                        TeleportService:Teleport(game.PlaceId,player,{},game.JobId)
                    end
                end
            end
            if not Modules.MysteryIsland or not Modules.MysteryIsland.Run then
                if sh.Data.MysteryIsland.enabled then
                    local island=nil
                    for _,v in pairs(Workspace:GetChildren()) do
                        if v:IsA("Model") and v:FindFirstChild("Head") and v.Name:lower():find("mysterious") then
                            island=v
                            break
                        end
                    end
                    if island then
                        local highestY=-math.huge
                        local highestPos=nil
                        local function scan(part)
                            if part:IsA("BasePart") then
                                if part.Position.Y>highestY then
                                    highestY=part.Position.Y
                                    highestPos=part.Position
                                end
                            end
                            for _,c in pairs(part:GetChildren()) do scan(c) end
                        end
                        scan(island)
                        if highestPos then
                            rootPart.CFrame=CFrame.new(highestPos+Vector3.new(0,3,0))
                            wait(1)
                        end
                    end
                end
            end
            if not Modules.VolcanoEvent or not Modules.VolcanoEvent.Run then
                if sh.Data.VolcanoEvent.enabled then
                    local volcano=nil
                    for _,v in pairs(Workspace:GetChildren()) do
                        if v:IsA("Model") and v:FindFirstChild("Head") and v.Name:lower():find("volcano") then
                            volcano=v
                            break
                        end
                    end
                    if volcano then
                        rootPart.CFrame=CFrame.new(volcano.Position+Vector3.new(0,5,0))
                        wait(0.5)
                        for _,v in pairs(Workspace:GetDescendants()) do
                            if v:IsA("Part") and v.Name:lower():find("bone") then
                                rootPart.CFrame=CFrame.new(v.Position)
                                wait(0.1)
                                v:Destroy()
                            end
                            if v:IsA("Part") and v.Name:lower():find("dragon") and v.Name:lower():find("egg") then
                                rootPart.CFrame=CFrame.new(v.Position)
                                wait(0.1)
                                v:Destroy()
                            end
                            if v:IsA("Part") and v.Name:lower():find("golem") and v:FindFirstAncestor("Model") then
                                local golem=v:FindFirstAncestor("Model")
                                if golem and golem:FindFirstChild("Humanoid") then
                                    rootPart.CFrame=CFrame.new(golem.Head.Position+Vector3.new(0,5,0))
                                    if humanoid then humanoid:BreakJoints() end
                                    wait(0.2)
                                end
                            end
                            if v:IsA("Part") and v.Name:lower():find("crack") then
                                rootPart.CFrame=CFrame.new(v.Position)
                                wait(0.2)
                            end
                        end
                    end
                end
            end
            if not Modules.Leviathan or not Modules.Leviathan.Run then
                if sh.Data.Leviathan.enabled then
                    local levi=findLeviathan()
                    if levi and levi:FindFirstChild("Humanoid") then
                        local health=levi.Humanoid.Health
                        if health>0 then
                            rootPart.CFrame=CFrame.new(levi.Head.Position+Vector3.new(0,10,0))
                            if humanoid then humanoid:BreakJoints() end
                            wait(0.5)
                        end
                    else
                        local spy=findSpy()
                        if spy then
                            rootPart.CFrame=CFrame.new(spy.Head.Position+Vector3.new(0,2,0))
                            wait(0.3)
                            if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
                        end
                        local frozen=findFrozenDimension()
                        if frozen then
                            rootPart.CFrame=CFrame.new(frozen.Position+Vector3.new(0,5,0))
                            wait(0.5)
                        end
                    end
                end
            end
            if not Modules.DracoRace or not Modules.DracoRace.Run then
                if sh.Data.Draco.enabled then
                    local wizard=findDragonWizard()
                    if wizard then
                        rootPart.CFrame=CFrame.new(wizard.Head.Position+Vector3.new(0,2,0))
                        wait(0.3)
                    end
                    local eggs=findDragonEggs()
                    for _,egg in ipairs(eggs) do
                        rootPart.CFrame=CFrame.new(egg.Position+Vector3.new(0,2,0))
                        wait(0.1)
                        egg:Destroy()
                    end
                    local bones=findDinosaurBones()
                    for _,bone in ipairs(bones) do
                        rootPart.CFrame=CFrame.new(bone.Position+Vector3.new(0,2,0))
                        wait(0.1)
                        bone:Destroy()
                    end
                end
            end
        end
    end)
end
local function main()
    initModules()
    startBackgroundTasks()
    handleKeybinds()
    fallbackAll()
    if Modules.Notification and Modules.Notification.Show then
        pcall(function()Modules.Notification.Show("ShinnyX Hub đã chạy!","Thành công")end)
    else
        print("ShinnyX Hub started")
    end
    print("ShinnyX Hub v"..sh.Version.." by Em Khang - hoạt động!")
end
player.OnTeleport:Connect(function(state)
    if Modules.Logger and Modules.Logger.Log then
        pcall(function()Modules.Logger.Log("Teleporting state: "..tostring(state))end)
    else
        print("Teleport state: "..tostring(state))
    end
end)
pcall(main)
return sh
