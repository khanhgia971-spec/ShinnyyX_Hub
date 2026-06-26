local autoFarm={}autoFarm.__index=autoFarm
local player=game.Players.LocalPlayer
local runService=game:GetService("RunService")
local userInput=game:GetService("UserInputService")
local virtualUser=game:GetService("VirtualUser")
local tweenService=game:GetService("TweenService")
local workspace=game:GetService("Workspace")
local replicatedStorage=game:GetService("ReplicatedStorage")
local players=game:GetService("Players")
local collectionService=game:GetService("CollectionService")
local pathfindingService=game:GetService("PathfindingService")
local debris=game:GetService("Debris")
local character=nil local humanoid=nil local rootPart=nil local dataRef=nil local isRunning=false local currentTarget=nil local targetList={} local collectedItems={} local skillCooldowns={} local attackCooldown=0 local dodgeCooldown=0 local farmTimer=0 local questProgress=0
local function updateCharacter()character=player.Character or player.CharacterAdded:Wait()if character then humanoid=character:FindFirstChild("Humanoid")rootPart=character:FindFirstChild("HumanoidRootPart")end end
local function getDistance(pos1,pos2)return (pos1-pos2).Magnitude end
local function findNearestTarget(targetType,radius,ignoreList)local nearest=nil local minDist=math.huge local children=workspace:GetChildren()for _,v in pairs(children)do if v:IsA("Model")and v:FindFirstChild("Humanoid")and v:FindFirstChild("Head")then local name=v.Name if name~=player.Name and not table.find(ignoreList or {},name)then local humanoidCheck=v:FindFirstChild("Humanoid")if humanoidCheck and humanoidCheck.Health>0 then local dist=getDistance(rootPart.Position,v.Head.Position)if dist<radius and dist<minDist then if targetType=="Quái"and not v:FindFirstChild("IsPlayer")then nearest=v minDist=dist elseif targetType=="Boss"and v:FindFirstChild("IsBoss")then nearest=v minDist=dist elseif targetType=="NPC"and v:FindFirstChild("IsNPC")then nearest=v minDist=dist else if targetType=="Tất cả"then nearest=v minDist=dist end end end end end end end return nearest end
local function findFruitNearby(radius)local nearest=nil local minDist=math.huge for _,v in pairs(workspace:GetChildren())do if v:IsA("Part")and v:FindFirstChild("FruitTag")then local dist=getDistance(rootPart.Position,v.Position)if dist<radius and dist<minDist then nearest=v minDist=dist end end end return nearest end
local function moveTo(position,timeout)timeout=timeout or 5 local startTime=tick()local success=false if rootPart then local tweenInfo=TweenInfo.new((getDistance(rootPart.Position,position)/50),Enum.EasingStyle.Linear)local tween=tweenService:Create(rootPart,tweenInfo,{CFrame=CFrame.new(position)})tween:Play()repeat wait(0.1)until not tween.PlaybackState==Enum.PlaybackState.Playing or tick()-startTime>timeout if getDistance(rootPart.Position,position)<5 then success=true end end return success end
local function attackTarget(target)if not target or not rootPart then return end if attackCooldown>tick()then return end local head=target:FindFirstChild("Head")if head then rootPart.CFrame=CFrame.new(head.Position+Vector3.new(0,3,0))wait(0.1)if humanoid then humanoid:BreakJoints()end attackCooldown=tick()+0.5 end end
local function useSkill(skillName)if skillCooldowns[skillName]and skillCooldowns[skillName]>tick()then return end local key=Enum.KeyCode[skillName]or Enum.KeyCode.Q if key then userInput:SetKeyDown(key)wait(0.05)userInput:SetKeyUp(key)skillCooldowns[skillName]=tick()+2 end end
local function collectItem(part)if not part or not rootPart then return end if table.find(collectedItems,part)then return end local dist=getDistance(rootPart.Position,part.Position)if dist<10 then rootPart.CFrame=CFrame.new(part.Position)wait(0.2)table.insert(collectedItems,part)debris:AddItem(part,0.5)return true else moveTo(part.Position,2)return false end end
local function autoCollectAll(radius)local count=0 for _,v in pairs(workspace:GetChildren())do if v:IsA("Part")and v:FindFirstChild("TouchInterest")then local dist=getDistance(rootPart.Position,v.Position)if dist<radius then if collectItem(v)then count=count+1 end end end end return count end
local function checkQuestProgress()local quests=player:FindFirstChild("Quests")if quests then for _,v in pairs(quests:GetChildren())do if v:IsA("IntValue")and v.Value>0 then questProgress=v.Value end end end return questProgress end
local function completeQuest()local quests=player:FindFirstChild("Quests")if quests then for _,v in pairs(quests:GetChildren())do if v:IsA("IntValue")and v.Value<=0 then v:Destroy()end end end end
local function findNPCLocation(npcName)for _,v in pairs(workspace:GetChildren())do if v:IsA("Model")and v.Name==npcName and v:FindFirstChild("Head")then return v.Head.Position end end return nil end
local function moveToNPC(npcName)local pos=findNPCLocation(npcName)if pos then return moveTo(pos,5)end return false end
local function getPlayerStats()local stats={}for _,v in pairs(player:GetChildren())do if v:IsA("IntValue")or v:IsA("NumberValue")then stats[v.Name]=v.Value end end return stats end
local function optimizeFarmSpeed(speed)if humanoid then local currentWalk=humanoid.WalkSpeed local targetWalk=16*speed if targetWalk>currentWalk then humanoid.WalkSpeed=targetWalk end end end
local function checkBossSpawn()local bossList={}for _,v in pairs(workspace:GetChildren())do if v:IsA("Model")and v:FindFirstChild("Humanoid")and v:FindFirstChild("IsBoss")then table.insert(bossList,v)end end return bossList end
local function isTargetValid(target)if not target then return false end if not target:FindFirstChild("Humanoid")then return false end if not target:FindFirstChild("Head")then return false end if target:FindFirstChild("Humanoid").Health<=0 then return false end return true end
local function getTargetHealth(target)if target and target:FindFirstChild("Humanoid")then return target.Humanoid.Health end return 0 end
local function getTargetLevel(target)if target and target:FindFirstChild("Level")then return target.Level.Value end return 1 end
local function dodgeAttack()if dodgeCooldown>tick()then return end if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.Jumping)dodgeCooldown=tick()+1 end end
local function handleCombat(target,data)if not target then return end local dist=getDistance(rootPart.Position,target.Head.Position)if dist>10 then moveTo(target.Head.Position,3)end if data.useSkill then for _,skill in ipairs({"Q","E","R","T","Y"})do useSkill(skill)end end attackTarget(target)if data.autoDodge then dodgeAttack()end end
local function processFarm(data)if not rootPart or not humanoid then updateCharacter()end if not rootPart or not humanoid then return end local radius=data.radius or 500 local speed=data.speed or 1 local targetType=data.targetType or "Quái" local useSkill=data.useSkill or true local collect=data.collectItems or true local autoQuest=data.autoQuest or false farmTimer=farmTimer+0.1 if farmTimer%5==0 then optimizeFarmSpeed(speed)end if collect and farmTimer%2==0 then autoCollectAll(radius/2)end local target=findNearestTarget(targetType,radius,{player.Name})if target then currentTarget=target handleCombat(target,data)else currentTarget=nil if autoQuest then local quests=player:FindFirstChild("Quests")if quests then for _,v in pairs(quests:GetChildren())do if v:IsA("IntValue")and v.Value>0 then break end end end end end if autoQuest then local questNPC=data.questNPC or "NPC" local quests=player:FindFirstChild("Quests")if not quests or #quests:GetChildren()==0 then moveToNPC(questNPC)wait(1)end end end
local function startFarm(data)if isRunning then return end isRunning=true dataRef=data updateCharacter()task.spawn(function()while isRunning do wait(0.1)pcall(function()processFarm(data)end)end end)return true end
function autoFarm.Stop()isRunning=false currentTarget=nil return true end
function autoFarm.Run(data)if not data then return false end if not data.enabled then if isRunning then autoFarm.Stop()end return false end if not isRunning then return startFarm(data)else dataRef=data return true end end
function autoFarm.SetTargetType(targetType)if dataRef then dataRef.targetType=targetType return true end return false end
function autoFarm.SetRadius(radius)if dataRef then dataRef.radius=radius return true end return false end
function autoFarm.SetSpeed(speed)if dataRef then dataRef.speed=speed return true end return false end
function autoFarm.ToggleSkill()if dataRef then dataRef.useSkill=not dataRef.useSkill return dataRef.useSkill end return false end
function autoFarm.ToggleCollect()if dataRef then dataRef.collectItems=not dataRef.collectItems return dataRef.collectItems end return false end
function autoFarm.ToggleQuest()if dataRef then dataRef.autoQuest=not dataRef.autoQuest return dataRef.autoQuest end return false end
function autoFarm.GetStatus()return{isRunning=isRunning,currentTarget=currentTarget and currentTarget.Name or "None",targetListCount=#targetList,questProgress=questProgress,attackCooldown=attackCooldown-tick(),dodgeCooldown=dodgeCooldown-tick()}end
function autoFarm.GetTargetList()local list={}for _,v in pairs(workspace:GetChildren())do if v:IsA("Model")and v:FindFirstChild("Humanoid")and v:FindFirstChild("Head")and v.Name~=player.Name then table.insert(list,v.Name)end end return list end
function autoFarm.FindBosses()return checkBossSpawn()end
function autoFarm.MoveToPosition(pos)return moveTo(pos,5)end
function autoFarm.CollectItems(radius)return autoCollectAll(radius or 500)end
function autoFarm.SetQuestNPC(npcName)if dataRef then dataRef.questNPC=npcName return true end return false end
function autoFarm.ResetCooldowns()attackCooldown=0 dodgeCooldown=0 skillCooldowns={}return true end
function autoFarm.GetCurrentTarget()return currentTarget end
function autoFarm.IsRunning()return isRunning end
function autoFarm.Pause()isRunning=false return true end
function autoFarm.Resume()if dataRef and dataRef.enabled then isRunning=true return true end return false end
function autoFarm.Destroy()autoFarm.Stop()dataRef=nil currentTarget=nil collectedItems={}return true end
function autoFarm.Initialize(data)dataRef=data updateCharacter()return true end
return autoFarm
