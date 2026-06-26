local sh={}
sh.Version="4.0.0"
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
local PlayersService=Players
local player=Players.LocalPlayer
local character=player.Character or player.CharacterAdded:Wait()
local humanoid=character:FindFirstChild("Humanoid")
local rootPart=character:FindFirstChild("HumanoidRootPart")
if not humanoid then repeat wait() humanoid=character:FindFirstChild("Humanoid") until humanoid end
if not rootPart then repeat wait() rootPart=character:FindFirstChild("HumanoidRootPart") until rootPart end
local function loadModule(name)
    local url=sh.BaseUrl..name..".lua"
    local success,result=pcall(function()return loadstring(game:HttpGet(url))()end)
    if success then return result else warn("[ShinnyX] Failed to load module: "..name) return nil end
end
local moduleNames={"GUI","Features","AutoFarm","AutoQuest","Teleport","ESP","Combat","Movement","Items","Player","World","Settings","Utils","Animations","Notification","Keybind","Logger","Library","AntiBan","Update","Fishing","Raid","SeaEvent","Stats","Misc"}
local Modules={}
for _,name in ipairs(moduleNames)do local mod=loadModule(name)if mod then Modules[name]=mod else error("[ShinnyX] Cannot load "..name)end end
sh.Data={
    AutoFarm={enabled=false,targetType="Quái",targetName="",radius=500,speed=1,useSkill=true,collectItems=true,autoQuest=false},
    AutoQuest={enabled=false,npcName="",questType="Daily",autoTurnIn=true},
    Teleport={targetPosition=Vector3.new(0,0,0),targetPlayer="",islandName="Jungle"},
    ESP={enabled=false,showPlayers=true,showFruits=true,showItems=false,showBoss=true,showNPC=false,distance=1000,colorPlayer=Color3.fromRGB(0,255,0),colorFruit=Color3.fromRGB(255,255,0),colorItem=Color3.fromRGB(0,100,255),colorBoss=Color3.fromRGB(255,0,0),colorNPC=Color3.fromRGB(200,200,200)},
    Combat={autoAttack=false,autoDodge=false,spamSkill=false,skillKey="Q",hitboxMultiplier=1,damageMultiplier=1,targetPriority="LowestHealth"},
    Movement={walkSpeed=16,jumpPower=50,fly=false,noclip=false,speedHack=false,swimSpeed=10},
    Items={spawnFruit="Leopard",spawnWeapon="Saber",autoCollect=false,collectRadius=2000,collectFilter="All"},
    Player={godMode=false,infiniteEnergy=false,infiniteStamina=false,infiniteMana=false,resetStats=false,maxHealth=999999,maxEnergy=999999},
    World={timeOfDay="Day",weather="Clear",fogEnabled=false,fogStart=0,fogEnd=1000},
    Settings={saveOnChange=true,autoUpdate=true,notifyOnLoad=true,defaultProfile="Profile1",antiAFK=true},
    Keybind={toggleFarm=Enum.KeyCode.F1,toggleFly=Enum.KeyCode.F2,toggleESP=Enum.KeyCode.F3,toggleGod=Enum.KeyCode.F4,teleportHome=Enum.KeyCode.F5},
    Fishing={enabled=false,autoCast=true,autoReel=true,fishType="All"},
    Raid={enabled=false,autoStart=true,autoComplete=true,raidDifficulty="Normal"},
    SeaEvent={enabled=false,autoFind=true,autoFight=true,eventType="All"},
    Stats={enabled=false,autoAssign=true,statPriority="Melee",stats={Melee=0,Defense=0,Sword=0,Gun=0,Fruit=0}},
    Misc={autoSpin=false,dailyReward=false,giftCollect=false,autoBuy=false}
}
local function initModules()
    for _,mod in pairs(Modules)do
        if mod and mod.Initialize then
            pcall(function()mod:Initialize(sh.Data)end)
        end
    end
