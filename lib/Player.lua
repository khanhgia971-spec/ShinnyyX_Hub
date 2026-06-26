local playerModule={}
playerModule.__index=playerModule
local player=game.Players.LocalPlayer
local runService=game:GetService("RunService")
local userInput=game:GetService("UserInputService")
local workspace=game:GetService("Workspace")
local players=game:GetService("Players")
local collectionService=game:GetService("CollectionService")
local debris=game:GetService("Debris")
local tweenService=game:GetService("TweenService")
local replicatedStorage=game:GetService("ReplicatedStorage")
local character=nil local humanoid=nil local rootPart=nil
local dataRef=nil local isRunning=false
local godMode=false local infiniteEnergy=false local infiniteStamina=false
local infiniteMana=false local resetStatsFlag=false
local maxHealthSet=999999 local maxEnergySet=999999
local currentHealth=0 local currentEnergy=0 local currentStamina=0
local statsBackup={} local statPoints=0
local statPriorityList={"Melee","Defense","Sword","Gun","Fruit"}
local function updateCharacter()
    character=player.Character or player.CharacterAdded:Wait()
    if character then
        humanoid=character:FindFirstChild("Humanoid")
        rootPart=character:FindFirstChild("HumanoidRootPart")
    end
end
local function getPlayerStats()
    local stats={}
    for _,v in pairs(player:GetChildren()) do
        if v:IsA("IntValue") or v:IsA("NumberValue") then
            if v.Name:match("Stat") or v.Name:match("Level") or v.Name:match("Exp") then
                stats[v.Name]=v.Value
            end
        end
    end
    return stats
end
local function getStatPoints()
    local sp=player:FindFirstChild("StatPoints")
    if sp and sp:IsA("NumberValue") then
        return sp.Value
    end
    return 0
end
local function setStatPoints(value)
    local sp=player:FindFirstChild("StatPoints")
    if sp and sp:IsA("NumberValue") then
        sp.Value=value
        return true
    end
    return false
end
local function addStat(statName,amount)
    local stat=player:FindFirstChild(statName)
    if stat and stat:IsA("NumberValue") then
        stat.Value=stat.Value+amount
        return true
    end
    return false
end
local function resetAllStats()
    local statNames={"Melee","Defense","Sword","Gun","Fruit"}
    for _,name in ipairs(statNames) do
        local stat=player:FindFirstChild(name)
        if stat and stat:IsA("NumberValue") then
            stat.Value=0
        end
    end
    local sp=player:FindFirstChild("StatPoints")
    if sp and sp:IsA("NumberValue") then
        local total=0
        for _,n in ipairs(statNames) do
            local s=player:FindFirstChild(n)
            if s and s:IsA("NumberValue") then total=total+s.Value end
        end
        sp.Value=sp.Value+total
    end
    return true
end
local function autoAssignStats(priority)
    priority=priority or "Melee"
    local points=getStatPoints()
    if points<=0 then return false end
    local stat=player:FindFirstChild(priority)
    if stat and stat:IsA("NumberValue") then
        stat.Value=stat.Value+points
        setStatPoints(0)
        return true
    end
    return false
end
local function applyGodMode(state)
    godMode=state
    if humanoid then
        if state then
            humanoid.MaxHealth=maxHealthSet
            humanoid.Health=maxHealthSet
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead,false)
        else
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead,true)
        end
    end
end
local function applyInfiniteEnergy(state)
    infiniteEnergy=state
    if state then
        local energy=humanoid and humanoid:FindFirstChild("Energy")
        if energy and energy:IsA("NumberValue") then
            maxEnergySet=energy.Value
        end
    end
end
local function applyInfiniteStamina(state)
    infiniteStamina=state
end
local function applyInfiniteMana(state)
    infiniteMana=state
    if state then
        local mana=player:FindFirstChild("Mana")
        if mana and mana:IsA("NumberValue") then
            mana.Value=999999
        end
    end
end
local function setMaxHealth(value)
    maxHealthSet=value
    if humanoid then
        humanoid.MaxHealth=value
    end
end
local function setMaxEnergy(value)
    maxEnergySet=value
    local energy=humanoid and humanoid:FindFirstChild("Energy")
    if energy and energy:IsA("NumberValue") then
        energy.Value=value
    end
end
local function healPlayer(amount)
    if humanoid then
        humanoid.Health=math.min(humanoid.Health+amount,humanoid.MaxHealth)
        return true
    end
    return false
end
local function fullHeal()
    if humanoid then
        humanoid.Health=humanoid.MaxHealth
        return true
    end
    return false
end
local function resetHealth()
    if humanoid then
        humanoid.Health=100
        return true
    end
    return false
end
local function getHealth()
    if humanoid then
        return humanoid.Health
    end
    return 0
