local keybind={}
keybind.__index=keybind
local player=game.Players.LocalPlayer
local runService=game:GetService("RunService")
local userInput=game:GetService("UserInputService")
local tweenService=game:GetService("TweenService")
local workspace=game:GetService("Workspace")
local players=game:GetService("Players")
local coreGui=game:GetService("CoreGui")
local guiService=game:GetService("GuiService")
local debris=game:GetService("Debris")
local httpService=game:GetService("HttpService")
local dataRef=nil
local isRunning=false
local bindings={}
local macros={}
local profiles={}
local currentProfile="Default"
local keyStates={}
local heldKeys={}
local comboSequence={}
local lastKeyTime=0
local macroRunning=false
local macroQueue={}
local recordingMacro=nil
local macroRecorder={}
local defaultBindings={
    toggleFarm=Enum.KeyCode.F1,
    toggleFly=Enum.KeyCode.F2,
    toggleESP=Enum.KeyCode.F3,
    toggleGod=Enum.KeyCode.F4,
    teleportHome=Enum.KeyCode.F5,
    toggleCombat=Enum.KeyCode.F6,
    toggleNoclip=Enum.KeyCode.F7,
    toggleSpeedHack=Enum.KeyCode.F8,
    toggleAutoQuest=Enum.KeyCode.F9,
    toggleAutoCollect=Enum.KeyCode.F10,
    heal=Enum.KeyCode.H,
    dash=Enum.KeyCode.LeftShift,
    jump=Enum.KeyCode.Space,
    flyUp=Enum.KeyCode.E,
    flyDown=Enum.KeyCode.Q,
    toggleFishing=Enum.KeyCode.F11,
    toggleRaid=Enum.KeyCode.F12,
    toggleSeaEvent=Enum.KeyCode.Insert,
    toggleStats=Enum.KeyCode.Home,
    toggleMisc=Enum.KeyCode.PageUp
}
local keyNames={}
for _,v in pairs(Enum.KeyCode:GetEnumItems()) do
    keyNames[v.Name]=v
    keyNames[v.Value]=v
end
local function getKeyCode(input)
    if type(input)=="string" then
        if keyNames[input] then return keyNames[input] end
        if string.match(input,"^%d+$") then
            local num=tonumber(input)
            for _,v in pairs(Enum.KeyCode:GetEnumItems()) do
                if v.Value==num then return v end
            end
        end
        return nil
    end
    return input
end
local function getKeyName(key)
    if type(key)=="string" then return key end
    if type(key)=="number" then
        for _,v in pairs(Enum.KeyCode:GetEnumItems()) do
            if v.Value==key then return v.Name end
        end
        return tostring(key)
    end
    if key and key.Name then return key.Name end
    return tostring(key)
end
local function isModifier(key)
    local name=getKeyName(key)
    return name=="LeftControl" or name=="RightControl" or name=="LeftShift" or name=="RightShift" or name=="LeftAlt" or name=="RightAlt"
end
local function getModifierState()
    local mods={}
    if userInput:IsKeyDown(Enum.KeyCode.LeftControl) or userInput:IsKeyDown(Enum.KeyCode.RightControl) then table.insert(mods,"Ctrl") end
    if userInput:IsKeyDown(Enum.KeyCode.LeftShift) or userInput:IsKeyDown(Enum.KeyCode.RightShift) then table.insert(mods,"Shift") end
    if userInput:IsKeyDown(Enum.KeyCode.LeftAlt) or userInput:IsKeyDown(Enum.KeyCode.RightAlt) then table.insert(mods,"Alt") end
    return mods
end
local function matchesModifier(key,requiredMods)
    if not requiredMods or #requiredMods==0 then return true end
    local current=getModifierState()
    for _,mod in ipairs(requiredMods) do
        if not table.find(current,mod) then return false end
    end
    return true
end
local function executeBinding(action,...)
    if not action then return false end
    local args={...}
    if type(action)=="function" then
        return action(unpack(args))
    elseif type(action)=="string" then
        local moduleName,funcName=string.match(action,"^([^:]+):([^:]+)$")
        if moduleName and funcName then
            local mod=rawget(_G,moduleName)
            if mod and mod[funcName] then
                return mod[funcName](unpack(args))
            end
        end
        local func=rawget(_G,action)
        if type(func)=="function" then
            return func(unpack(args))
        end
    end
    return false
end
local function parseBindingString(str)
    local parts={}
    for part in string.gmatch(str,"[^+]+") do
        table.insert(parts,part)
    end
    local modifiers={}
    local key=nil
    for _,part in ipairs(parts) do
        if part=="Ctrl" or part=="Shift" or part=="Alt" then
            table.insert(modifiers,part)
        else
            key=part
        end
    end
    return key,modifiers
