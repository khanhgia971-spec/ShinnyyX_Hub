local movement={}
movement.__index=movement
local player=game.Players.LocalPlayer
local runService=game:GetService("RunService")
local userInput=game:GetService("UserInputService")
local tweenService=game:GetService("TweenService")
local workspace=game:GetService("Workspace")
local players=game:GetService("Players")
local virtualUser=game:GetService("VirtualUser")
local collectionService=game:GetService("CollectionService")
local debris=game:GetService("Debris")
local character=nil local humanoid=nil local rootPart=nil
local dataRef=nil local isRunning=false
local flyEnabled=false local flySpeed=50 local flyHeight=10
local noclipEnabled=false local speedHackEnabled=false
local currentWalkSpeed=16 local currentJumpPower=50
local swimSpeed=10 local gravityScale=1
local teleportCooldown=0 local dashCooldown=0
local lastPosition=Vector3.new(0,0,0)
local velocityBuffer={}
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
local function applyWalkSpeed(speed)
    if humanoid then
        humanoid.WalkSpeed=speed
        currentWalkSpeed=speed
    end
end
local function applyJumpPower(power)
    if humanoid then
        humanoid.JumpPower=power
        currentJumpPower=power
    end
end
local function applySwimSpeed(speed)
    if humanoid then
        humanoid.WalkSpeed=speed
        swimSpeed=speed
    end
end
local function applyFly(state,speed,height)
    flyEnabled=state
    flySpeed=speed or 50
    flyHeight=height or 10
    if humanoid then
        humanoid.PlatformStand=state
    end
    if rootPart then
        rootPart.Velocity=Vector3.new(0,0,0)
    end
end
local function applyNoclip(state)
    noclipEnabled=state
    if character then
        for _,v in pairs(character:GetChildren()) do
            if v:IsA("BasePart") then
                v.CanCollide=not state
            end
        end
    end
end
local function applySpeedHack(state,multiplier)
    speedHackEnabled=state
    local speed=16
    if state then
        speed=16*(multiplier or 2)
    end
    applyWalkSpeed(speed)
end
local function applyGravity(scale)
    gravityScale=scale
    if workspace then
        workspace.Gravity=196.2*scale
    end
end
local function dash(direction,power)
    if dashCooldown>tick() then return false end
    if not rootPart then return false end
    local dir=direction or rootPart.CFrame.LookVector
    rootPart.Velocity=dir*power
    dashCooldown=tick()+1
    return true
end
local function teleportToPosition(position)
    if teleportCooldown>tick() then return false end
    if rootPart then
        rootPart.CFrame=CFrame.new(position)
        teleportCooldown=tick()+0.5
        return true
    end
    return false
end
local function jump()
    if humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        return true
    end
    return false
end
local function flyControl()
    if not flyEnabled or not rootPart then return end
    local direction=Vector3.new(0,0,0)
    local input=userInput
    if input:IsKeyDown(Enum.KeyCode.W) then
        direction=direction+rootPart.CFrame.LookVector
    end
    if input:IsKeyDown(Enum.KeyCode.S) then
        direction=direction-rootPart.CFrame.LookVector
    end
    if input:IsKeyDown(Enum.KeyCode.A) then
        direction=direction-rootPart.CFrame.RightVector
    end
    if input:IsKeyDown(Enum.KeyCode.D) then
        direction=direction+rootPart.CFrame.RightVector
    end
    if input:IsKeyDown(Enum.KeyCode.Space) then
        direction=direction+Vector3.new(0,1,0)
    end
    if input:IsKeyDown(Enum.KeyCode.LeftShift) then
        direction=direction-Vector3.new(0,1,0)
    end
    if direction.Magnitude>0 then
        direction=direction.Unit*flySpeed
        rootPart.Velocity=direction
    else
        rootPart.Velocity=Vector3.new(0,0,0)
    end
end
local function noclipControl()
    if noclipEnabled then
        for _,v in pairs(character:GetChildren()) do
            if v:IsA("BasePart") then
                v.CanCollide=false
            end
        end
    end
end
local function speedHackControl()
    if speedHackEnabled then
        if humanoid then
            humanoid.WalkSpeed=currentWalkSpeed*2
        end
    end
end
local function swimControl()
    if humanoid and humanoid:GetState()==Enum.HumanoidStateType.Swimming then
        humanoid.WalkSpeed=swimSpeed
    end
end
local function resetMovement()
    applyWalkSpeed(16)
    applyJumpPower(50)
    applyFly(false)
    applyNoclip(false)
    applySpeedHack(false)
    applyGravity(1)
    swimSpeed=10
end
local function processMovement(data)
    if not rootPart or not humanoid then updateCharacter() end
    if not rootPart or not humanoid then return end
    local walkSpeed=data.walkSpeed or 16
    local jumpPower=data.jumpPower or 50
    local fly=data.fly or false
    local noclip=data.noclip or false
    local speedHack=data.speedHack or false
    local swimSpeed=data.swimSpeed or 10
    local flySpeed=data.flySpeed or 50
    local gravity=data.gravity or 1
    local speedMultiplier=data.speedMultiplier or 2
    if walkSpeed~=currentWalkSpeed then
        applyWalkSpeed(walkSpeed)
    end
    if jumpPower~=currentJumpPower then
        applyJumpPower(jumpPower)
    end
    if fly then
        applyFly(true,flySpeed)
    else
        if flyEnabled then applyFly(false) end
    end
    if noclip then
        applyNoclip(true)
    else
        if noclipEnabled then applyNoclip(false) end
    end
    if speedHack then
        applySpeedHack(true,speedMultiplier)
    else
        if speedHackEnabled then applySpeedHack(false) end
    end
    applySwimSpeed(swimSpeed)
    applyGravity(gravity)
    if flyEnabled then
        flyControl()
    end
    if noclipEnabled then
        noclipControl()
    end
    if speedHackEnabled then
        speedHackControl()
    end
    swimControl()