end
local function startBackgroundTasks()
    task.spawn(function()
        while true do
            wait(0.1)
            if sh.Data.AutoFarm.enabled and Modules.AutoFarm and Modules.AutoFarm.Run then
                Modules.AutoFarm:Run(sh.Data.AutoFarm)
            end
            if sh.Data.AutoQuest.enabled and Modules.AutoQuest and Modules.AutoQuest.Run then
                Modules.AutoQuest:Run(sh.Data.AutoQuest)
            end
            if sh.Data.ESP.enabled and Modules.ESP and Modules.ESP.Update then
                Modules.ESP:Update(sh.Data.ESP)
            end
            if (sh.Data.Combat.autoAttack or sh.Data.Combat.spamSkill) and Modules.Combat and Modules.Combat.Run then
                Modules.Combat:Run(sh.Data.Combat)
            end
            if Modules.Movement and Modules.Movement.Apply then
                Modules.Movement:Apply(sh.Data.Movement)
            end
            if Modules.Player and Modules.Player.Apply then
                Modules.Player:Apply(sh.Data.Player)
            end
            if Modules.World and Modules.World.Apply then
                Modules.World:Apply(sh.Data.World)
            end
            if sh.Data.Items.autoCollect and Modules.Items and Modules.Items.AutoCollect then
                Modules.Items:AutoCollect(sh.Data.Items)
            end
            if sh.Data.Settings.antiAFK then
                pcall(function()
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton2(Vector2.new())
                end)
            end
            if Modules.Settings and Modules.Settings.Save then
                Modules.Settings:Save(sh.Data)
            end
            if sh.Data.Fishing.enabled and Modules.Fishing and Modules.Fishing.Run then
                Modules.Fishing:Run(sh.Data.Fishing)
            end
            if sh.Data.Raid.enabled and Modules.Raid and Modules.Raid.Run then
                Modules.Raid:Run(sh.Data.Raid)
            end
            if sh.Data.SeaEvent.enabled and Modules.SeaEvent and Modules.SeaEvent.Run then
                Modules.SeaEvent:Run(sh.Data.SeaEvent)
            end
            if sh.Data.Stats.enabled and Modules.Stats and Modules.Stats.Run then
                Modules.Stats:Run(sh.Data.Stats)
            end
            if sh.Data.Misc.autoSpin or sh.Data.Misc.dailyReward or sh.Data.Misc.giftCollect then
                if Modules.Misc and Modules.Misc.Run then
                    Modules.Misc:Run(sh.Data.Misc)
                end
            end
        end
    end)
end
local function fallbackESP()
    if not sh.Data.ESP.enabled then return end
    for _,v in pairs(Workspace:GetChildren())do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("Head") then
            local dist=(rootPart and rootPart.Position-v.Head.Position).Magnitude
            if dist<sh.Data.ESP.distance then
                if v.Name~=player.Name then
                    local bill=Instance.new("BillboardGui")
                    bill.Size=UDim2.new(0,2,0,2)
                    bill.AlwaysOnTop=true
                    bill.Parent=v.Head
                    local label=Instance.new("TextLabel")
                    label.Size=UDim2.new(1,0,1,0)
                    label.BackgroundTransparency=1
                    label.Text=v.Name.." "..math.floor(dist)
                    label.TextColor3=sh.Data.ESP.colorPlayer
                    label.TextScaled=true
                    label.Parent=bill
                    task.delay(0.1,function()bill:Destroy()end)
                end
            end
        end
    end
end
local function fallbackAutoFarm()
    if not sh.Data.AutoFarm.enabled then return end
    local target=nil
    local minDist=math.huge
    for _,v in pairs(Workspace:GetChildren())do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("Head") and v.Name~=player.Name then
            if sh.Data.AutoFarm.targetType=="Quái" and v:FindFirstChild("Humanoid").Health<1000 then
                local dist=(rootPart and rootPart.Position-v.Head.Position).Magnitude
                if dist<minDist then minDist=dist target=v end
            end
        end
    end
    if target and rootPart then
        rootPart.CFrame=CFrame.new(target.Head.Position+Vector3.new(0,5,0))
        if humanoid then humanoid:BreakJoints() end
    end
end
local function fallbackTeleport(pos)
    if rootPart then rootPart.CFrame=CFrame.new(pos) end
end
local function fallbackMovement()
    if humanoid then
        humanoid.WalkSpeed=sh.Data.Movement.walkSpeed
        humanoid.JumpPower=sh.Data.Movement.jumpPower
    end
    if sh.Data.Movement.fly and rootPart then
        rootPart.Velocity=Vector3.new(0,50,0)
    end
    if sh.Data.Movement.noclip then
        for _,v in pairs(character:GetChildren())do if v:IsA("BasePart") then v.CanCollide=false end end
    else
        for _,v in pairs(character:GetChildren())do if v:IsA("BasePart") then v.CanCollide=true end end
    end
end
local function fallbackPlayer()
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
local function fallbackWorld()
    if sh.Data.World.timeOfDay=="Day" then Lighting.TimeOfDay="12:00:00"
    elseif sh.Data.World.timeOfDay=="Night" then Lighting.TimeOfDay="00:00:00"
    elseif sh.Data.World.timeOfDay=="Sunrise" then Lighting.TimeOfDay="06:00:00"
    elseif sh.Data.World.timeOfDay=="Sunset" then Lighting.TimeOfDay="18:00:00" end
    if sh.Data.World.weather=="Clear" then Lighting.Brightness=1
    elseif sh.Data.World.weather=="Rain" then Lighting.Brightness=0.5
    elseif sh.Data.World.weather=="Storm" then Lighting.Brightness=0.2
    elseif sh.Data.World.weather=="Fog" then Lighting.Brightness=0.3 end
    if sh.Data.World.fogEnabled then Lighting.FogStart=sh.Data.World.fogStart Lighting.FogEnd=sh.Data.World.fogEnd
    else Lighting.FogStart=0 Lighting.FogEnd=10000 end
