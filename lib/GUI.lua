local gui={}
gui.__index=gui
local player=game.Players.LocalPlayer
local runService=game:GetService("RunService")
local userInput=game:GetService("UserInputService")
local tweenService=game:GetService("TweenService")
local coreGui=game:GetService("CoreGui")
local isAdmin=false
local authCompleted=false

local function createAuthGUI(data, modules, callback)
    local screenGui=Instance.new("ScreenGui")
    screenGui.Name="ShinnyXAuth"
    screenGui.Parent=coreGui
    screenGui.ResetOnSpawn=false
    local mainFrame=Instance.new("Frame")
    mainFrame.Size=UDim2.new(0,400,0,320)
    mainFrame.Position=UDim2.new(0.5,-200,0.5,-160)
    mainFrame.BackgroundColor3=Color3.fromRGB(10,10,30)
    mainFrame.BackgroundTransparency=0.2
    mainFrame.BorderSizePixel=0
    mainFrame.ClipsDescendants=true
    mainFrame.Parent=screenGui
    local glass=Instance.new("ImageLabel")
    glass.Size=UDim2.new(1,0,1,0)
    glass.Image="rbxassetid://14859610560"
    glass.BackgroundTransparency=1
    glass.Parent=mainFrame
    local title=Instance.new("TextLabel")
    title.Size=UDim2.new(1,0,0,50)
    title.BackgroundTransparency=1
    title.Text="ShinnyX Hub - Xác thực"
    title.TextColor3=Color3.fromRGB(0,200,255)
    title.TextScaled=true
    title.Font=Enum.Font.GothamBold
    title.Parent=mainFrame
    local userLabel=Instance.new("TextLabel")
    userLabel.Size=UDim2.new(0.3,0,0,30)
    userLabel.Position=UDim2.new(0.05,0,0.2,0)
    userLabel.BackgroundTransparency=1
    userLabel.Text="User:"
    userLabel.TextColor3=Color3.fromRGB(255,255,255)
    userLabel.TextScaled=true
    userLabel.Parent=mainFrame
    local userBox=Instance.new("TextBox")
    userBox.Size=UDim2.new(0.6,0,0,30)
    userBox.Position=UDim2.new(0.35,0,0.2,0)
    userBox.BackgroundColor3=Color3.fromRGB(30,30,60)
    userBox.Text=""
    userBox.TextColor3=Color3.fromRGB(255,255,255)
    userBox.Parent=mainFrame
    local passLabel=Instance.new("TextLabel")
    passLabel.Size=UDim2.new(0.3,0,0,30)
    passLabel.Position=UDim2.new(0.05,0,0.4,0)
    passLabel.BackgroundTransparency=1
    passLabel.Text="Password:"
    passLabel.TextColor3=Color3.fromRGB(255,255,255)
    passLabel.TextScaled=true
    passLabel.Parent=mainFrame
    local passBox=Instance.new("TextBox")
    passBox.Size=UDim2.new(0.6,0,0,30)
    passBox.Position=UDim2.new(0.35,0,0.4,0)
    passBox.BackgroundColor3=Color3.fromRGB(30,30,60)
    passBox.Text=""
    passBox.TextColor3=Color3.fromRGB(255,255,255)
    passBox.Parent=mainFrame
    passBox.PlaceholderText="********"
    local adminBtn=Instance.new("TextButton")
    adminBtn.Size=UDim2.new(0.4,0,0,40)
    adminBtn.Position=UDim2.new(0.05,0,0.65,0)
    adminBtn.BackgroundColor3=Color3.fromRGB(40,40,80)
    adminBtn.Text="ADMIN"
    adminBtn.TextColor3=Color3.fromRGB(255,255,255)
    adminBtn.Parent=mainFrame
    adminBtn.MouseButton1Click:Connect(function()
        local user=userBox.Text
        local pass=passBox.Text
        if user=="kendepzaiadmin123@" and pass=="aminkendepzai123@" then
            screenGui:Destroy()
            callback(true)
        else
            local err=Instance.new("TextLabel")
            err.Size=UDim2.new(1,0,0,20)
            err.Position=UDim2.new(0,0,0.6,0)
            err.BackgroundTransparency=1
            err.Text="Sai user hoặc password!"
            err.TextColor3=Color3.fromRGB(255,0,0)
            err.TextScaled=true
            err.Parent=mainFrame
            task.delay(2,function()err:Destroy()end)
        end
    end)
    local normalBtn=Instance.new("TextButton")
    normalBtn.Size=UDim2.new(0.4,0,0,40)
    normalBtn.Position=UDim2.new(0.55,0,0.65,0)
    normalBtn.BackgroundColor3=Color3.fromRGB(40,40,80)
    normalBtn.Text="Menu thường"
    normalBtn.TextColor3=Color3.fromRGB(255,255,255)
    normalBtn.Parent=mainFrame
    normalBtn.MouseButton1Click:Connect(function()
        screenGui:Destroy()
        callback(false)
    end)