end
local function getKeyFromString(str)
    local key,mods=parseBindingString(str)
    return key,mods
end
local function createBinding(key,action,modifiers,description)
    if type(key)=="string" then
        local k=keyNames[key]
        if k then key=k end
    end
    if not key then return false end
    modifiers=modifiers or {}
    local binding={
        key=key,
        action=action,
        modifiers=modifiers,
        description=description or "",
        enabled=true,
        repeatable=false,
        holdable=false,
        held=false,
        lastTrigger=0,
        cooldown=0
    }
    return binding
end
local function addBinding(name,binding)
    bindings[name]=binding
    return true
end
local function removeBinding(name)
    bindings[name]=nil
    return true
end
local function getBinding(name)
    return bindings[name]
end
local function listBindings()
    local list={}
    for k,v in pairs(bindings) do
        table.insert(list,{name=k,binding=v})
    end
    return list
end
local function setBindingKey(name,key)
    if bindings[name] then
        if type(key)=="string" then
            local k=keyNames[key]
            if k then key=k end
        end
        bindings[name].key=key
        return true
    end
    return false
end
local function setBindingAction(name,action)
    if bindings[name] then
        bindings[name].action=action
        return true
    end
    return false
end
local function setBindingModifiers(name,modifiers)
    if bindings[name] then
        bindings[name].modifiers=modifiers
        return true
    end
    return false
end
local function setBindingEnabled(name,enabled)
    if bindings[name] then
        bindings[name].enabled=enabled
        return true
    end
    return false
end
local function toggleBinding(name)
    if bindings[name] then
        bindings[name].enabled=not bindings[name].enabled
        return bindings[name].enabled
    end
    return false
end
local function isBindingEnabled(name)
    return bindings[name] and bindings[name].enabled or false
end
local function triggerBinding(name,...)
    local binding=bindings[name]
    if not binding or not binding.enabled then return false end
    if binding.cooldown>0 and tick()-binding.lastTrigger<binding.cooldown then return false end
    binding.lastTrigger=tick()
    return executeBinding(binding.action,...)
end
local function createMacro(name,actions,repeatCount,interval)
    repeatCount=repeatCount or 1
    interval=interval or 0.1
    local macro={
        name=name,
        actions=actions,
        repeatCount=repeatCount,
        interval=interval,
        running=false,
        currentRepeat=0,
        currentStep=0
    }
    macros[name]=macro
    return true
end
local function removeMacro(name)
    macros[name]=nil
    return true
end
local function getMacro(name)
    return macros[name]
end
local function listMacros()
    local list={}
    for k,v in pairs(macros) do
        table.insert(list,{name=k,macro=v})
    end
    return list
end
local function runMacro(name)
    local macro=macros[name]
    if not macro or macro.running then return false end
    macro.running=true
    macro.currentRepeat=0
    macro.currentStep=0
    task.spawn(function()
        while macro.running and (macro.repeatCount==-1 or macro.currentRepeat<macro.repeatCount) do
            for i,action in ipairs(macro.actions) do
                if not macro.running then break end
                macro.currentStep=i
                if type(action)=="function" then
                    action()
                elseif type(action)=="string" then
                    executeBinding(action)
                elseif type(action)=="table" then
                    if action.key then
                        local key=action.key
                        if type(key)=="string" then key=keyNames[key] end
                        if key then
                            userInput:SetKeyDown(key)
                            task.wait(action.duration or 0.05)
                            userInput:SetKeyUp(key)
                        end
                    elseif action.func then
                        action.func()
                    end
                end
                task.wait(macro.interval)
            end
            macro.currentRepeat=macro.currentRepeat+1
        end
        macro.running=false
    end)
    return true
end
local function stopMacro(name)
    local macro=macros[name]
    if macro then
        macro.running=false
        return true
    end
    return false
end
local function stopAllMacros()
    for name,_ in pairs(macros) do
        stopMacro(name)
    end
    return true
end
local function isMacroRunning(name)
    local macro=macros[name]
    return macro and macro.running or false
end
local function startRecording(name)
    if recordingMacro then return false end
    recordingMacro={name=name,actions={},startTime=tick()}
    macroRecorder={}
    return true
end
local function stopRecording()
    if not recordingMacro then return false end
    local name=recordingMacro.name
    local actions=recordingMacro.actions
    createMacro(name,actions,1,0.1)
    recordingMacro=nil
    macroRecorder={}
    return true
