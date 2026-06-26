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
local player=Players.LocalPlayer
local character=player.Character or player.CharacterAdded:Wait()
local humanoid=character:FindFirstChild("Humanoid")
local rootPart=character:FindFirstChild("HumanoidRootPart")
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
local moduleNames={"GUI","Features","AutoFarm","AutoQuest","Teleport","ESP","Combat","Movement","Items","Player","World","Settings","Utils","Animations","Notification","Keybind","Logger","Library","AntiBan","Update"}
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
        enabled=false,
        targetType="Quái",
        targetName="",
        radius=500,
        speed=1,
        useSkill=true,
        collectItems=true,
        autoQuest=false
    },
    AutoQuest={
        enabled=false,
        npcName="",
        questType="Daily",
        autoTurnIn=true
    },
    Teleport={
        targetPosition=Vector3.new(0,0,0),
        targetPlayer="",
        islandName="Jungle"
    },
    ESP={
        enabled=false,
        showPlayers=true,
        showFruits=true,
        showItems=false,
        showBoss=true,
        showNPC=false,
        distance=1000,
        colorPlayer=Color3.fromRGB(0,255,0),
        colorFruit=Color3.fromRGB(255,255,0),
        colorItem=Color3.fromRGB(0,100,255),
        colorBoss=Color3.fromRGB(255,0,0),
        colorNPC=Color3.fromRGB(200,200,200)
    },
    Combat={
        autoAttack=false,
        autoDodge=false,
        spamSkill=false,
        skillKey="Q",
        hitboxMultiplier=1,
        damageMultiplier=1,
        targetPriority="LowestHealth"
    },
    Movement={
        walkSpeed=16,
        jumpPower=50,
        fly=false,
        noclip=false,
        speedHack=false,
        swimSpeed=10
    },
    Items={
        spawnFruit="Leopard",
        spawnWeapon="Saber",
        autoCollect=false,
        collectRadius=2000,
        collectFilter="All"
    },
    Player={
        godMode=false,
        infiniteEnergy=false,
        infiniteStamina=false,
        infiniteMana=false,
        resetStats=false,
        maxHealth=999999,
        maxEnergy=999999
    },
    World={
        timeOfDay="Day",
        weather="Clear",
        fogEnabled=false,
        fogStart=0,
        fogEnd=1000
    },
    Settings={
        saveOnChange=true,
        autoUpdate=true,
        notifyOnLoad=true,
        defaultProfile="Profile1",
        antiAFK=true,
        keybinds={
            toggleFarm=Enum.KeyCode.F1,
            toggleFly=Enum.KeyCode.F2,
            toggleESP=Enum.KeyCode.F3,
            toggleGod=Enum.KeyCode.F4,
            teleportHome=Enum.KeyCode.F5
        }
    },
    Keybind={
        toggleFarm=Enum.KeyCode.F1,
        toggleFly=Enum.KeyCode.F2,
        toggleESP=Enum.KeyCode.F3,
        toggleGod=Enum.KeyCode.F4,
        teleportHome=Enum.KeyCode.F5
    }
}
local function initModules()
    if Modules.Utils and Modules.Utils.Initialize then
        Modules.Utils:Initialize(sh.Data)
    end
    if Modules.Logger and Modules.Logger.Initialize then
        Modules.Logger:Initialize(sh.Data)
    end
    if Modules.AntiBan and Modules.AntiBan.Initialize then
        Modules.AntiBan:Initialize(sh.Data)
    end
    if Modules.Features and Modules.Features.Initialize then
        Modules.Features:Initialize(sh.Data, Modules)
    end
    if Modules.Settings and Modules.Settings.Load then
        Modules.Settings:Load(sh.Data)
    end
    if Modules.GUI and Modules.GUI.Create then
        Modules.GUI:Create(sh.Data, Modules)
    end
    if Modules.Keybind and Modules.Keybind.Initialize then
        Modules.Keybind:Initialize(sh.Data, Modules)
    end
    if Modules.Notification and Modules.Notification.Initialize then
        Modules.Notification:Initialize(sh.Data)
    end
    if Modules.Update and Modules.Update.CheckForUpdate then
        Modules.Update:CheckForUpdate(sh)
    end
    if Modules.Library and Modules.Library.Initialize then
        Modules.Library:Initialize(sh.Data)
    end
    if Modules.Animations and Modules.Animations.Initialize then
        Modules.Animations:Initialize()
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
        end
    end)