end
local function startMovementLoop(data)
    if isRunning then return end
    isRunning=true
    task.spawn(function()
        while isRunning do
            wait(0.05)
            pcall(function()processMovement(data)end)
        end
    end)
end
function movement.Stop()
    isRunning=false
    resetMovement()
    return true
end
function movement.Apply(data)
    if not data then return false end
    dataRef=data
    if not isRunning then
        startMovementLoop(data)
    end
    return true
end
function movement.SetWalkSpeed(speed)
    if dataRef then dataRef.walkSpeed=speed return true end
    return false
end
function movement.SetJumpPower(power)
    if dataRef then dataRef.jumpPower=power return true end
    return false
end
function movement.ToggleFly()
    if dataRef then
        dataRef.fly=not dataRef.fly
        return dataRef.fly
    end
    return false
end
function movement.ToggleNoclip()
    if dataRef then
        dataRef.noclip=not dataRef.noclip
        return dataRef.noclip
    end
    return false
end
function movement.ToggleSpeedHack()
    if dataRef then
        dataRef.speedHack=not dataRef.speedHack
        return dataRef.speedHack
    end
    return false
end
function movement.SetSwimSpeed(speed)
    if dataRef then
        dataRef.swimSpeed=speed
        swimSpeed=speed
        return true
    end
    return false
end
function movement.SetFlySpeed(speed)
    if dataRef then
        dataRef.flySpeed=speed
        flySpeed=speed
        return true
    end
    return false
end
function movement.SetGravity(scale)
    if dataRef then
        dataRef.gravity=scale
        applyGravity(scale)
        return true
    end
    return false
end
function movement.SetSpeedMultiplier(mult)
    if dataRef then
        dataRef.speedMultiplier=mult
        return true
    end
    return false
end
function movement.Dash(direction,power)
    return dash(direction,power)
end
function movement.Teleport(position)
    return teleportToPosition(position)
end
function movement.Jump()
    return jump()
end
function movement.GetStatus()
    return{
        isRunning=isRunning,
        walkSpeed=currentWalkSpeed,
        jumpPower=currentJumpPower,
        flyEnabled=flyEnabled,
        noclipEnabled=noclipEnabled,
        speedHackEnabled=speedHackEnabled,
        swimSpeed=swimSpeed,
        flySpeed=flySpeed,
        gravity=gravityScale,
        dashCooldown=dashCooldown-tick()
    }
end
function movement.ResetToDefault()
    resetMovement()
    return true
end
function movement.EnableFly()
    if dataRef then dataRef.fly=true return true end
    return false
end
function movement.DisableFly()
    if dataRef then dataRef.fly=false return true end
    return false
end
function movement.EnableNoclip()
    if dataRef then dataRef.noclip=true return true end
    return false
end
function movement.DisableNoclip()
    if dataRef then dataRef.noclip=false return true end
    return false
end
function movement.EnableSpeedHack()
    if dataRef then dataRef.speedHack=true return true end
    return false
end
function movement.DisableSpeedHack()
    if dataRef then dataRef.speedHack=false return true end
    return false
end
function movement.SuperJump(power)
    if humanoid then
        humanoid.JumpPower=power or 200
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        wait(0.1)
        humanoid.JumpPower=currentJumpPower
        return true
    end
    return false
end
function movement.WallClimb(state)
    if humanoid then
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing,state)
        return true
    end
    return false
end
function movement.SetNoStun(state)
    if humanoid then
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead,state)
        return true
    end
    return false
end
function movement.FlyUp()
    if flyEnabled and rootPart then
        rootPart.Velocity=Vector3.new(0,flySpeed,0)
        return true
    end
    return false
end
function movement.FlyDown()
    if flyEnabled and rootPart then
        rootPart.Velocity=Vector3.new(0,-flySpeed,0)
        return true
    end
    return false
end
function movement.FlyForward()
    if flyEnabled and rootPart then
        rootPart.Velocity=rootPart.CFrame.LookVector*flySpeed
        return true
    end
    return false
end
function movement.FlyBackward()
    if flyEnabled and rootPart then
        rootPart.Velocity=-rootPart.CFrame.LookVector*flySpeed
        return true
    end
    return false
end
function movement.Pause()
    isRunning=false
    return true
end
function movement.Resume()
    if dataRef then
        isRunning=true
        startMovementLoop(dataRef)
        return true
    end
    return false
end
function movement.Destroy()
    isRunning=false
    resetMovement()
    dataRef=nil
    return true
end
function movement.Initialize(data)
    dataRef=data
    updateCharacter()
    userInput.InputBegan:Connect(function(input,gameProcessed)
        if gameProcessed then return end
        if input.KeyCode==Enum.KeyCode.F then
            if dataRef then dataRef.fly=not dataRef.fly end
        end
        if input.KeyCode==Enum.KeyCode.N then
            if dataRef then dataRef.noclip=not dataRef.noclip end
        end
        if input.KeyCode==Enum.KeyCode.LeftShift and dataRef and dataRef.fly then
            rootPart.Velocity=rootPart.CFrame.LookVector*100
        end
    end)
    return true
end
return movement