end
local function fallbackItems()
    if sh.Data.Items.autoCollect then
        for _,v in pairs(Workspace:GetChildren())do
            if v:IsA("Part") and v:FindFirstChild("TouchInterest") then
                local dist=(rootPart and rootPart.Position-v.Position).Magnitude
                if dist<sh.Data.Items.collectRadius then
                    rootPart.CFrame=CFrame.new(v.Position)
                    wait(0.1)
                end
            end
        end
    end
end
local function fallbackCombat()
    if sh.Data.Combat.autoAttack then
        local target=nil
        local minHealth=math.huge
        for _,v in pairs(Workspace:GetChildren())do
            if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("Head") and v.Name~=player.Name then
                local health=v.Humanoid.Health
                if health>0 and health<minHealth then minHealth=health target=v end
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
local function fallbackAutoQuest()
    if not sh.Data.AutoQuest.enabled then return end
    local npc=nil
    for _,v in pairs(Workspace:GetChildren())do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v.Name==sh.Data.AutoQuest.npcName then npc=v break end
    end
    if npc and rootPart then
        rootPart.CFrame=CFrame.new(npc.Head.Position+Vector3.new(0,3,0))
        wait(0.5)
        if humanoid then humanoid:BreakJoints() end
    end
end
local function fallbackFishing()
    if not sh.Data.Fishing.enabled then return end
    for _,v in pairs(Workspace:GetChildren())do
        if v:IsA("Model") and v.Name=="FishingSpot" then
            rootPart.CFrame=CFrame.new(v.Position+Vector3.new(0,2,0))
            wait(0.2)
            if sh.Data.Fishing.autoCast then
                local b=Instance.new("Part")
                b.Size=Vector3.new(1,1,1)
                b.Position=rootPart.Position+Vector3.new(0,5,0)
                b.Anchored=true
                b.Parent=Workspace
                wait(0.1)
                b:Destroy()
            end
            if sh.Data.Fishing.autoReel then
                wait(2)
            end
        end
    end
end
local function fallbackRaid()
    if not sh.Data.Raid.enabled then return end
    for _,v in pairs(Workspace:GetChildren())do
        if v:IsA("Model") and v.Name=="RaidPortal" then
            rootPart.CFrame=CFrame.new(v.Position+Vector3.new(0,2,0))
            if sh.Data.Raid.autoStart then
                wait(0.5)
                local b=Instance.new("Part")
                b.Size=Vector3.new(2,2,2)
                b.Position=rootPart.Position+Vector3.new(0,3,0)
                b.Anchored=true
                b.Parent=Workspace
                wait(0.2)
                b:Destroy()
            end
        end
    end
    if sh.Data.Raid.autoComplete then
        for _,v in pairs(Workspace:GetChildren())do
            if v:IsA("Model") and v:FindFirstChild("Humanoid") and v.Name:match("Boss") then
                rootPart.CFrame=CFrame.new(v.Head.Position+Vector3.new(0,5,0))
                if humanoid then humanoid:BreakJoints() end
            end
        end
    end
end
local function fallbackSeaEvent()
    if not sh.Data.SeaEvent.enabled then return end
    for _,v in pairs(Workspace:GetChildren())do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v.Name:match("Sea") then
            rootPart.CFrame=CFrame.new(v.Head.Position+Vector3.new(0,10,0))
            if sh.Data.SeaEvent.autoFight then
                if humanoid then humanoid:BreakJoints() end
            end
        end
    end
end
local function fallbackStats()
    if not sh.Data.Stats.enabled then return end
    if sh.Data.Stats.autoAssign then
        local priority=sh.Data.Stats.statPriority
        for _,v in pairs(player:GetChildren())do
            if v:IsA("IntValue") and v.Name:match("Stat") then
                if priority=="Melee" and v.Name=="Melee" then v.Value=v.Value+1
                elseif priority=="Defense" and v.Name=="Defense" then v.Value=v.Value+1
                elseif priority=="Sword" and v.Name=="Sword" then v.Value=v.Value+1
                elseif priority=="Gun" and v.Name=="Gun" then v.Value=v.Value+1
                elseif priority=="Fruit" and v.Name=="Fruit" then v.Value=v.Value+1 end
            end
        end
    end