end
local function getMaxHealth()
    if humanoid then
        return humanoid.MaxHealth
    end
    return 100
end
local function getEnergy()
    local energy=humanoid and humanoid:FindFirstChild("Energy")
    if energy and energy:IsA("NumberValue") then
        return energy.Value
    end
    return 0
end
local function getStamina()
    local stamina=humanoid and humanoid:FindFirstChild("Stamina")
    if stamina and stamina:IsA("NumberValue") then
        return stamina.Value
    end
    return 0
end
local function getMana()
    local mana=player:FindFirstChild("Mana")
    if mana and mana:IsA("NumberValue") then
        return mana.Value
    end
    return 0
end
local function getLevel()
    local level=player:FindFirstChild("Level")
    if level and level:IsA("NumberValue") then
        return level.Value
    end
    return 0
end
local function getExp()
    local exp=player:FindFirstChild("Exp")
    if exp and exp:IsA("NumberValue") then
        return exp.Value
    end
    return 0
end
local function getMaxExp()
    local maxExp=player:FindFirstChild("MaxExp")
    if maxExp and maxExp:IsA("NumberValue") then
        return maxExp.Value
    end
    return 100
end
local function getBeli()
    local beli=player:FindFirstChild("Beli")
    if beli and beli:IsA("NumberValue") then
        return beli.Value
    end
    return 0
end
local function getGems()
    local gems=player:FindFirstChild("Gems")
    if gems and gems:IsA("NumberValue") then
        return gems.Value
    end
    return 0
end
local function getFruit()
    local fruit=player:FindFirstChild("Fruit")
    if fruit and fruit:IsA("StringValue") then
        return fruit.Value
    end
    return "None"
end
local function getWeapon()
    local weapon=player:FindFirstChild("Weapon")
    if weapon and weapon:IsA("StringValue") then
        return weapon.Value
    end
    return "None"
end
local function setFruit(fruitName)
    local fruit=player:FindFirstChild("Fruit")
    if fruit and fruit:IsA("StringValue") then
        fruit.Value=fruitName
        return true
    end
    return false
end
local function setWeapon(weaponName)
    local weapon=player:FindFirstChild("Weapon")
    if weapon and weapon:IsA("StringValue") then
        weapon.Value=weaponName
        return true
    end
    return false
end
local function addBeli(amount)
    local beli=player:FindFirstChild("Beli")
    if beli and beli:IsA("NumberValue") then
        beli.Value=beli.Value+amount
        return true
    end
    return false
end
local function addGems(amount)
    local gems=player:FindFirstChild("Gems")
    if gems and gems:IsA("NumberValue") then
        gems.Value=gems.Value+amount
        return true
    end
    return false
end
local function addExp(amount)
    local exp=player:FindFirstChild("Exp")
    if exp and exp:IsA("NumberValue") then
        exp.Value=exp.Value+amount
        return true
    end
    return false
end
local function setLevel(level)
    local lvl=player:FindFirstChild("Level")
    if lvl and lvl:IsA("NumberValue") then
        lvl.Value=level
        return true
    end
    return false
end
local function resetPlayer()
    resetAllStats()
    resetHealth()
    return true
end
local function processPlayer(data)
    if not rootPart or not humanoid then updateCharacter() end
    if not rootPart or not humanoid then return end
    if data.godMode then
        if not godMode then applyGodMode(true) end
        if humanoid then
            humanoid.Health=humanoid.MaxHealth
        end
    else
        if godMode then applyGodMode(false) end
    end
    if data.infiniteEnergy then
        applyInfiniteEnergy(true)
        local energy=humanoid:FindFirstChild("Energy")
        if energy and energy:IsA("NumberValue") then
            energy.Value=maxEnergySet
        end
    else
        if infiniteEnergy then applyInfiniteEnergy(false) end
    end
    if data.infiniteStamina then
        applyInfiniteStamina(true)
        local stamina=humanoid:FindFirstChild("Stamina")
        if stamina and stamina:IsA("NumberValue") then
            stamina.Value=999999
        end
    else
        if infiniteStamina then applyInfiniteStamina(false) end
    end
    if data.infiniteMana then
        applyInfiniteMana(true)
        local mana=player:FindFirstChild("Mana")
        if mana and mana:IsA("NumberValue") then
            mana.Value=999999
        end
    else
        if infiniteMana then applyInfiniteMana(false) end
    end
    if data.resetStats then
        resetAllStats()
        data.resetStats=false
    end
    if data.maxHealth and data.maxHealth~=maxHealthSet then
        setMaxHealth(data.maxHealth)
    end
    if data.maxEnergy and data.maxEnergy~=maxEnergySet then
        setMaxEnergy(data.maxEnergy)
    end
    if data.autoAssignStats and data.autoAssignStats then
        if getStatPoints()>0 then
            autoAssignStats(data.statPriority or "Melee")
        end
    end