end
local function cancelRecording()
    recordingMacro=nil
    macroRecorder={}
    return true
end
local function isRecording()
    return recordingMacro~=nil
end
local function addMacroStep(action)
    if not recordingMacro then return false end
    table.insert(recordingMacro.actions,action)
    return true
end
local function recordKeyPress(key,duration)
    if not recordingMacro then return false end
    duration=duration or 0.1
    table.insert(recordingMacro.actions,{key=key,duration=duration})
    return true
end
local function recordDelay(duration)
    if not recordingMacro then return false end
    table.insert(recordingMacro.actions,{func=function()task.wait(duration)end})
    return true
end
local function createProfile(name)
    if profiles[name] then return false end
    profiles[name]={
        bindings={},
        macros={},
        name=name,
        created=os.time()
    }
    for k,v in pairs(bindings) do
        profiles[name].bindings[k]=v
    end
    for k,v in pairs(macros) do
        profiles[name].macros[k]=v
    end
    return true
end
local function deleteProfile(name)
    if name=="Default" then return false end
    profiles[name]=nil
    if currentProfile==name then currentProfile="Default" end
    return true
end
local function loadProfile(name)
    if not profiles[name] then return false end
    currentProfile=name
    local profile=profiles[name]
    for k,v in pairs(profile.bindings) do
        bindings[k]=v
    end
    for k,v in pairs(profile.macros) do
        macros[k]=v
    end
    return true
end
local function saveProfile(name)
    if not profiles[name] then return false end
    local profile=profiles[name]
    profile.bindings={}
    profile.macros={}
    for k,v in pairs(bindings) do
        profile.bindings[k]=v
    end
    for k,v in pairs(macros) do
        profile.macros[k]=v
    end
    return true
end
local function listProfiles()
    local list={}
    for k,_ in pairs(profiles) do
        table.insert(list,k)
    end
    return list
end
local function getCurrentProfile()
    return currentProfile
end
local function resetToDefault()
    bindings={}
    macros={}
    for k,v in pairs(defaultBindings) do
        bindings[k]=createBinding(v,k,{},"Default binding for "..k)
    end
    return true
end
local function exportBindings()
    local data={
        bindings=bindings,
        macros=macros,
        profiles=profiles,
        currentProfile=currentProfile,
        version="4.0.0",
        timestamp=os.time()
    }
    return httpService:JSONEncode(data)
end
local function importBindings(json)
    local success,data=pcall(function()return httpService:JSONDecode(json)end)
    if not success or not data then return false end
    if data.bindings then
        for k,v in pairs(data.bindings) do
            bindings[k]=v
        end
    end
    if data.macros then
        for k,v in pairs(data.macros) do
            macros[k]=v
        end
    end
    if data.profiles then
        for k,v in pairs(data.profiles) do
            profiles[k]=v
        end
    end
    if data.currentProfile then
        currentProfile=data.currentProfile
    end
    return true
end
local function handleInput(input,gameProcessed)
    if gameProcessed then return end
    local key=input.KeyCode
    if key==Enum.KeyCode.Unknown then return end
    local modifiers=getModifierState()
    local keyName=getKeyName(key)
    if input.UserInputType==Enum.UserInputType.Keyboard then
        if input.KeyCode~=Enum.KeyCode.Unknown then
            if input.UserInputState==Enum.UserInputState.Begin then
                heldKeys[keyName]=true
                lastKeyTime=tick()
                for name,binding in pairs(bindings) do
                    if binding and binding.enabled then
                        local bKey=getKeyName(binding.key)
                        if bKey==keyName or (type(binding.key)=="table" and table.find(binding.key,keyName)) then
                            if matchesModifier(key,binding.modifiers) then
                                triggerBinding(name,input)
                            end
                        end
                    end
                end
                if recordingMacro then
                    recordKeyPress(keyName,0.1)
                end
            elseif input.UserInputState==Enum.UserInputState.End then
                heldKeys[keyName]=nil
            end
        end
    end
end
local function handleMouseInput(input,gameProcessed)
    if gameProcessed then return end
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.MouseButton2 or input.UserInputType==Enum.UserInputType.MouseButton3 then
        if input.UserInputState==Enum.UserInputState.Begin then
            if recordingMacro then
                recordKeyPress(input.UserInputType.Name,0.1)
            end
        end
    end