end
local function fallbackMisc()
    if sh.Data.Misc.autoSpin then
        for _,v in pairs(player:GetChildren())do
            if v:IsA("IntValue") and v.Name=="Gems" then
                if v.Value>=150 then v.Value=v.Value-150 end
            end
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
        for _,v in pairs(Workspace:GetChildren())do
            if v:IsA("Model") and v.Name:match("Gift") then
                rootPart.CFrame=CFrame.new(v.Position+Vector3.new(0,2,0))
            end
        end
    end
end
local function handleKeybinds()
    UserInputService.InputBegan:Connect(function(input,gameProcessed)
        if gameProcessed then return end
        local key=input.KeyCode
        if key==sh.Data.Keybind.toggleFarm then sh.Data.AutoFarm.enabled=not sh.Data.AutoFarm.enabled
        elseif key==sh.Data.Keybind.toggleFly then sh.Data.Movement.fly=not sh.Data.Movement.fly
        elseif key==sh.Data.Keybind.toggleESP then sh.Data.ESP.enabled=not sh.Data.ESP.enabled
        elseif key==sh.Data.Keybind.toggleGod then sh.Data.Player.godMode=not sh.Data.Player.godMode
        elseif key==sh.Data.Keybind.teleportHome then fallbackTeleport(Vector3.new(0,10,0)) end
    end)
end
local function startFallbackLoop()
    task.spawn(function()
        while true do
            wait(0.5)
            if not Modules.ESP or not Modules.ESP.Update then fallbackESP() end
            if not Modules.AutoFarm or not Modules.AutoFarm.Run then fallbackAutoFarm() end
            if not Modules.Movement or not Modules.Movement.Apply then fallbackMovement() end
            if not Modules.Player or not Modules.Player.Apply then fallbackPlayer() end
            if not Modules.World or not Modules.World.Apply then fallbackWorld() end
            if not Modules.Items or not Modules.Items.AutoCollect then fallbackItems() end
            if not Modules.Combat or not Modules.Combat.Run then fallbackCombat() end
            if not Modules.AutoQuest or not Modules.AutoQuest.Run then fallbackAutoQuest() end
            if not Modules.Fishing or not Modules.Fishing.Run then fallbackFishing() end
            if not Modules.Raid or not Modules.Raid.Run then fallbackRaid() end
            if not Modules.SeaEvent or not Modules.SeaEvent.Run then fallbackSeaEvent() end
            if not Modules.Stats or not Modules.Stats.Run then fallbackStats() end
            if not Modules.Misc or not Modules.Misc.Run then fallbackMisc() end
        end
    end)
end
local function createFallbackGUI()
    local screenGui=Instance.new("ScreenGui")
    screenGui.Name="ShinnyXHubFallback"
    screenGui.Parent=player.PlayerGui
    local main=Instance.new("Frame")
    main.Size=UDim2.new(0,300,0,400)
    main.Position=UDim2.new(0.5,-150,0.5,-200)
    main.BackgroundColor3=Color3.fromRGB(10,10,20)
    main.BackgroundTransparency=0.2
    main.Parent=screenGui
    local title=Instance.new("TextLabel")
    title.Size=UDim2.new(1,0,0,40)
    title.Text="ShinnyX Hub"
    title.TextColor3=Color3.fromRGB(0,200,255)
    title.TextScaled=true
    title.Parent=main
    local status=Instance.new("TextLabel")
    status.Size=UDim2.new(1,0,0,30)
    status.Position=UDim2.new(0,0,0,40)
    status.Text="Đang chạy fallback - không có module"
    status.TextColor3=Color3.fromRGB(255,255,255)
    status.Parent=main
    local btn=Instance.new("TextButton")
    btn.Size=UDim2.new(0,100,0,30)
    btn.Position=UDim2.new(0.5,-50,0,80)
    btn.Text="Toggle Farm"
    btn.Parent=main
    btn.MouseButton1Click:Connect(function()
        sh.Data.AutoFarm.enabled=not sh.Data.AutoFarm.enabled
        status.Text=sh.Data.AutoFarm.enabled and "Farm ON" or "Farm OFF"
    end)
end
local function main()
    initModules()
    startBackgroundTasks()
    handleKeybinds()
    startFallbackLoop()
    if not Modules.GUI or not Modules.GUI.Create then createFallbackGUI() end
    if Modules.Notification and Modules.Notification.Show then
        Modules.Notification:Show("ShinnyX Hub đã chạy!","Thành công")
    else
        print("ShinnyX Hub started")
    end
    print("ShinnyX Hub v"..sh.Version.." by Em Khang - hoạt động!")
end
player.OnTeleport:Connect(function(state)
    if Modules.Logger and Modules.Logger.Log then
        Modules.Logger:Log("Teleporting state: "..tostring(state))
    else
        print("Teleport state: "..tostring(state))
    end
end)
pcall(main)
return sh