end
local function startPlayerLoop(data)
    if isRunning then return end
    isRunning=true
    task.spawn(function()
        while isRunning do
            wait(0.1)
            pcall(function()processPlayer(data)end)
        end
    end)
end
function playerModule.Stop()
    isRunning=false
    if godMode then applyGodMode(false) end
    if infiniteEnergy then applyInfiniteEnergy(false) end
    if infiniteStamina then applyInfiniteStamina(false) end
    if infiniteMana then applyInfiniteMana(false) end
    return true
end
function playerModule.Apply(data)
    if not data then return false end
    dataRef=data
    if not isRunning then
        startPlayerLoop(data)
    end
    return true
end
function playerModule.ToggleGodMode()
    if dataRef then
        dataRef.godMode=not dataRef.godMode
        return dataRef.godMode
    end
    return false
end
function playerModule.ToggleInfiniteEnergy()
    if dataRef then
        dataRef.infiniteEnergy=not dataRef.infiniteEnergy
        return dataRef.infiniteEnergy
    end
    return false
end
function playerModule.ToggleInfiniteStamina()
    if dataRef then
        dataRef.infiniteStamina=not dataRef.infiniteStamina
        return dataRef.infiniteStamina
    end
    return false
end
function playerModule.ToggleInfiniteMana()
    if dataRef then
        dataRef.infiniteMana=not dataRef.infiniteMana
        return dataRef.infiniteMana
    end
    return false
end
function playerModule.ResetStats()
    if dataRef then
        dataRef.resetStats=true
        return true
    end
    return false
end
function playerModule.SetMaxHealth(value)
    if dataRef then
        dataRef.maxHealth=value
        setMaxHealth(value)
        return true
    end
    return false
end
function playerModule.SetMaxEnergy(value)
    if dataRef then
        dataRef.maxEnergy=value
        setMaxEnergy(value)
        return true
    end
    return false
end
function playerModule.SetStatPriority(priority)
    if dataRef then
        dataRef.statPriority=priority
        return true
    end
    return false
end
function playerModule.ToggleAutoAssignStats()
    if dataRef then
        dataRef.autoAssignStats=not dataRef.autoAssignStats
        return dataRef.autoAssignStats
    end
    return false
end
function playerModule.GetStatus()
    return{
        isRunning=isRunning,
        godMode=godMode,
        infiniteEnergy=infiniteEnergy,
        infiniteStamina=infiniteStamina,
        infiniteMana=infiniteMana,
        health=getHealth(),
        maxHealth=getMaxHealth(),
        energy=getEnergy(),
        stamina=getStamina(),
        mana=getMana(),
        level=getLevel(),
        exp=getExp(),
        maxExp=getMaxExp(),
        beli=getBeli(),
        gems=getGems(),
        fruit=getFruit(),
        weapon=getWeapon(),
        statPoints=getStatPoints()
    }
end
function playerModule.Heal(amount)
    return healPlayer(amount)
end
function playerModule.FullHeal()
    return fullHeal()
end
function playerModule.GetStats()
    return getPlayerStats()
end
function playerModule.AddStat(statName,amount)
    return addStat(statName,amount)
end
function playerModule.AutoAssignStats(priority)
    return autoAssignStats(priority)
end
function playerModule.ResetAllStats()
    return resetAllStats()
end
function playerModule.SetFruit(fruitName)
    return setFruit(fruitName)
end
function playerModule.SetWeapon(weaponName)
    return setWeapon(weaponName)
end
function playerModule.AddBeli(amount)
    return addBeli(amount)
end
function playerModule.AddGems(amount)
    return addGems(amount)
end
function playerModule.AddExp(amount)
    return addExp(amount)
end
function playerModule.SetLevel(level)
    return setLevel(level)
end
function playerModule.ResetPlayer()
    return resetPlayer()
end
function playerModule.GetStatPoints()
    return getStatPoints()
end
function playerModule.SetStatPoints(value)
    return setStatPoints(value)
end
function playerModule.Pause()
    isRunning=false
    return true
end
function playerModule.Resume()
    if dataRef then
        isRunning=true
        startPlayerLoop(dataRef)
        return true
    end
    return false
end
function playerModule.Destroy()
    isRunning=false
    playerModule.Stop()
    dataRef=nil
    return true
end
function playerModule.Initialize(data)
    dataRef=data
    updateCharacter()
    player.CharacterAdded:Connect(function(char)
        character=char
        humanoid=char:FindFirstChild("Humanoid")
        rootPart=char:FindFirstChild("HumanoidRootPart")
        if dataRef and dataRef.godMode then
            applyGodMode(true)
        end
    end)
    return true
end
return playerModule