end

local function createToggle(parent,label,default,callback)
    local frame=Instance.new("Frame")
    frame.Size=UDim2.new(1,0,0,30)
    frame.BackgroundTransparency=1
    frame.Parent=parent
    local lbl=Instance.new("TextLabel")
    lbl.Size=UDim2.new(0.7,0,1,0)
    lbl.BackgroundTransparency=1
    lbl.Text=label
    lbl.TextColor3=Color3.fromRGB(255,255,255)
    lbl.TextXAlignment=Enum.TextXAlignment.Left
    lbl.Parent=frame
    local toggle=Instance.new("TextButton")
    toggle.Size=UDim2.new(0.2,0,1,0)
    toggle.Position=UDim2.new(0.8,0,0,0)
    toggle.BackgroundColor3=default and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0)
    toggle.Text=default and"ON"or"OFF"
    toggle.TextColor3=Color3.fromRGB(255,255,255)
    toggle.Parent=frame
    toggle.MouseButton1Click:Connect(function()
        default=not default
        toggle.BackgroundColor3=default and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0)
        toggle.Text=default and"ON"or"OFF"
        callback(default)
    end)
    return toggle
end
local function createSlider(parent,label,min,max,default,callback)
    local frame=Instance.new("Frame")
    frame.Size=UDim2.new(1,0,0,40)
    frame.BackgroundTransparency=1
    frame.Parent=parent
    local lbl=Instance.new("TextLabel")
    lbl.Size=UDim2.new(0.6,0,0.5,0)
    lbl.BackgroundTransparency=1
    lbl.Text=label..": "..string.format("%.1f",default)
    lbl.TextColor3=Color3.fromRGB(255,255,255)
    lbl.TextXAlignment=Enum.TextXAlignment.Left
    lbl.Parent=frame
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
            lbl.Text=label..": "..string.format("%.1f",val)
            callback(val)
        end
    end)
    return sliderBg
end
local function createDropdown(parent,label,items,default,callback)
    local frame=Instance.new("Frame")
    frame.Size=UDim2.new(1,0,0,30)
    frame.BackgroundTransparency=1
    frame.Parent=parent
    local lbl=Instance.new("TextLabel")
    lbl.Size=UDim2.new(0.4,0,1,0)
    lbl.BackgroundTransparency=1
    lbl.Text=label
    lbl.TextColor3=Color3.fromRGB(255,255,255)
    lbl.TextXAlignment=Enum.TextXAlignment.Left
    lbl.Parent=frame
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
    for _,item in ipairs(items)do
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
        if listFrame.Visible then listFrame.Size=UDim2.new(0.5,0,0,#items*25) else listFrame.Size=UDim2.new(0.5,0,0,0) end
    end)
    return dropdown
end
local function createButton(parent,label,callback)
    local btn=Instance.new("TextButton")
    btn.Size=UDim2.new(1,0,0,30)
    btn.BackgroundColor3=Color3.fromRGB(40,40,80)
    btn.Text=label
    btn.TextColor3=Color3.fromRGB(255,255,255)
    btn.Parent=parent
    btn.MouseButton1Click:Connect(callback)
    return btn
end
local function createTextBox(parent,label,default,callback)
    local frame=Instance.new("Frame")
    frame.Size=UDim2.new(1,0,0,30)
    frame.BackgroundTransparency=1
    frame.Parent=parent
    local lbl=Instance.new("TextLabel")
    lbl.Size=UDim2.new(0.3,0,1,0)
    lbl.BackgroundTransparency=1
    lbl.Text=label
    lbl.TextColor3=Color3.fromRGB(255,255,255)
    lbl.TextXAlignment=Enum.TextXAlignment.Left
    lbl.Parent=frame
    local box=Instance.new("TextBox")
    box.Size=UDim2.new(0.6,0,1,0)
    box.Position=UDim2.new(0.4,0,0,0)
    box.BackgroundColor3=Color3.fromRGB(30,30,60)
    box.Text=default
    box.TextColor3=Color3.fromRGB(255,255,255)
    box.Parent=frame
    box.FocusLost:Connect(function(enter)if enter then callback(box.Text)end end)
    return box