end
local function handleHoldKeys()
    for name,binding in pairs(bindings) do
        if binding and binding.enabled and binding.holdable then
            local keyName=getKeyName(binding.key)
            if heldKeys[keyName] then
                if binding.held==false then
                    binding.held=true
                    triggerBinding(name,"hold_start")
                else
                    triggerBinding(name,"hold")
                end
            else
                if binding.held==true then
                    binding.held=false
                    triggerBinding(name,"hold_end")
                end
            end
        end
    end
end
local function initBindings()
    resetToDefault()
    for k,v in pairs(defaultBindings) do
        if not bindings[k] then
            bindings[k]=createBinding(v,k,{},"Default binding for "..k)
        end
    end
end
local function startLoop()
    if isRunning then return end
    isRunning=true
    task.spawn(function()
        while isRunning do
            wait(0.05)
            pcall(handleHoldKeys)
        end
    end)
end
function keybind.Stop()
    isRunning=false
    return true
end
function keybind.Initialize(data)
    dataRef=data
    if data and data.bindings then
        for k,v in pairs(data.bindings) do
            bindings[k]=v
        end
    else
        initBindings()
    end
    if data and data.profiles then
        for k,v in pairs(data.profiles) do
            profiles[k]=v
        end
    end
    if data and data.currentProfile then
        currentProfile=data.currentProfile
    end
    userInput.InputBegan:Connect(handleInput)
    userInput.InputEnded:Connect(handleInput)
    userInput.InputBegan:Connect(handleMouseInput)
    userInput.InputEnded:Connect(handleMouseInput)
    startLoop()
    return true
end
function keybind.AddBinding(name,key,action,modifiers,description)
    local binding=createBinding(key,action,modifiers,description)
    if binding then
        bindings[name]=binding
        return true
    end
    return false
end
function keybind.RemoveBinding(name)
    return removeBinding(name)
end
function keybind.GetBinding(name)
    return getBinding(name)
end
function keybind.ListBindings()
    return listBindings()
end
function keybind.SetBindingKey(name,key)
    return setBindingKey(name,key)
end
function keybind.SetBindingAction(name,action)
    return setBindingAction(name,action)
end
function keybind.SetBindingModifiers(name,modifiers)
    return setBindingModifiers(name,modifiers)
end
function keybind.SetBindingEnabled(name,enabled)
    return setBindingEnabled(name,enabled)
end
function keybind.ToggleBinding(name)
    return toggleBinding(name)
end
function keybind.IsBindingEnabled(name)
    return isBindingEnabled(name)
end
function keybind.TriggerBinding(name,...)
    return triggerBinding(name,...)
end
function keybind.CreateMacro(name,actions,repeatCount,interval)
    return createMacro(name,actions,repeatCount,interval)
end
function keybind.RemoveMacro(name)
    return removeMacro(name)
end
function keybind.GetMacro(name)
    return getMacro(name)
end
function keybind.ListMacros()
    return listMacros()
end
function keybind.RunMacro(name)
    return runMacro(name)
end
function keybind.StopMacro(name)
    return stopMacro(name)
end
function keybind.StopAllMacros()
    return stopAllMacros()
end
function keybind.IsMacroRunning(name)
    return isMacroRunning(name)
end
function keybind.StartRecording(name)
    return startRecording(name)
end
function keybind.StopRecording()
    return stopRecording()
end
function keybind.CancelRecording()
    return cancelRecording()
end
function keybind.IsRecording()
    return isRecording()
end
function keybind.AddMacroStep(action)
    return addMacroStep(action)
end
function keybind.RecordKeyPress(key,duration)
    return recordKeyPress(key,duration)
end
function keybind.RecordDelay(duration)
    return recordDelay(duration)
end
function keybind.CreateProfile(name)
    return createProfile(name)
end
function keybind.DeleteProfile(name)
    return deleteProfile(name)
end
function keybind.LoadProfile(name)
    return loadProfile(name)
end
function keybind.SaveProfile(name)
    return saveProfile(name)
end
function keybind.ListProfiles()
    return listProfiles()
end
function keybind.GetCurrentProfile()
    return getCurrentProfile()
end
function keybind.ResetToDefault()
    return resetToDefault()
end
function keybind.ExportBindings()
    return exportBindings()
end
function keybind.ImportBindings(json)
    return importBindings(json)
end
function keybind.GetKeyName(key)
    return getKeyName(key)
end
function keybind.GetKeyCode(name)
    return getKeyCode(name)
end
function keybind.IsKeyDown(key)
    if type(key)=="string" then
        local k=getKeyCode(key)
        if k then return userInput:IsKeyDown(k) end
        return false
    end
    return userInput:IsKeyDown(key)
end
function keybind.GetModifierState()
    return getModifierState()
