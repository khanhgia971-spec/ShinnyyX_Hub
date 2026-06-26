local animations={}
animations.__index=animations
local player=game.Players.LocalPlayer
local runService=game:GetService("RunService")
local tweenService=game:GetService("TweenService")
local workspace=game:GetService("Workspace")
local lighting=game:GetService("Lighting")
local debris=game:GetService("Debris")
local collectionService=game:GetService("CollectionService")
local replicatedStorage=game:GetService("ReplicatedStorage")
local coreGui=game:GetService("CoreGui")
local guiService=game:GetService("GuiService")
local userInput=game:GetService("UserInputService")
local dataRef=nil
local activeTweens={}
local animationQueue={}
local queueRunning=false
local function createTween(obj,properties,duration,style,direction,delay,repeatCount,reverses)
    duration=duration or 0.5
    style=style or Enum.EasingStyle.Quad
    direction=direction or Enum.EasingDirection.Out
    delay=delay or 0
    repeatCount=repeatCount or 0
    reverses=reverses or false
    local tweenInfo=TweenInfo.new(duration,style,direction,repeatCount,reverses,delay)
    local tween=tweenService:Create(obj,tweenInfo,properties)
    tween:Play()
    table.insert(activeTweens,tween)
    tween.Completed:Connect(function()
        for i,v in ipairs(activeTweens)do
            if v==tween then table.remove(activeTweens,i) break end
        end
    end)
    return tween
end
local function stopAllTweens()
    for _,tween in pairs(activeTweens)do
        pcall(function()tween:Cancel()end)
    end
    activeTweens={}
end
local function stopTween(tween)
    pcall(function()tween:Cancel()end)
    for i,v in ipairs(activeTweens)do
        if v==tween then table.remove(activeTweens,i) break end
    end
end
local function fadeIn(obj,duration)
    duration=duration or 0.5
    obj.Transparency=1
    return createTween(obj,{Transparency=0},duration,Enum.EasingStyle.Linear)
end
local function fadeOut(obj,duration)
    duration=duration or 0.5
    obj.Transparency=0
    return createTween(obj,{Transparency=1},duration,Enum.EasingStyle.Linear)