end

local function buildTab(tabName,data,modules,isAdmin)
    local content=Instance.new("ScrollingFrame")
    content.Size=UDim2.new(1,-10,1,-110)
    content.Position=UDim2.new(0,5,0,90)
    content.BackgroundColor3=Color3.fromRGB(20,20,40)
    content.BackgroundTransparency=0.5
    content.BorderSizePixel=0
    content.Parent=Instance.new("Frame")
    content.CanvasSize=UDim2.new(0,0,0,0)
    content.ScrollBarThickness=6
    local layout=Instance.new("UIListLayout")
    layout.Parent=content
    layout.SortOrder=Enum.SortOrder.LayoutOrder
    layout.Padding=UDim.new(0,5)
    if tabName=="Farm"then
        createToggle(content,"Bật Auto Farm",data.AutoFarm.enabled,function(val)data.AutoFarm.enabled=val;if modules.Settings then modules.Settings:Save(data)end end)
        createDropdown(content,"Loại mục tiêu",{"Quái","Boss","NPC"},data.AutoFarm.targetType,function(val)data.AutoFarm.targetType=val;if modules.Settings then modules.Settings:Save(data)end end)
        createSlider(content,"Bán kính",100,2000,data.AutoFarm.radius,function(val)data.AutoFarm.radius=val;if modules.Settings then modules.Settings:Save(data)end end)
        createSlider(content,"Tốc độ",0.5,5,data.AutoFarm.speed,function(val)data.AutoFarm.speed=val;if modules.Settings then modules.Settings:Save(data)end end)
        createToggle(content,"Dùng skill",data.AutoFarm.useSkill,function(val)data.AutoFarm.useSkill=val;if modules.Settings then modules.Settings:Save(data)end end)
        createToggle(content,"Nhặt vật phẩm",data.AutoFarm.collectItems,function(val)data.AutoFarm.collectItems=val;if modules.Settings then modules.Settings:Save(data)end end)
    elseif tabName=="Quest"then
        createToggle(content,"Bật Auto Quest",data.AutoQuest.enabled,function(val)data.AutoQuest.enabled=val;if modules.Settings then modules.Settings:Save(data)end end)
        createTextBox(content,"Tên NPC",data.AutoQuest.npcName,function(val)data.AutoQuest.npcName=val;if modules.Settings then modules.Settings:Save(data)end end)
        createDropdown(content,"Loại quest",{"Normal","Daily"},data.AutoQuest.questType,function(val)data.AutoQuest.questType=val;if modules.Settings then modules.Settings:Save(data)end end)
        createToggle(content,"Tự động nộp",data.AutoQuest.autoTurnIn,function(val)data.AutoQuest.autoTurnIn=val;if modules.Settings then modules.Settings:Save(data)end end)
    elseif tabName=="Teleport"then
        createTextBox(content,"Tọa độ (x,y,z)",tostring(data.Teleport.targetPosition),function(val)local t={}for num in string.gmatch(val,"([^,]+)")do table.insert(t,tonumber(num))end if #t==3 then data.Teleport.targetPosition=Vector3.new(t[1],t[2],t[3]);if modules.Settings then modules.Settings:Save(data)end end end)
        createButton(content,"Dịch chuyển đến tọa độ",function()if modules.Teleport and modules.Teleport.TeleportTo then modules.Teleport:TeleportTo(data.Teleport.targetPosition)elseif rootPart then rootPart.CFrame=CFrame.new(data.Teleport.targetPosition)end end)
        createButton(content,"Dịch chuyển về nhà",function()local home=Vector3.new(0,10,0);if modules.Teleport then modules.Teleport:TeleportTo(home)elseif rootPart then rootPart.CFrame=CFrame.new(home)end end)
        local islands={"Jungle","Pirate","Marine","Sky","Magma","Ice","Desert"}
        for _,name in ipairs(islands)do createButton(content,"→ "..name,function()local pos=nil;if name=="Jungle"then pos=Vector3.new(-1000,50,0)elseif name=="Pirate"then pos=Vector3.new(0,50,1000)elseif name=="Marine"then pos=Vector3.new(1000,50,0)elseif name=="Sky"then pos=Vector3.new(0,500,0)elseif name=="Magma"then pos=Vector3.new(-500,50,-500)elseif name=="Ice"then pos=Vector3.new(500,50,-500)elseif name=="Desert"then pos=Vector3.new(0,50,-1000)end;if pos then if modules.Teleport then modules.Teleport:TeleportTo(pos)elseif rootPart then rootPart.CFrame=CFrame.new(pos)end;data.Teleport.targetPosition=pos;if modules.Settings then modules.Settings:Save(data)end end end)end
    elseif tabName=="ESP"then
        createToggle(content,"Bật ESP",data.ESP.enabled,function(val)data.ESP.enabled=val;if modules.Settings then modules.Settings:Save(data)end end)
        createToggle(content,"Hiển thị người chơi",data.ESP.showPlayers,function(val)data.ESP.showPlayers=val;if modules.Settings then modules.Settings:Save(data)end end)
        createToggle(content,"Hiển thị trái cây",data.ESP.showFruits,function(val)data.ESP.showFruits=val;if modules.Settings then modules.Settings:Save(data)end end)
        createToggle(content,"Hiển thị vật phẩm",data.ESP.showItems,function(val)data.ESP.showItems=val;if modules.Settings then modules.Settings:Save(data)end end)
        createToggle(content,"Hiển thị Boss",data.ESP.showBoss,function(val)data.ESP.showBoss=val;if modules.Settings then modules.Settings:Save(data)end end)
        createSlider(content,"Khoảng cách",100,5000,data.ESP.distance,function(val)data.ESP.distance=val;if modules.Settings then modules.Settings:Save(data)end end)
    elseif tabName=="Combat"then
        createToggle(content,"Auto Attack",data.Combat.autoAttack,function(val)data.Combat.autoAttack=val;if modules.Settings then modules.Settings:Save(data)end end)
        createToggle(content,"Auto Dodge",data.Combat.autoDodge,function(val)data.Combat.autoDodge=val;if modules.Settings then modules.Settings:Save(data)end end)
        createToggle(content,"Spam Skill",data.Combat.spamSkill,function(val)data.Combat.spamSkill=val;if modules.Settings then modules.Settings:Save(data)end end)
        createTextBox(content,"Phím skill",data.Combat.skillKey,function(val)data.Combat.skillKey=val;if modules.Settings then modules.Settings:Save(data)end end)
        createSlider(content,"Hitbox multiplier",1,10,data.Combat.hitboxMultiplier,function(val)data.Combat.hitboxMultiplier=val;if modules.Settings then modules.Settings:Save(data)end end)
        createSlider(content,"Damage multiplier",1,100,data.Combat.damageMultiplier,function(val)data.Combat.damageMultiplier=val;if modules.Settings then modules.Settings:Save(data)end end)
        createDropdown(content,"Ưu tiên target",{"LowestHealth","Nearest","HighestLevel"},data.Combat.targetPriority,function(val)data.Combat.targetPriority=val;if modules.Settings then modules.Settings:Save(data)end end)
    elseif tabName=="Movement"then
        createSlider(content,"WalkSpeed",0,200,data.Movement.walkSpeed,function(val)data.Movement.walkSpeed=val;if modules.Settings then modules.Settings:Save(data)end end)
        createSlider(content,"JumpPower",0,200,data.Movement.jumpPower,function(val)data.Movement.jumpPower=val;if modules.Settings then modules.Settings:Save(data)end end)
        createToggle(content,"Bay (Fly)",data.Movement.fly,function(val)data.Movement.fly=val;if modules.Settings then modules.Settings:Save(data)end end)
        createToggle(content,"Xuyên tường (Noclip)",data.Movement.noclip,function(val)data.Movement.noclip=val;if modules.Settings then modules.Settings:Save(data)end end)
        createToggle(content,"Speed Hack",data.Movement.speedHack,function(val)data.Movement.speedHack=val;if modules.Settings then modules.Settings:Save(data)end end)
        createSlider(content,"Tốc độ bơi",0,50,data.Movement.swimSpeed,function(val)data.Movement.swimSpeed=val;if modules.Settings then modules.Settings:Save(data)end end)
    elseif tabName=="Items"then
        createDropdown(content,"Spawn trái cây",{"Leopard","Dragon","Dough","Dark","Light","Flame","Ice","Magma","Quake","String"},data.Items.spawnFruit,function(val)data.Items.spawnFruit=val;if modules.Settings then modules.Settings:Save(data)end end)
        createButton(content,"Spawn trái cây",function()if modules.Items and modules.Items.SpawnFruit then modules.Items:SpawnFruit(data.Items.spawnFruit)end end)
        createDropdown(content,"Spawn vũ khí",{"Saber","Katana","Trident","Pole","Gun"},data.Items.spawnWeapon,function(val)data.Items.spawnWeapon=val;if modules.Settings then modules.Settings:Save(data)end end)
        createButton(content,"Spawn vũ khí",function()if modules.Items and modules.Items.SpawnWeapon then modules.Items:SpawnWeapon(data.Items.spawnWeapon)end end)
        createToggle(content,"Auto Collect",data.Items.autoCollect,function(val)data.Items.autoCollect=val;if modules.Settings then modules.Settings:Save(data)end end)
        createSlider(content,"Bán kính collect",100,5000,data.Items.collectRadius,function(val)data.Items.collectRadius=val;if modules.Settings then modules.Settings:Save(data)end end)
        createDropdown(content,"Lọc collect",{"All","Fruit","Weapon","Money"},data.Items.collectFilter,function(val)data.Items.collectFilter=val;if modules.Settings then modules.Settings:Save(data)end end)
    elseif tabName=="Player"then
        createToggle(content,"God Mode",data.Player.godMode,function(val)data.Player.godMode=val;if modules.Settings then modules.Settings:Save(data)end end)
        createToggle(content,"Infinite Energy",data.Player.infiniteEnergy,function(val)data.Player.infiniteEnergy=val;if modules.Settings then modules.Settings:Save(data)end end)
        createToggle(content,"Infinite Stamina",data.Player.infiniteStamina,function(val)data.Player.infiniteStamina=val;if modules.Settings then modules.Settings:Save(data)end end)
        createToggle(content,"Infinite Mana",data.Player.infiniteMana,function(val)data.Player.infiniteMana=val;if modules.Settings then modules.Settings:Save(data)end end)
        createButton(content,"Reset stats",function()if modules.Player and modules.Player.ResetStats then modules.Player:ResetStats()end end)
    elseif tabName=="World"then
        createDropdown(content,"Thời gian",{"Day","Night","Sunrise","Sunset"},data.World.timeOfDay,function(val)data.World.timeOfDay=val;if modules.Settings then modules.Settings:Save(data)end end)
        createDropdown(content,"Thời tiết",{"Clear","Rain","Storm","Fog"},data.World.weather,function(val)data.World.weather=val;if modules.Settings then modules.Settings:Save(data)end end)
        createToggle(content,"Bật sương mù",data.World.fogEnabled,function(val)data.World.fogEnabled=val;if modules.Settings then modules.Settings:Save(data)end end)
        createSlider(content,"Fog Start",0,500,data.World.fogStart,function(val)data.World.fogStart=val;if modules.Settings then modules.Settings:Save(data)end end)
        createSlider(content,"Fog End",500,5000,data.World.fogEnd,function(val)data.World.fogEnd=val;if modules.Settings then modules.Settings:Save(data)end end)
    elseif tabName=="Cài đặt"then
        createToggle(content,"Lưu tự động",data.Settings.saveOnChange,function(val)data.Settings.saveOnChange=val;if modules.Settings then modules.Settings:Save(data)end end)
        createToggle(content,"Chống AFK",data.Settings.antiAFK,function(val)data.Settings.antiAFK=val;if modules.Settings then modules.Settings:Save(data)end end)
        createToggle(content,"Tự động cập nhật",data.Settings.autoUpdate,function(val)data.Settings.autoUpdate=val;if modules.Settings then modules.Settings:Save(data)end end)
        createButton(content,"Lưu cấu hình",function()if modules.Settings then modules.Settings:Save(data)end end)
        createButton(content,"Tải cấu hình",function()if modules.Settings then modules.Settings:Load(data)end end)
    elseif tabName=="Leviathan" and isAdmin then
        createToggle(content,"Auto Bribe Spy",data.Leviathan.autoBribe,function(val)data.Leviathan.autoBribe=val;if modules.Settings then modules.Settings:Save(data)end end)
        createToggle(content,"Auto Find Frozen Dimension",data.Leviathan.autoFindFrozen,function(val)data.Leviathan.autoFindFrozen=val;if modules.Settings then modules.Settings:Save(data)end end)
        createToggle(content,"Auto Sail",data.Leviathan.autoSail,function(val)data.Leviathan.autoSail=val;if modules.Settings then modules.Settings:Save(data)end end)
        createToggle(content,"Auto Spawn",data.Leviathan.autoSpawn,function(val)data.Leviathan.autoSpawn=val;if modules.Settings then modules.Settings:Save(data)end end)
        createToggle(content,"Auto Fight",data.Leviathan.autoFight,function(val)data.Leviathan.autoFight=val;if modules.Settings then modules.Settings:Save(data)end end)
        createToggle(content,"Auto Collect Heart",data.Leviathan.autoCollectHeart,function(val)data.Leviathan.autoCollectHeart=val;if modules.Settings then modules.Settings:Save(data)end end)
        createToggle(content,"Auto Reset",data.Leviathan.autoReset,function(val)data.Leviathan.autoReset=val;if modules.Settings then modules.Settings:Save(data)end end)
        createButton(content,"Check Status",function()if modules.Leviathan then print(modules.Leviathan:GetStatus())end end)
    elseif tabName=="Draco" and isAdmin then
        createToggle(content,"Auto Collect Materials",data.Draco.autoCollectMaterials,function(val)data.Draco.autoCollectMaterials=val;if modules.Settings then modules.Settings:Save(data)end end)
        createToggle(content,"Auto Upgrade V2",data.Draco.autoUpgradeV2,function(val)data.Draco.autoUpgradeV2=val;if modules.Settings then modules.Settings:Save(data)end end)
        createToggle(content,"Auto Upgrade V3",data.Draco.autoUpgradeV3,function(val)data.Draco.autoUpgradeV3=val;if modules.Settings then modules.Settings:Save(data)end end)
        createToggle(content,"Auto Upgrade V4",data.Draco.autoUpgradeV4,function(val)data.Draco.autoUpgradeV4=val;if modules.Settings then modules.Settings:Save(data)end end)
        createToggle(content,"Auto Leviathan",data.Draco.autoLeviathan,function(val)data.Draco.autoLeviathan=val;if modules.Settings then modules.Settings:Save(data)end end)
        createToggle(content,"Auto Collect Volcanic Orb",data.Draco.autoOrb,function(val)data.Draco.autoOrb=val;if modules.Settings then modules.Settings:Save(data)end end)
        createToggle(content,"Auto Trial of Flames",data.Draco.autoTrial,function(val)data.Draco.autoTrial=val;if modules.Settings then modules.Settings:Save(data)end end)
        createToggle(content,"Auto Primordial Reign",data.Draco.autoPrimordialReign,function(val)data.Draco.autoPrimordialReign=val;if modules.Settings then modules.Settings:Save(data)end end)
        createToggle(content,"Auto Dragon Heart",data.Draco.autoDragonHeart,function(val)data.Draco.autoDragonHeart=val;if modules.Settings then modules.Settings:Save(data)end end)
        createToggle(content,"Auto Transform",data.Draco.autoTransform,function(val)data.Draco.autoTransform=val;if modules.Settings then modules.Settings:Save(data)end end)
        createToggle(content,"Auto Fill Gauge",data.Draco.autoFillGauge,function(val)data.Draco.autoFillGauge=val;if modules.Settings then modules.Settings:Save(data)end end)
        createButton(content,"Check Status",function()if modules.DracoRace then print(modules.DracoRace:GetStatus())end end)
    elseif tabName=="Volcano" and isAdmin then
        createToggle(content,"Auto Find",data.VolcanoEvent.autoFind,function(val)data.VolcanoEvent.autoFind=val;if modules.Settings then modules.Settings:Save(data)end end)
        createToggle(content,"Auto Start",data.VolcanoEvent.autoStart,function(val)data.VolcanoEvent.autoStart=val;if modules.Settings then modules.Settings:Save(data)end end)
        createToggle(content,"Auto Seal Cracks",data.VolcanoEvent.autoSealCracks,function(val)data.VolcanoEvent.autoSealCracks=val;if modules.Settings then modules.Settings:Save(data)end end)
        createToggle(content,"Auto Kill Golems",data.VolcanoEvent.autoKillGolems,function(val)data.VolcanoEvent.autoKillGolems=val;if modules.Settings then modules.Settings:Save(data)end end)
        createToggle(content,"Auto Collect Bones",data.VolcanoEvent.autoCollectBones,function(val)data.VolcanoEvent.autoCollectBones=val;if modules.Settings then modules.Settings:Save(data)end end)
        createToggle(content,"Auto Collect Eggs",data.VolcanoEvent.autoCollectEggs,function(val)data.VolcanoEvent.autoCollectEggs=val;if modules.Settings then modules.Settings:Save(data)end end)
        createButton(content,"Check Status",function()if modules.VolcanoEvent then print(modules.VolcanoEvent:GetStatus())end end)
    elseif tabName=="MysteryIsland" and isAdmin then
        createToggle(content,"Enable",data.MysteryIsland.enabled,function(val)data.MysteryIsland.enabled=val;if modules.Settings then modules.Settings:Save(data)end end)
        createButton(content,"Find Island",function()if modules.MysteryIsland then modules.MysteryIsland:FindIsland()end end)
        createButton(content,"Move to Highest Point",function()if modules.MysteryIsland then modules.MysteryIsland:MoveToHighest()end end)
        createButton(content,"Move to Gear",function()if modules.MysteryIsland then modules.MysteryIsland:MoveToGear()end end)
        createButton(content,"Check Status",function()if modules.MysteryIsland then print(modules.MysteryIsland:GetStatus())end end)
    elseif tabName=="MoonHop" and isAdmin then
        createToggle(content,"Enable",data.MoonHop.enabled,function(val)data.MoonHop.enabled=val;if modules.Settings then modules.Settings:Save(data)end end)
        createDropdown(content,"Target Type",{"Full Moon","Gần Full Moon","Trăng 1/5","Trăng 2/5","Trăng 3/5"},data.MoonHop.targetType,function(val)data.MoonHop.targetType=val;if modules.Settings then modules.Settings:Save(data)end end)
        createSlider(content,"Max Hops",1,100,data.MoonHop.maxHops,function(val)data.MoonHop.maxHops=val;if modules.Settings then modules.Settings:Save(data)end end)
        createSlider(content,"Hop Delay (s)",1,10,data.MoonHop.hopDelay,function(val)data.MoonHop.hopDelay=val;if modules.Settings then modules.Settings:Save(data)end end)
        createButton(content,"Check Status",function()if modules.MoonHop then print(modules.MoonHop:GetStatus())end end)
    end
    return content
end

local function createMainGUI(data,modules,isAdmin)
    local screenGui=Instance.new("ScreenGui")
    screenGui.Name="ShinnyXHub"
    screenGui.Parent=coreGui
    screenGui.ResetOnSpawn=false
    local mainFrame=Instance.new("Frame")
    mainFrame.Size=UDim2.new(0,520,0,720)
    mainFrame.Position=UDim2.new(0.5,-260,0.5,-360)
    mainFrame.BackgroundColor3=Color3.fromRGB(8,8,20)
    mainFrame.BackgroundTransparency=0.15
    mainFrame.BorderSizePixel=0
    mainFrame.ClipsDescendants=true
    mainFrame.Parent=screenGui
    local glass=Instance.new("ImageLabel")
    glass.Size=UDim2.new(1,0,1,0)
    glass.Image="rbxassetid://14859610560"
    glass.BackgroundTransparency=1
    glass.Parent=mainFrame
    local titleBar=Instance.new("Frame")
    titleBar.Size=UDim2.new(1,0,0,45)
    titleBar.BackgroundTransparency=1
    titleBar.Parent=mainFrame
    local titleLabel=Instance.new("TextLabel")
    titleLabel.Size=UDim2.new(0.8,0,1,0)
    titleLabel.BackgroundTransparency=1
    titleLabel.Text="ShinnyyX Hub✨ v5.0"
    titleLabel.TextColor3=Color3.fromRGB(0,200,255)
    titleLabel.TextScaled=true
    titleLabel.Font=Enum.Font.GothamBold
    titleLabel.TextXAlignment=Enum.TextXAlignment.Left
    titleLabel.Parent=titleBar
    local closeBtn=Instance.new("TextButton")
    closeBtn.Size=UDim2.new(0,30,0,30)
    closeBtn.Position=UDim2.new(1,-35,0,7)
    closeBtn.BackgroundColor3=Color3.fromRGB(200,0,0)
    closeBtn.Text="X"
    closeBtn.TextColor3=Color3.fromRGB(255,255,255)
    closeBtn.Parent=titleBar
    closeBtn.MouseButton1Click:Connect(function()mainFrame.Visible=not mainFrame.Visible end)
    local minBtn=Instance.new("TextButton")
    minBtn.Size=UDim2.new(0,30,0,30)
    minBtn.Position=UDim2.new(1,-70,0,7)
    minBtn.BackgroundColor3=Color3.fromRGB(100,100,100)
    minBtn.Text="-"
    minBtn.TextColor3=Color3.fromRGB(255,255,255)
    minBtn.Parent=titleBar
    local iconImage=Instance.new("ImageLabel")
    iconImage.Size=UDim2.new(0,40,0,40)
    iconImage.Position=UDim2.new(0,5,0,5)
    iconImage.BackgroundTransparency=1
    iconImage.Image="https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR_7ccpg_A-03rMNAk84DVvqX25sjen2eV-pGj2Qs3Y6Q&s=10"
    iconImage.Visible=false
    iconImage.Parent=mainFrame
    minBtn.MouseButton1Click:Connect(function()
        mainFrame.Size=UDim2.new(0,50,0,50)
        titleLabel.Visible=false
        tabsFrame.Visible=false
        contentContainer.Visible=false
        iconImage.Visible=true
    end)
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 and input.Position.Y<45 then
            if mainFrame.Size.Y.Offset==50 then
                mainFrame.Size=UDim2.new(0,520,0,720)
                titleLabel.Visible=true
                tabsFrame.Visible=true
                contentContainer.Visible=true
                iconImage.Visible=false
            else
                mainFrame.Size=UDim2.new(0,50,0,50)
                titleLabel.Visible=false
                tabsFrame.Visible=false
                contentContainer.Visible=false
                iconImage.Visible=true
            end
        end
    end)
    local tabsFrame=Instance.new("Frame")
    tabsFrame.Size=UDim2.new(1,0,0,40)
    tabsFrame.Position=UDim2.new(0,0,0,45)
    tabsFrame.BackgroundTransparency=1
    tabsFrame.Parent=mainFrame
    local contentContainer=Instance.new("Frame")
    contentContainer.Size=UDim2.new(1,0,1,-85)
    contentContainer.Position=UDim2.new(0,0,0,85)
    contentContainer.BackgroundTransparency=1
    contentContainer.Parent=mainFrame
    local tabNames={"Farm","Quest","Teleport","ESP","Combat","Movement","Items","Player","World","Cài đặt"}
    if isAdmin then
        table.insert(tabNames,"Leviathan")
        table.insert(tabNames,"Draco")
        table.insert(tabNames,"Volcano")
        table.insert(tabNames,"MysteryIsland")
        table.insert(tabNames,"MoonHop")
    end
    local tabButtons={}
    local currentContent=nil
    for i,name in ipairs(tabNames)do
        local btn=Instance.new("TextButton")
        btn.Size=UDim2.new(0,90,1,0)
        btn.Position=UDim2.new(0,(i-1)*95,0,0)
        btn.BackgroundTransparency=1
        btn.Text=name
        btn.TextColor3=Color3.fromRGB(255,255,255)
        btn.TextScaled=true
        btn.Font=Enum.Font.Gotham
        btn.Parent=tabsFrame
        tabButtons[name]=btn
        btn.MouseButton1Click:Connect(function()
            if currentContent then currentContent:Destroy() end
            currentContent=buildTab(name,data,modules,isAdmin)
            currentContent.Parent=contentContainer
        end)
    end
    if tabButtons["Farm"] then tabButtons["Farm"]:Fire() end
end

function gui.Initialize(data,modules)
    createAuthGUI(data,modules,function(admin)
        isAdmin=admin
        authCompleted=true
        createMainGUI(data,modules,admin)
    end)
end
return gui
