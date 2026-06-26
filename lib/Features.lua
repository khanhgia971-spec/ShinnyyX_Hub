local features={}features.__index=features
local player=game.Players.LocalPlayer
local runService=game:GetService("RunService")
local httpService=game:GetService("HttpService")
local featuresData={}
local modules={}
local dataRef=nil
local function deepCopy(t)local r={}for k,v in pairs(t)do if type(v)=="table"then r[k]=deepCopy(v)else r[k]=v end end return r end
local function mergeTables(t1,t2)for k,v in pairs(t2)do if type(v)=="table"and type(t1[k])=="table"then mergeTables(t1[k],v)else t1[k]=v end end return t1 end
function features.Initialize(data,mods)dataRef=data modules=mods or {}featuresData=deepCopy(data)print("[Features] Initialized with "..tostring(#modules).." modules")return features end
function features.GetFeature(path)local parts={}for part in string.gmatch(path,"[^%.]+")do table.insert(parts,part)end local current=dataRef for _,part in ipairs(parts)do if current and type(current)=="table"then current=current[part]else return nil end end return current end
function features.SetFeature(path,value)local parts={}for part in string.gmatch(path,"[^%.]+")do table.insert(parts,part)end local current=dataRef for i=1,#parts-1 do local part=parts[i]if type(current[part])~="table"then current[part]={}end current=current[part]end current[parts[#parts]]=value return true end
function features.ToggleFeature(path)local current=features.GetFeature(path)if type(current)=="boolean"then features.SetFeature(path,not current)return not current end return nil end
function features.GetAllFeatures()return deepCopy(dataRef)end
function features.SaveFeatures()if modules.Settings and modules.Settings.Save then modules.Settings:Save(dataRef)return true end return false end
function features.LoadFeatures()if modules.Settings and modules.Settings.Load then modules.Settings:Load(dataRef)return true end return false end
function features.ResetFeatures()dataRef=deepCopy(featuresData)return true end
function features.RegisterModule(name,func)modules[name]=func return true end
function features.GetModule(name)return modules[name]end
function features.CallModule(name,...)if modules[name]then return modules[name](...)end return nil end
function features.IsFeatureEnabled(path)local val=features.GetFeature(path)if type(val)=="boolean"then return val else return false end end
function features.EnableFeature(path)return features.SetFeature(path,true)end
function features.DisableFeature(path)return features.SetFeature(path,false)end
function features.ListAllFeatures(t,prefix)local result={}prefix=prefix or""for k,v in pairs(t or dataRef)do local key=prefix..k if type(v)=="table"then for _,sub in ipairs(features.ListAllFeatures(v,key.."."))do table.insert(result,sub)end else table.insert(result,{path=key,value=v,type=type(v)})end end return result end
function features.SearchFeatures(pattern)local all=features.ListAllFeatures()local result={}for _,item in ipairs(all)do if string.find(item.path,pattern)then table.insert(result,item)end end return result end
function features.ExportFeatures()return httpService:JSONEncode(dataRef)end
function features.ImportFeatures(json)local success,decoded=pcall(function()return httpService:JSONDecode(json)end)if success then dataRef=decoded return true else return false end end
function features.WatchFeature(path,callback)local last=features.GetFeature(path)runService.Heartbeat:Connect(function()local current=features.GetFeature(path)if current~=last then last=current callback(current,last)end end)end
function features.BulkSet(table)for k,v in pairs(table)do features.SetFeature(k,v)end return true end
function features.BulkToggle(table)for _,path in ipairs(table)do features.ToggleFeature(path)end return true end
function features.GetAllEnabled()local all=features.ListAllFeatures()local enabled={}for _,item in ipairs(all)do if item.value==true then table.insert(enabled,item.path)end end return enabled end
function features.GetAllDisabled()local all=features.ListAllFeatures()local disabled={}for _,item in ipairs(all)do if item.value==false then table.insert(disabled,item.path)end end return disabled end
function features.CountFeatures()return #features.ListAllFeatures()end
function features.CountEnabled()return #features.GetAllEnabled()end
function features.CountDisabled()return #features.GetAllDisabled()end
function features.ResetToDefault()dataRef=deepCopy(featuresData)return true end
function features.Backup()return deepCopy(dataRef)end
function features.Restore(backup)if backup then dataRef=deepCopy(backup)return true end return false end
function features.PrintStatus()local total=features.CountFeatures()local enabled=features.CountEnabled()local disabled=features.CountDisabled()print("[Features] Total: "..total.." | Enabled: "..enabled.." | Disabled: "..disabled)end
function features.GetModuleList()local list={}for k,_ in pairs(modules)do table.insert(list,k)end return list end
function features.HealthCheck()local ok=true for _,name in ipairs({"AutoFarm","AutoQuest","Teleport","ESP","Combat","Movement","Items","Player","World","Settings"})do if not modules[name]then ok=false warn("[Features] Missing module: "..name)end end return ok end
function features.SyncAll()for _,item in ipairs(features.ListAllFeatures())do local path=item.path local parts={}for part in string.gmatch(path,"[^%.]+")do table.insert(parts,part)end if #parts>=2 then local moduleName=parts[1]local featureName=parts[2]if modules[moduleName]and modules[moduleName]["Sync"]then modules[moduleName]:Sync(featureName,item.value)end end end end
function features.OnChange(path,callback)return features.WatchFeature(path,callback)end
function features.DebugInfo()return{version="4.0.0",totalFeatures=features.CountFeatures(),modules=features.GetModuleList(),dataSize=string.len(httpService:JSONEncode(dataRef))}end
function features.Reload()features.LoadFeatures()features.SyncAll()return true end
return features