end
function keybind.SetBindingCooldown(name,cooldown)
    if bindings[name] then
        bindings[name].cooldown=cooldown
        return true
    end
    return false
end
function keybind.SetBindingRepeatable(name,repeatable)
    if bindings[name] then
        bindings[name].repeatable=repeatable
        return true
    end
    return false
end
function keybind.SetBindingHoldable(name,holdable)
    if bindings[name] then
        bindings[name].holdable=holdable
        return true
    end
    return false
end
function keybind.SetBindingDescription(name,description)
    if bindings[name] then
        bindings[name].description=description
        return true
    end
    return false
end
function keybind.ExportProfile(name)
    if not profiles[name] then return nil end
    return httpService:JSONEncode(profiles[name])
end
function keybind.ImportProfile(name,json)
    local success,data=pcall(function()return httpService:JSONDecode(json)end)
    if not success or not data then return false end
    profiles[name]=data
    return true
end
function keybind.CloneProfile(name,newName)
    if not profiles[name] or profiles[newName] then return false end
    profiles[newName]=httpService:JSONDecode(httpService:JSONEncode(profiles[name]))
    return true
end
function keybind.GetAllKeys()
    local list={}
    for _,v in pairs(Enum.KeyCode:GetEnumItems()) do
        table.insert(list,v.Name)
    end
    return list
end
function keybind.GetHeldKeys()
    local list={}
    for k,_ in pairs(heldKeys) do
        table.insert(list,k)
    end
    return list
end
function keybind.ClearHeldKeys()
    heldKeys={}
    return true
end
function keybind.GetKeyState(key)
    if type(key)=="string" then
        return heldKeys[key] or false
    end
    local name=getKeyName(key)
    return heldKeys[name] or false
end
function keybind.WaitForKey(duration)
    local event
    local done=false
    local keyPressed=nil
    event=userInput.InputBegan:Connect(function(input,gameProcessed)
        if not gameProcessed and input.UserInputType==Enum.UserInputType.Keyboard then
            keyPressed=input.KeyCode
            done=true
            event:Disconnect()
        end
    end)
    if duration then
        task.wait(duration)
        if not done then
            event:Disconnect()
            return nil
        end
    else
        repeat task.wait(0.1) until done
    end
    return keyPressed
end
function keybind.SimulateKeyPress(key,duration)
    if type(key)=="string" then
        local k=getKeyCode(key)
        if not k then return false end
        key=k
    end
    duration=duration or 0.05
    userInput:SetKeyDown(key)
    task.wait(duration)
    userInput:SetKeyUp(key)
    return true
end
function keybind.SimulateKeyDown(key)
    if type(key)=="string" then
        local k=getKeyCode(key)
        if not k then return false end
        key=k
    end
    userInput:SetKeyDown(key)
    return true
end
function keybind.SimulateKeyUp(key)
    if type(key)=="string" then
        local k=getKeyCode(key)
        if not k then return false end
        key=k
    end
    userInput:SetKeyUp(key)
    return true
end
function keybind.SimulateMouseClick(button)
    button=button or Enum.UserInputType.MouseButton1
    userInput:SetKeyDown(button)
    task.wait(0.05)
    userInput:SetKeyUp(button)
    return true
end
function keybind.SimulateMouseDown(button)
    userInput:SetKeyDown(button)
    return true
end
function keybind.SimulateMouseUp(button)
    userInput:SetKeyUp(button)
    return true
end
function keybind.GetLastKeyTime()
    return lastKeyTime
end
function keybind.GetComboSequence()
    return comboSequence
end
function keybind.ResetComboSequence()
    comboSequence={}
    return true
end
function keybind.RecordCombo(key)
    if type(key)=="string" then
        local k=getKeyCode(key)
        if not k then return false end
        key=k
    end
    table.insert(comboSequence,{key=getKeyName(key),time=tick()})
    return true
end
function keybind.MatchCombo(sequence)
    if #sequence>#comboSequence then return false end
    for i=1,#sequence do
        local expected=sequence[i]
        local actual=comboSequence[#comboSequence-#sequence+i]
        if not actual or actual.key~=expected then return false end
    end
    return true
end
function keybind.ClearCombo()
    comboSequence={}
    return true
end
function keybind.Pause()
    isRunning=false
    return true
end
function keybind.Resume()
    if not isRunning then
        isRunning=true
        startLoop()
        return true
    end
    return false
end
function keybind.Destroy()
    isRunning=false
    bindings={}
    macros={}
    profiles={}
    currentProfile="Default"
    heldKeys={}
    comboSequence={}
    recordingMacro=nil
    return true
end
return keybind