end
local function fallbackESP()
    if not sh.Data.ESP.enabled then return end
    for _,v in pairs(Workspace:GetChildren()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("Head") then
            local dist=(rootPart and rootPart.Position-v:FindFirstChild("Head").Position).Magnitude
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
                    task.delay(0.1,function()
                        bill:Destroy()
                    end)
                end
            end
        end
    end
end
local function fallbackAutoFarm()
    if not sh.Data.AutoFarm.enabled then return end
    local target=nil
    local minDist=math.huge
    for _,v in pairs(Workspace:GetChildren()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("Head") and v.Name~=player.Name then
            if sh.Data.AutoFarm.targetType=="Quái" and v:FindFirstChild("Humanoid").Health<1000 then
                local dist=(rootPart and rootPart.Position-v.Head.Position).Magnitude
                if dist<minDist then
                    minDist=dist
                    target=v
                end
            end
        end
    end
    if target and rootPart then
        rootPart.CFrame=CFrame.new(target.Head.Position+Vector3.new(0,5,0))
        if humanoid and humanoid:FindFirstChild("Health") then
            humanoid:BreakJoints()
        end
    end
end
local function fallbackTeleport(pos)
    if rootPart then
        rootPart.CFrame=CFrame.new(pos)
    end
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
        for _,v in pairs(character:GetChildren()) do
            if v:IsA("BasePart") then
                v.CanCollide=false
            end
        end
    else
        for _,v in pairs(character:GetChildren()) do
            if v:IsA("BasePart") then
                v.CanCollide=true
            end
        end
    end
end
local function fallbackPlayer()
    if sh.Data.Player.godMode and humanoid then
        humanoid.Health=humanoid.MaxHealth
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead,false)
    end
    if sh.Data.Player.infiniteEnergy then
        if humanoid:FindFirstChild("Energy") then
            humanoid.Energy.Value=999999
        end
    end
    if sh.Data.Player.infiniteStamina then
        if humanoid:FindFirstChild("Stamina") then
            humanoid.Stamina.Value=999999
        end
    end
end
local function fallbackWorld()
    if sh.Data.World.timeOfDay=="Day" then
        Lighting.TimeOfDay="12:00:00"
    elseif sh.Data.World.timeOfDay=="Night" then
        Lighting.TimeOfDay="00:00:00"
    elseif sh.Data.World.timeOfDay=="Sunrise" then
        Lighting.TimeOfDay="06:00:00"
    elseif sh.Data.World.timeOfDay=="Sunset" then
        Lighting.TimeOfDay="18:00:00"
    end
    if sh.Data.World.weather=="Clear" then
        Lighting.Brightness=1
    elseif sh.Data.World.weather=="Rain" then
        Lighting.Brightness=0.5
    elseif sh.Data.World.weather=="Storm" then
        Lighting.Brightness=0.2
    elseif sh.Data.World.weather=="Fog" then
        Lighting.Brightness=0.3
    end
    if sh.Data.World.fogEnabled then
        Lighting.FogStart=sh.Data.World.fogStart
        Lighting.FogEnd=sh.Data.World.fogEnd
    else
        Lighting.FogStart=0
        Lighting.FogEnd=10000
    end
end
local function fallbackItems()
    if sh.Data.Items.autoCollect then
        for _,v in pairs(Workspace:GetChildren()) do
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
local function fallbackAutoQuest()
    if not sh.Data.AutoQuest.enabled then return end
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
        if humanoid then
            humanoid:BreakJoints()
        end
    end
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
            local home=Vector3.new(0,10,0)
            fallbackTeleport(home)
        end
    end)
end
local function main()
    initModules()
    startBackgroundTasks()
    handleKeybinds()
    task.spawn(function()
        while true do
            wait(0.5)
            if not Modules.ESP or not Modules.ESP.Update then
                fallbackESP()
            end
            if not Modules.AutoFarm or not Modules.AutoFarm.Run then
                fallbackAutoFarm()
            end
            if not Modules.Movement or not Modules.Movement.Apply then
                fallbackMovement()
            end
            if not Modules.Player or not Modules.Player.Apply then
                fallbackPlayer()
            end
            if not Modules.World or not Modules.World.Apply then
                fallbackWorld()
            end
            if not Modules.Items or not Modules.Items.AutoCollect then
                fallbackItems()
            end
            if not Modules.Combat or not Modules.Combat.Run then
                fallbackCombat()
            end
            if not Modules.AutoQuest or not Modules.AutoQuest.Run then
                fallbackAutoQuest()
            end
        end
    end)
    if Modules.Notification and Modules.Notification.Show then
        Modules.Notification:Show("ShinnyX Hub đã chạy!","Thành công")
    else
        print("ShinnyX Hub started - no notification module")
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