end
local function slideIn(obj,direction,distance,duration)
    duration=duration or 0.5
    direction=direction or "Left"
    distance=distance or 100
    local startPos=obj.Position
    local offset=UDim2.new(0,0,0,0)
    if direction=="Left" then offset=UDim2.new(0,-distance,0,0)
    elseif direction=="Right" then offset=UDim2.new(0,distance,0,0)
    elseif direction=="Up" then offset=UDim2.new(0,0,0,-distance)
    elseif direction=="Down" then offset=UDim2.new(0,0,0,distance) end
    obj.Position=startPos+offset
    return createTween(obj,{Position=startPos},duration,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
end
local function slideOut(obj,direction,distance,duration)
    duration=duration or 0.5
    direction=direction or "Left"
    distance=distance or 100
    local endPos=obj.Position
    local offset=UDim2.new(0,0,0,0)
    if direction=="Left" then offset=UDim2.new(0,-distance,0,0)
    elseif direction=="Right" then offset=UDim2.new(0,distance,0,0)
    elseif direction=="Up" then offset=UDim2.new(0,0,0,-distance)
    elseif direction=="Down" then offset=UDim2.new(0,0,0,distance) end
    return createTween(obj,{Position=endPos+offset},duration,Enum.EasingStyle.Quad,Enum.EasingDirection.In)
end
local function scaleIn(obj,startScale,endScale,duration)
    duration=duration or 0.5
    startScale=startScale or 0.5
    endScale=endScale or 1
    obj.Size=obj.Size*(startScale/endScale)
    return createTween(obj,{Size=obj.Size*(endScale/startScale)},duration,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
end
local function scaleOut(obj,endScale,duration)
    duration=duration or 0.5
    endScale=endScale or 0.5
    return createTween(obj,{Size=obj.Size*endScale},duration,Enum.EasingStyle.Back,Enum.EasingDirection.In)
end
local function rotate(obj,angle,duration)
    duration=duration or 1
    return createTween(obj,{Rotation=angle},duration,Enum.EasingStyle.Linear)
end
local function pulse(obj,scaleMult,duration,repeatCount)
    scaleMult=scaleMult or 1.2
    duration=duration or 0.5
    repeatCount=repeatCount or -1
    local originalSize=obj.Size
    local tween1=createTween(obj,{Size=originalSize*scaleMult},duration/2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
    local tween2=createTween(obj,{Size=originalSize},duration/2,Enum.EasingStyle.Quad,Enum.EasingDirection.In)
    tween1.Completed:Connect(function()
        tween2:Play()
    end)
    local count=0
    local function repeatPulse()
        if repeatCount==-1 or count<repeatCount then
            tween1:Play()
            count=count+1
        end
    end
    tween2.Completed:Connect(repeatPulse)
    return {tween1=tween1,tween2=tween2}
end
local function glow(obj,color,transparency,duration)
    duration=duration or 0.5
    color=color or Color3.fromRGB(0,200,255)
    transparency=transparency or 0.3
    local originalColor=obj.BackgroundColor3
    local originalTransparency=obj.BackgroundTransparency
    local tween1=createTween(obj,{BackgroundColor3=color,BackgroundTransparency=transparency},duration/2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
    local tween2=createTween(obj,{BackgroundColor3=originalColor,BackgroundTransparency=originalTransparency},duration/2,Enum.EasingStyle.Quad,Enum.EasingDirection.In)
    tween1.Completed:Connect(function()tween2:Play()end)
    return {tween1=tween1,tween2=tween2}
end
local function ripple(obj,color,size,duration)
    duration=duration or 1
    color=color or Color3.fromRGB(255,255,255)
    size=size or 50
    local ripplePart=Instance.new("Part")
    ripplePart.Size=Vector3.new(0,0,0)
    ripplePart.Position=obj.Position+Vector3.new(0,0.5,0)
    ripplePart.Anchored=true
    ripplePart.CanCollide=false
    ripplePart.BrickColor=BrickColor.new(color)
    ripplePart.Transparency=1
    ripplePart.Parent=workspace
    local tween=createTween(ripplePart,{Size=Vector3.new(size,1,size),Transparency=0},duration/2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
    tween.Completed:Connect(function()
        createTween(ripplePart,{Transparency=1},duration/2,Enum.EasingStyle.Linear):Completed:Connect(function()ripplePart:Destroy()end)
    end)
    return tween
end
local function shake(obj,intensity,duration)
    intensity=intensity or 5
    duration=duration or 0.5
    local originalPos=obj.Position
    local tweenTable={}
    for i=1,10 do
        local offset=Vector3.new(math.random(-intensity,intensity),math.random(-intensity,intensity),math.random(-intensity,intensity))
        local tween=createTween(obj,{Position=originalPos+offset},duration/20,Enum.EasingStyle.Linear)
        table.insert(tweenTable,tween)
    end
    local tween=createTween(obj,{Position=originalPos},duration/20,Enum.EasingStyle.Linear)
    table.insert(tweenTable,tween)
    for i=1,#tweenTable do
        tweenTable[i]:Play()
    end
    return tweenTable
end
local function bounce(obj,height,duration)
    height=height or 20
    duration=duration or 0.5
    local originalPos=obj.Position
    local mid=originalPos+Vector3.new(0,height,0)
    local tween1=createTween(obj,{Position=mid},duration/2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
    local tween2=createTween(obj,{Position=originalPos},duration/2,Enum.EasingStyle.Quad,Enum.EasingDirection.In)
    tween1.Completed:Connect(function()tween2:Play()end)
    return {tween1=tween1,tween2=tween2}
end
local function spin(obj,duration,revolutions)
    duration=duration or 1
    revolutions=revolutions or 1
    local angle=revolutions*360
    return createTween(obj,{Rotation=angle},duration,Enum.EasingStyle.Linear)
end
local function typewriter(label,text,charDelay)
    charDelay=charDelay or 0.05
    label.Text=""
    local chars=string.split(text,"")
    for i,char in ipairs(chars) do
        label.Text=label.Text..char
        task.wait(charDelay)
    end
end
local function progressBar(bar,fill,label,start,endVal,duration)
    duration=duration or 1
    start=start or 0
    endVal=endVal or 1
    fill.Size=UDim2.new(start,0,1,0)
    local tween=createTween(fill,{Size=UDim2.new(endVal,0,1,0)},duration,Enum.EasingStyle.Linear)
    if label then
        tween:Connect("Update",function()
            local progress=fill.Size.X.Scale
            label.Text=math.floor(progress*100).."%"
        end)
    end
    return tween
end
local function colorTransition(obj,color1,color2,duration,repeats)
    duration=duration or 1
    repeats=repeats or -1
    local tween1=createTween(obj,{BackgroundColor3=color2},duration/2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
    local tween2=createTween(obj,{BackgroundColor3=color1},duration/2,Enum.EasingStyle.Quad,Enum.EasingDirection.In)
    tween1.Completed:Connect(function()tween2:Play()end)
    local count=0
    local function repeatColor()
        if repeats==-1 or count<repeats then
            tween1:Play()
            count=count+1
        end
    end
    tween2.Completed:Connect(repeatColor)
    return {tween1=tween1,tween2=tween2}
end
local function sizeTransition(obj,size1,size2,duration)
    duration=duration or 0.5
    obj.Size=size1
    return createTween(obj,{Size=size2},duration,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
end
local function positionTransition(obj,pos1,pos2,duration)
    duration=duration or 0.5
    obj.Position=pos1
    return createTween(obj,{Position=pos2},duration,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
end
local function transparencyTransition(obj,trans1,trans2,duration)
    duration=duration or 0.5
    obj.BackgroundTransparency=trans1
    return createTween(obj,{BackgroundTransparency=trans2},duration,Enum.EasingStyle.Linear)
end
local function imageTransition(img,image1,image2,duration)
    duration=duration or 0.5
    img.Image=image1
    return createTween(img,{Image=image2},duration,Enum.EasingStyle.Linear)
end
local function sequence(animations,duration)
    duration=duration or 0.5
    local seq={}
    for i,anim in ipairs(animations) do
        if type(anim)=="table" and anim.tween then
            table.insert(seq,anim)
        else
            local tween=createTween(anim.obj,anim.properties,anim.duration or duration,anim.style or Enum.EasingStyle.Quad,anim.direction or Enum.EasingDirection.Out)
            table.insert(seq,{tween=tween})
        end
    end
    for i=1,#seq-1 do
        seq[i].tween.Completed:Connect(function()
            seq[i+1].tween:Play()
        end)
    end
    if #seq>0 then seq[1].tween:Play() end
    return seq
end
local function parallel(animations)
    local tweens={}
    for _,anim in ipairs(animations) do
        if type(anim)=="table" and anim.tween then
            anim.tween:Play()
            table.insert(tweens,anim.tween)
        else
            local tween=createTween(anim.obj,anim.properties,anim.duration or 0.5,anim.style or Enum.EasingStyle.Quad,anim.direction or Enum.EasingDirection.Out)
            table.insert(tweens,tween)
        end
    end
    return tweens
end
local function easeInOut(obj,property,startVal,endVal,duration)
    duration=duration or 0.5
    local props={}
    props[property]=startVal
    obj[property]=startVal
    local tween=createTween(obj,{props},duration,Enum.EasingStyle.Quad,Enum.EasingDirection.InOut)
    return tween
end
local function createPulseEffect(obj,property,minVal,maxVal,duration,repeats)
    duration=duration or 1
    repeats=repeats or -1
    local props1={}
    props1[property]=maxVal
    local props2={}
    props2[property]=minVal
    local tween1=createTween(obj,props1,duration/2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
    local tween2=createTween(obj,props2,duration/2,Enum.EasingStyle.Quad,Enum.EasingDirection.In)
    tween1.Completed:Connect(function()tween2:Play()end)
    local count=0
    local function repeatPulse()
        if repeats==-1 or count<repeats then
            tween1:Play()
            count=count+1
        end
    end
    tween2.Completed:Connect(repeatPulse)
    return {tween1=tween1,tween2=tween2}
end
local function createRippleEffect(part,color,radius,life)
    life=life or 1
    radius=radius or 10
    color=color or Color3.fromRGB(255,255,255)
    local ring=Instance.new("Part")
    ring.Size=Vector3.new(0.1,0.1,0.1)
    ring.Position=part.Position+Vector3.new(0,0.5,0)
    ring.Anchored=true
    ring.CanCollide=false
    ring.BrickColor=BrickColor.new(color)
    ring.Transparency=1
    ring.Parent=workspace
    local tween=createTween(ring,{Size=Vector3.new(radius,0.2,radius),Transparency=0},life/2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
    tween.Completed:Connect(function()
        createTween(ring,{Transparency=1},life/2,Enum.EasingStyle.Linear):Completed:Connect(function()ring:Destroy()end)
    end)
    return tween
end
local function createShakeEffect(obj,intensity,duration)
    intensity=intensity or 5
    duration=duration or 0.5
    local originalPos=obj.Position
    local tweens={}
    for i=1,20 do
        local offset=Vector3.new(math.random(-intensity,intensity),math.random(-intensity,intensity),math.random(-intensity,intensity))
        local t=createTween(obj,{Position=originalPos+offset},duration/20,Enum.EasingStyle.Linear)
        table.insert(tweens,t)
    end
    local t=createTween(obj,{Position=originalPos},duration/20,Enum.EasingStyle.Linear)
    table.insert(tweens,t)
    for _,t in ipairs(tweens) do t:Play() end
    return tweens
end
local function createGlowEffect(obj,color,intensity,duration)
    duration=duration or 0.5
    intensity=intensity or 50
    color=color or Color3.fromRGB(0,200,255)
    local glow=Instance.new("SelectionBox")
    glow.Adornee=obj
    glow.Color3=color
    glow.Transparency=0.5
    glow.Parent=obj
    local tween=createTween(glow,{Transparency=0},duration/2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
    tween.Completed:Connect(function()
        createTween(glow,{Transparency=0.5},duration/2,Enum.EasingStyle.Quad,Enum.EasingDirection.In)
    end)
    return tween
end
local function createTypewriterEffect(label,text,charDelay)
    charDelay=charDelay or 0.05
    label.Text=""
    local chars=string.split(text,"")
    for i,char in ipairs(chars) do
        label.Text=label.Text..char
        task.wait(charDelay)
    end
end
local function createSlideInEffect(obj,direction,offset,duration)
    duration=duration or 0.5
    direction=direction or "Left"
    offset=offset or 100
    local startPos=obj.Position
    local delta=UDim2.new(0,0,0,0)
    if direction=="Left" then delta=UDim2.new(0,-offset,0,0)
    elseif direction=="Right" then delta=UDim2.new(0,offset,0,0)
    elseif direction=="Up" then delta=UDim2.new(0,0,0,-offset)
    elseif direction=="Down" then delta=UDim2.new(0,0,0,offset) end
    obj.Position=startPos+delta
    return createTween(obj,{Position=startPos},duration,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
end
local function createSlideOutEffect(obj,direction,offset,duration)
    duration=duration or 0.5
    direction=direction or "Left"
    offset=offset or 100
    local startPos=obj.Position
    local delta=UDim2.new(0,0,0,0)
    if direction=="Left" then delta=UDim2.new(0,-offset,0,0)
    elseif direction=="Right" then delta=UDim2.new(0,offset,0,0)
    elseif direction=="Up" then delta=UDim2.new(0,0,0,-offset)
    elseif direction=="Down" then delta=UDim2.new(0,0,0,offset) end
    return createTween(obj,{Position=startPos+delta},duration,Enum.EasingStyle.Quad,Enum.EasingDirection.In)
end
local function createScaleInEffect(obj,startScale,endScale,duration)
    duration=duration or 0.5
    startScale=startScale or 0.5
    endScale=endScale or 1
    obj.Size=obj.Size*(startScale/endScale)
    return createTween(obj,{Size=obj.Size*(endScale/startScale)},duration,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
end
local function createScaleOutEffect(obj,endScale,duration)
    duration=duration or 0.5
    endScale=endScale or 0.5
    return createTween(obj,{Size=obj.Size*endScale},duration,Enum.EasingStyle.Back,Enum.EasingDirection.In)
end
local function createFadeInEffect(obj,duration)
    duration=duration or 0.5
    obj.BackgroundTransparency=1
    return createTween(obj,{BackgroundTransparency=0},duration,Enum.EasingStyle.Linear)
end
local function createFadeOutEffect(obj,duration)
    duration=duration or 0.5
    obj.BackgroundTransparency=0
    return createTween(obj,{BackgroundTransparency=1},duration,Enum.EasingStyle.Linear)
end
local function createRotateEffect(obj,angle,duration,repeats)
    duration=duration or 1
    angle=angle or 360
    repeats=repeats or 1
    local t=createTween(obj,{Rotation=angle},duration,Enum.EasingStyle.Linear,Enum.EasingDirection.Out)
    if repeats>1 then
        t.Completed:Connect(function()
            for i=2,repeats do
                local t2=createTween(obj,{Rotation=angle*i},duration,Enum.EasingStyle.Linear,Enum.EasingDirection.Out)
                if i==repeats then
                    t2.Completed:Connect(function()
                        createTween(obj,{Rotation=0},duration,Enum.EasingStyle.Linear)
                    end)
                end
            end
        end)
    end
    return t
end
local function createBounceEffect(obj,height,duration)
    height=height or 20
    duration=duration or 0.5
    local originalPos=obj.Position
    local mid=originalPos+Vector3.new(0,height,0)
    local t1=createTween(obj,{Position=mid},duration/2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
    local t2=createTween(obj,{Position=originalPos},duration/2,Enum.EasingStyle.Quad,Enum.EasingDirection.In)
    t1.Completed:Connect(function()t2:Play()end)
    return {t1=t1,t2=t2}
end
local function createPulseLoop(obj,property,minVal,maxVal,duration)
    duration=duration or 1
    local props1={}
    props1[property]=maxVal
    local props2={}
    props2[property]=minVal
    local t1=createTween(obj,props1,duration/2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
    local t2=createTween(obj,props2,duration/2,Enum.EasingStyle.Quad,Enum.EasingDirection.In)
    t1.Completed:Connect(function()t2:Play()end)
    t2.Completed:Connect(function()t1:Play()end)
    return {t1=t1,t2=t2}
end
local function createColorShift(obj,colors,duration)
    duration=duration or 1
    local index=1
    local function shift()
        if index>#colors then index=1 end
        local nextIndex=index+1
        if nextIndex>#colors then nextIndex=1 end
        local t=createTween(obj,{BackgroundColor3=colors[nextIndex]},duration,Enum.EasingStyle.Linear)
        t.Completed:Connect(function()
            index=nextIndex
            shift()
        end)
        index=nextIndex
        return t
    end
    return shift()
end
local function createProgressAnimation(bar,fill,label,startVal,endVal,duration)
    duration=duration or 1
    fill.Size=UDim2.new(startVal,0,1,0)
    local t=createTween(fill,{Size=UDim2.new(endVal,0,1,0)},duration,Enum.EasingStyle.Linear)
    if label then
        t:Connect("Update",function()
            label.Text=math.floor(fill.Size.X.Scale*100).."%"
        end)
    end
    return t
end
local function createMoveTo(obj,targetPos,duration)
    duration=duration or 0.5
    return createTween(obj,{Position=targetPos},duration,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
end
local function createResizeTo(obj,targetSize,duration)
    duration=duration or 0.5
    return createTween(obj,{Size=targetSize},duration,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
end
local function createColorTo(obj,targetColor,duration)
    duration=duration or 0.5
    return createTween(obj,{BackgroundColor3=targetColor},duration,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
end
local function createTransparencyTo(obj,targetTransparency,duration)
    duration=duration or 0.5
    return createTween(obj,{BackgroundTransparency=targetTransparency},duration,Enum.EasingStyle.Linear)
end
local function createScaleTo(obj,targetScale,duration)
    duration=duration or 0.5
    return createTween(obj,{Size=obj.Size*targetScale},duration,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
end
local function createRotateTo(obj,targetAngle,duration)
    duration=duration or 0.5
    return createTween(obj,{Rotation=targetAngle},duration,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
end
local function createImageFade(img,image1,image2,duration)
    duration=duration or 0.5
    img.Image=image1
    local t=createTween(img,{Image=image2},duration,Enum.EasingStyle.Linear)
    return t
end
local function createSequenceAnim(animations)
    local seq={}
    for _,anim in ipairs(animations) do
        local t
        if anim.tween then
            t=anim.tween
        else
            t=createTween(anim.obj,anim.properties,anim.duration or 0.5,anim.style or Enum.EasingStyle.Quad,anim.direction or Enum.EasingDirection.Out)
        end
        table.insert(seq,t)
    end
    for i=1,#seq-1 do
        seq[i].Completed:Connect(function()seq[i+1]:Play()end)
    end
    if #seq>0 then seq[1]:Play() end
    return seq
end
local function createParallelAnim(animations)
    local tweens={}
    for _,anim in ipairs(animations) do
        local t
        if anim.tween then
            t=anim.tween
        else
            t=createTween(anim.obj,anim.properties,anim.duration or 0.5,anim.style or Enum.EasingStyle.Quad,anim.direction or Enum.EasingDirection.Out)
        end
        table.insert(tweens,t)
        t:Play()
    end
    return tweens
end
local function stopAll()
    stopAllTweens()
end
local function pauseAll()
    for _,tween in pairs(activeTweens)do
        pcall(function()tween:Pause()end)
    end
end
local function resumeAll()
    for _,tween in pairs(activeTweens)do
        pcall(function()tween:Play()end)
    end
end
local function getActiveCount()
    return #activeTweens
end
local function clearQueue()
    animationQueue={}
    queueRunning=false
end
local function addToQueue(anim)
    table.insert(animationQueue,anim)
    if not queueRunning then
        queueRunning=true
        task.spawn(function()
            while #animationQueue>0 do
                local anim=table.remove(animationQueue,1)
                if anim and anim.tween then
                    anim.tween:Play()
                    anim.tween.Completed:Wait()
                elseif type(anim)=="function" then
                    anim()
                end
            end
            queueRunning=false
        end)
    end
end
local function initialize(data)
    dataRef=data
    return true
end
animations.Initialize=initialize
animations.createTween=createTween
animations.stopAll=stopAll
animations.stopTween=stopTween
animations.fadeIn=fadeIn
animations.fadeOut=fadeOut
animations.slideIn=slideIn
animations.slideOut=slideOut
animations.scaleIn=scaleIn
animations.scaleOut=scaleOut
animations.rotate=rotate
animations.pulse=pulse
animations.glow=glow
animations.ripple=ripple
animations.shake=shake
animations.bounce=bounce
animations.spin=spin
animations.typewriter=typewriter
animations.progressBar=progressBar
animations.colorTransition=colorTransition
animations.sizeTransition=sizeTransition
animations.positionTransition=positionTransition
animations.transparencyTransition=transparencyTransition
animations.imageTransition=imageTransition
animations.sequence=sequence
animations.parallel=parallel
animations.easeInOut=easeInOut
animations.createPulseEffect=createPulseEffect
animations.createRippleEffect=createRippleEffect
animations.createShakeEffect=createShakeEffect
animations.createGlowEffect=createGlowEffect
animations.createTypewriterEffect=createTypewriterEffect
animations.createSlideInEffect=createSlideInEffect
animations.createSlideOutEffect=createSlideOutEffect
animations.createScaleInEffect=createScaleInEffect
animations.createScaleOutEffect=createScaleOutEffect
animations.createFadeInEffect=createFadeInEffect
animations.createFadeOutEffect=createFadeOutEffect
animations.createRotateEffect=createRotateEffect
animations.createBounceEffect=createBounceEffect
animations.createPulseLoop=createPulseLoop
animations.createColorShift=createColorShift
animations.createProgressAnimation=createProgressAnimation
animations.createMoveTo=createMoveTo
animations.createResizeTo=createResizeTo
animations.createColorTo=createColorTo
animations.createTransparencyTo=createTransparencyTo
animations.createScaleTo=createScaleTo
animations.createRotateTo=createRotateTo
animations.createImageFade=createImageFade
animations.createSequenceAnim=createSequenceAnim
animations.createParallelAnim=createParallelAnim
animations.stopAll=stopAll
animations.pauseAll=pauseAll
animations.resumeAll=resumeAll
animations.getActiveCount=getActiveCount
animations.clearQueue=clearQueue
animations.addToQueue=addToQueue
return animations
