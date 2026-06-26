local library={}
library.__index=library
local player=game.Players.LocalPlayer
local runService=game:GetService("RunService")
local httpService=game:GetService("HttpService")
local workspace=game:GetService("Workspace")
local players=game:GetService("Players")
local dataRef=nil
local function deepCopy(t,seen)
    seen=seen or {}
    if type(t)~="table" then return t end
    if seen[t] then return seen[t] end
    local r={}
    seen[t]=r
    for k,v in pairs(t) do
        r[k]=deepCopy(v,seen)
    end
    setmetatable(r,getmetatable(t))
    return r
end
local function mergeTables(t1,t2,overwrite)
    overwrite=overwrite or false
    local result=deepCopy(t1)
    for k,v in pairs(t2) do
        if type(v)=="table" and type(result[k])=="table" then
            result[k]=mergeTables(result[k],v,overwrite)
        else
            if overwrite or result[k]==nil then
                result[k]=v
            end
        end
    end
    return result
end
local function tableFilter(t,func)
    local r={}
    for k,v in pairs(t) do
        if func(v,k) then
            r[k]=v
        end
    end
    return r
end
local function tableMap(t,func)
    local r={}
    for k,v in pairs(t) do
        r[k]=func(v,k)
    end
    return r
end
local function tableReduce(t,func,initial)
    local acc=initial
    for k,v in pairs(t) do
        acc=func(acc,v,k)
    end
    return acc
end
local function tableFind(t,func)
    for k,v in pairs(t) do
        if func(v,k) then
            return v,k
        end
    end
    return nil
end
local function tableFindAll(t,func)
    local r={}
    for k,v in pairs(t) do
        if func(v,k) then
            table.insert(r,{key=k,value=v})
        end
    end
    return r
end
local function tableGroupBy(t,func)
    local r={}
    for k,v in pairs(t) do
        local group=func(v,k)
        if not r[group] then r[group]={} end
        r[group][k]=v
    end
    return r
end
local function tableSort(t,func)
    local keys={}
    for k,_ in pairs(t) do table.insert(keys,k) end
    table.sort(keys,function(a,b)return func(t[a],t[b])end)
    local r={}
    for _,k in ipairs(keys) do r[k]=t[k] end
    return r
end
local function tableKeys(t)
    local r={}
    for k,_ in pairs(t) do table.insert(r,k) end
    return r
end
local function tableValues(t)
    local r={}
    for _,v in pairs(t) do table.insert(r,v) end
    return r
end
local function tableSize(t)
    local count=0
    for _,_ in pairs(t) do count=count+1 end
    return count
end
local function tableIsEmpty(t)
    return tableSize(t)==0
end
local function tableContains(t,value)
    for _,v in pairs(t) do
        if v==value then return true end
    end
    return false
end
local function tableContainsKey(t,key)
    return t[key]~=nil
end
local function tableRemoveValue(t,value)
    for i,v in ipairs(t) do
        if v==value then
            table.remove(t,i)
            return true
        end
    end
    return false
end
local function tableRemoveKey(t,key)
    if t[key]~=nil then
        t[key]=nil
        return true
    end
    return false
end
local function tableInsertUnique(t,value)
    if not tableContains(t,value) then
        table.insert(t,value)
        return true
    end
    return false
end
local function tableChunk(t,size)
    size=size or 10
    local r={}
    local chunk={}
    for i,v in ipairs(t) do
        table.insert(chunk,v)
        if #chunk>=size then
            table.insert(r,chunk)
            chunk={}
        end
    end
    if #chunk>0 then table.insert(r,chunk) end
    return r
end
local function tableShuffle(t)
    local r=deepCopy(t)
    for i=#r,2,-1 do
        local j=math.random(i)
        r[i],r[j]=r[j],r[i]
    end
    return r
end
local function tableReverse(t)
    local r={}
    for i=#t,1,-1 do
        table.insert(r,t[i])
    end
    return r
end
local function tableUnique(t)
    local seen={}
    local r={}
    for _,v in ipairs(t) do
        if not seen[v] then
            seen[v]=true
            table.insert(r,v)
        end
    end
    return r
end
local function tableDifference(t1,t2)
    local r={}
    for k,v in pairs(t1) do
        if t2[k]==nil then r[k]=v end
    end
    return r
end
local function tableIntersection(t1,t2)
    local r={}
    for k,v in pairs(t1) do
        if t2[k]~=nil then r[k]=v end
    end
    return r
end
local function tableMerge(t1,t2)
    return mergeTables(t1,t2,false)
end
local function tableOverride(t1,t2)
    return mergeTables(t1,t2,true)
end
local function tableSerialize(t)
    return httpService:JSONEncode(t)
end
local function tableDeserialize(str)
    local success,r=pcall(function()return httpService:JSONDecode(str)end)
    if success then return r else return nil end
end
local function tableEquals(t1,t2)
    if type(t1)~="table" or type(t2)~="table" then return t1==t2 end
    if tableSize(t1)~=tableSize(t2) then return false end
    for k,v in pairs(t1) do
        if not tableEquals(v,t2[k]) then return false end
    end
    return true
end
local function tableToString(t,indent)
    indent=indent or 0
    local spaces=string.rep(" ",indent*2)
    local r=spaces.."{\n"
    for k,v in pairs(t) do
        if type(v)=="table" then
            r=r..spaces.."  ["..tostring(k).."] = "..tableToString(v,indent+1)
        else
            r=r..spaces.."  ["..tostring(k).."] = "..tostring(v)..",\n"
        end
    end
    r=r..spaces.."}\n"
    return r
end
local function stringSplit(str,delimiter)
    local r={}
    if str=="" then return r end
    for part in string.gmatch(str,string.format("([^%s]+)",delimiter or " ")) do
        table.insert(r,part)
    end
    return r
end
local function stringJoin(arr,delimiter)
    delimiter=delimiter or ""
    local r=""
    for i,v in ipairs(arr) do
        if i>1 then r=r..delimiter end
        r=r..tostring(v)
    end
    return r
end
local function stringTrim(str)
    return string.gsub(str,"^%s*(.-)%s*$","%1")
end
local function stringStartsWith(str,prefix)
    return string.sub(str,1,string.len(prefix))==prefix
end
local function stringEndsWith(str,suffix)
    return string.sub(str,-string.len(suffix))==suffix
end
local function stringContains(str,sub)
    return string.find(str,sub)~=nil
end
local function stringReplace(str,from,to)
    return string.gsub(str,from,to)
end
local function stringToLower(str)
    return string.lower(str)
end
local function stringToUpper(str)
    return string.upper(str)
end
local function stringCapitalize(str)
    return string.upper(string.sub(str,1,1))..string.lower(string.sub(str,2))
end
local function stringReverse(str)
    local r=""
    for i=string.len(str),1,-1 do
        r=r..string.sub(str,i,i)
    end
    return r
end
local function stringPad(str,len,char,side)
    char=char or " "
    side=side or "left"
    local diff=len-string.len(str)
    if diff<=0 then return str end
    local pad=string.rep(char,diff)
    if side=="left" then return pad..str
    elseif side=="right" then return str..pad
    else return pad..str..pad end
end
local function stringIsEmpty(str)
    return stringTrim(str)==""
end
local function stringIsNumeric(str)
    return tonumber(str)~=nil
end
local function stringCount(str,sub)
    local count=0
    for _ in string.gmatch(str,sub) do count=count+1 end
    return count
end
local function stringBetween(str,start,finish)
    local s,e=string.find(str,start)
    if not s then return nil end
    local s2,e2=string.find(str,finish,e)
    if not s2 then return nil end
    return string.sub(str,e+1,s2-1)
end
local function stringToTable(str)
    local r={}
    for i=1,string.len(str) do
        table.insert(r,string.sub(str,i,i))
    end
    return r
end
local function stringFromTable(arr)
    return table.concat(arr)
end
local function stringHash(str)
    local hash=0
    for i=1,string.len(str) do
        hash=(hash*31+string.byte(str,i))%2^32
    end
    return hash
end
local function stringBase64Encode(str)
    local b64chars="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    local result=""
    for i=1,string.len(str),3 do
        local b1=string.byte(str,i)
        local b2=string.byte(str,i+1) or 0
        local b3=string.byte(str,i+2) or 0
        local n=(b1<<16)+(b2<<8)+b3
        result=result..string.sub(b64chars,(n>>18)&63+1,(n>>18)&63+1)
        result=result..string.sub(b64chars,(n>>12)&63+1,(n>>12)&63+1)
        result=result..(i+1<=string.len(str) and string.sub(b64chars,(n>>6)&63+1,(n>>6)&63+1) or "=")
        result=result..(i+2<=string.len(str) and string.sub(b64chars,n&63+1,n&63+1) or "=")
    end
    return result
end
local function stringBase64Decode(str)
    local b64chars="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    local result=""
    str=string.gsub(str,"=","")
    for i=1,string.len(str),4 do
        local c1=string.find(b64chars,string.sub(str,i,i))-1
        local c2=string.find(b64chars,string.sub(str,i+1,i+1))-1
        local c3=string.find(b64chars,string.sub(str,i+2,i+2))-1 or 0
        local c4=string.find(b64chars,string.sub(str,i+3,i+3))-1 or 0
        local n=(c1<<18)+(c2<<12)+(c3<<6)+c4
        result=result..string.char((n>>16)&255)
        if i+2<=string.len(str) then
            result=result..string.char((n>>8)&255)
        end
        if i+3<=string.len(str) then
            result=result..string.char(n&255)
        end
    end
    return result
end
local function stringUrlEncode(str)
    return string.gsub(str,"[^%w%-_%.~]","%1"..string.format("%%%02X",string.byte))
end
local function stringUrlDecode(str)
    return string.gsub(str, "%%(%x%x)", function(hex)
        return string.char(tonumber(hex,16))
    end)
end
local function mathClamp(val,min,max)
    return math.max(min,math.min(max,val))
end
local function mathLerp(a,b,t)
    return a+(b-a)*t
end
local function mathSmoothstep(a,b,t)
    t=mathClamp((t-a)/(b-a),0,1)
    return t*t*(3-2*t)
end
local function mathSmootherstep(a,b,t)
    t=mathClamp((t-a)/(b-a),0,1)
    return t*t*t*(t*(t*6-15)+10)
end
local function mathMap(val,inMin,inMax,outMin,outMax)
    return outMin+(outMax-outMin)*((val-inMin)/(inMax-inMin))
end
local function mathRandomRange(min,max)
    if type(min)=="number" and type(max)=="number" then
        return math.random()*(max-min)+min
    end
    return math.random()
end
local function mathRandomInt(min,max)
    return math.random(min,max)
end
local function mathRandomBool()
    return math.random()<0.5
end
local function mathRandomChoice(arr)
    if #arr==0 then return nil end
    return arr[math.random(1,#arr)]
end
local function mathRandomWeighted(weights)
    local total=0
    for _,w in pairs(weights) do total=total+w end
    local r=math.random()*total
    for k,w in pairs(weights) do
        r=r-w
        if r<=0 then return k end
    end
    return nil
end
local function mathDistance(pos1,pos2)
    if not pos1 or not pos2 then return math.huge end
    return (pos1-pos2).Magnitude
end
local function mathVectorLerp(v1,v2,t)
    return v1+(v2-v1)*t
end
local function mathVectorNormalize(v)
    local mag=v.Magnitude
    if mag==0 then return Vector3.new(0,0,0) end
    return v/mag
end
local function mathVectorAngle(v1,v2)
    local dot=v1:Dot(v2)
    local mag1=v1.Magnitude
    local mag2=v2.Magnitude
    if mag1==0 or mag2==0 then return 0 end
    return math.acos(mathClamp(dot/(mag1*mag2),-1,1))
end
local function mathVectorCross(v1,v2)
    return v1:Cross(v2)
end
local function mathVectorProject(v1,v2)
    local dot=v1:Dot(v2)
    local mag2=v2.Magnitude^2
    if mag2==0 then return Vector3.new(0,0,0) end
    return v2*(dot/mag2)
end
local function mathVectorReflect(v,normal)
    return v-normal*2*v:Dot(normal)
end
local function mathColorLerp(c1,c2,t)
    return Color3.new(
        mathLerp(c1.R,c2.R,t),
        mathLerp(c1.G,c2.G,t),
        mathLerp(c1.B,c2.B,t)
    )
end
local function mathColorHexToRGB(hex)
    hex=string.gsub(hex,"#","")
    local r=tonumber(string.sub(hex,1,2),16)
    local g=tonumber(string.sub(hex,3,4),16)
    local b=tonumber(string.sub(hex,5,6),16)
    return Color3.fromRGB(r,g,b)
end
local function mathColorRGBToHex(c)
    local r=math.floor(c.R*255)
    local g=math.floor(c.G*255)
    local b=math.floor(c.B*255)
    return string.format("#%02X%02X%02X",r,g,b)
end
local function mathColorHSVToRGB(h,s,v)
    h=h%360
    local c=v*s
    local x=c*(1-math.abs((h/60)%2-1))
    local m=v-c
    local r,g,b
    if h<60 then r=c g=x b=0
    elseif h<120 then r=x g=c b=0
    elseif h<180 then r=0 g=c b=x
    elseif h<240 then r=0 g=x b=c
    elseif h<300 then r=x g=0 b=c
    else r=c g=0 b=x end
    return Color3.fromRGB((r+m)*255,(g+m)*255,(b+m)*255)
end
local function mathColorRGBToHSV(c)
    local r=c.R g=c.G b=c.B
    local max=math.max(r,g,b)
    local min=math.min(r,g,b)
    local v=max
    local s=max==0 and 0 or (max-min)/max
    local h=0
    if max==min then h=0
    elseif max==r then h=(g-b)/(max-min)*60
    elseif max==g then h=(b-r)/(max-min)*60+120
    else h=(r-g)/(max-min)*60+240 end
    if h<0 then h=h+360 end
    return h,s,v
end
local function mathColorRandom()
    return Color3.fromRGB(math.random(0,255),math.random(0,255),math.random(0,255))
end
local function mathColorFromName(name)
    local colors={
        red=Color3.fromRGB(255,0,0),
        green=Color3.fromRGB(0,255,0),
        blue=Color3.fromRGB(0,0,255),
        yellow=Color3.fromRGB(255,255,0),
        cyan=Color3.fromRGB(0,255,255),
        magenta=Color3.fromRGB(255,0,255),
        white=Color3.fromRGB(255,255,255),
        black=Color3.fromRGB(0,0,0),
        gray=Color3.fromRGB(128,128,128),
        orange=Color3.fromRGB(255,128,0),
        purple=Color3.fromRGB(128,0,255),
        pink=Color3.fromRGB(255,0,128)
    }
    return colors[string.lower(name)] or Color3.fromRGB(255,255,255)
end
local function mathClampVector(v,min,max)
    return Vector3.new(
        mathClamp(v.X,min.X,max.X),
        mathClamp(v.Y,min.Y,max.Y),
        mathClamp(v.Z,min.Z,max.Z)
    )
end
local function mathAngleBetween(v1,v2)
    return math.acos(mathClamp(v1.Unit:Dot(v2.Unit),-1,1))
end
local function mathRotateVector(v,angle,axis)
    axis=axis or Vector3.new(0,1,0)
    local c=math.cos(angle)
    local s=math.sin(angle)
    local t=1-c
    local x=axis.X
    local y=axis.Y
    local z=axis.Z
    return Vector3.new(
        (t*x*x+c)*v.X+(t*x*y-s*z)*v.Y+(t*x*z+s*y)*v.Z,
        (t*x*y+s*z)*v.X+(t*y*y+c)*v.Y+(t*y*z-s*x)*v.Z,
        (t*x*z-s*y)*v.X+(t*y*z+s*x)*v.Y+(t*z*z+c)*v.Z
    )
end
local function mathIsVectorInRange(v1,v2,range)
    return (v1-v2).Magnitude<=range
end
local function mathSmoothDamp(current,target,velocity,smoothTime,maxSpeed,deltaTime)
    smoothTime=math.max(0.0001,smoothTime)
    local omega=2/smoothTime
    local x=omega*deltaTime
    local exp=1/(1+x+0.48*x*x+0.235*x*x*x)
    local change=current-target
    local maxChange=maxSpeed*smoothTime
    change=mathClamp(change,-maxChange,maxChange)
    local temp=(velocity+omega*change)*deltaTime
    velocity=(velocity-omega*temp)*exp
    local output=target+change+temp
    if (target-current)*(output-target)>0 then
        output=target
        velocity=0
    end
    return output,velocity
end
local function mathIsPowerOfTwo(n)
    return n>0 and (n&(n-1))==0
end
local function mathNextPowerOfTwo(n)
    n=n-1
    n=n|(n>>1)
    n=n|(n>>2)
    n=n|(n>>4)
    n=n|(n>>8)
    n=n|(n>>16)
    return n+1
end
local function mathBitCount(n)
    local count=0
    while n>0 do
        count=count+(n&1)
        n=n>>1
    end
    return count
end
local function mathIsPrime(n)
    if n<2 then return false end
    if n==2 then return true end
    if n%2==0 then return false end
    for i=3,math.sqrt(n),2 do
        if n%i==0 then return false end
    end
    return true
end
local function mathGCD(a,b)
    while b~=0 do
        a,b=b,a%b
    end
    return math.abs(a)
end
local function mathLCM(a,b)
    return math.abs(a*b)/mathGCD(a,b)
end
local function mathFactorial(n)
    if n<0 then return 0 end
    if n<=1 then return 1 end
    local r=1
    for i=2,n do r=r*i end
    return r
end
local function mathFibonacci(n)
    if n<=0 then return 0 end
    if n==1 then return 1 end
    local a,b=0,1
    for i=2,n do
        a,b=b,a+b
    end
    return b
end
local function mathBinomial(n,k)
    if k<0 or k>n then return 0 end
    if k==0 or k==n then return 1 end
    local r=1
    for i=1,k do
        r=r*(n-k+i)/i
    end
    return r
end
local Queue={}
function Queue.new()
    return {items={},head=1,tail=0}
end
function Queue:push(value)
    self.tail=self.tail+1
    self.items[self.tail]=value
end
function Queue:pop()
    if self:isEmpty() then return nil end
    local value=self.items[self.head]
    self.items[self.head]=nil
    self.head=self.head+1
    return value
end
function Queue:peek()
    if self:isEmpty() then return nil end
    return self.items[self.head]
end
function Queue:isEmpty()
    return self.head>self.tail
end
function Queue:size()
    return self.tail-self.head+1
end
function Queue:clear()
    self.items={}
    self.head=1
    self.tail=0
end
function Queue:toArray()
    local r={}
    for i=self.head,self.tail do
        table.insert(r,self.items[i])
    end
    return r
end
local Stack={}
function Stack.new()
    return {items={}}
end
function Stack:push(value)
    table.insert(self.items,value)
end
function Stack:pop()
    if self:isEmpty() then return nil end
    return table.remove(self.items)
end
function Stack:peek()
    if self:isEmpty() then return nil end
    return self.items[#self.items]
end
function Stack:isEmpty()
    return #self.items==0
end
function Stack:size()
    return #self.items
end
function Stack:clear()
    self.items={}
end
function Stack:toArray()
    return deepCopy(self.items)
end
local PriorityQueue={}
function PriorityQueue.new()
    return {items={},count=0}
end
function PriorityQueue:push(value,priority)
    priority=priority or 0
    self.count=self.count+1
    table.insert(self.items,{value=value,priority=priority,index=self.count})
    self:_siftUp(#self.items)
end
function PriorityQueue:pop()
    if self:isEmpty() then return nil end
    local top=self.items[1]
    local last=table.remove(self.items)
    if #self.items>0 then
        self.items[1]=last
        self:_siftDown(1)
    end
    return top.value
end
function PriorityQueue:peek()
    if self:isEmpty() then return nil end
    return self.items[1].value
end
function PriorityQueue:isEmpty()
    return #self.items==0
end
function PriorityQueue:size()
    return #self.items
end
function PriorityQueue:clear()
    self.items={}
    self.count=0
end
function PriorityQueue:_siftUp(i)
    while i>1 do
        local parent=math.floor(i/2)
        if self.items[parent].priority<=self.items[i].priority then break end
        self.items[parent],self.items[i]=self.items[i],self.items[parent]
        i=parent
    end
end
function PriorityQueue:_siftDown(i)
    local n=#self.items
    while true do
        local left=i*2
        local right=i*2+1
        local smallest=i
        if left<=n and self.items[left].priority<self.items[smallest].priority then smallest=left end
        if right<=n and self.items[right].priority<self.items[smallest].priority then smallest=right end
        if smallest==i then break end
        self.items[i],self.items[smallest]=self.items[smallest],self.items[i]
        i=smallest
    end
end
function PriorityQueue:toArray()
    local r={}
    for _,item in ipairs(self.items) do
        table.insert(r,{value=item.value,priority=item.priority})
    end
    return r
end
local Cache={}
function Cache.new(maxSize,ttl)
    maxSize=maxSize or 100
    ttl=ttl or 60
    return {items={},maxSize=maxSize,ttl=ttl,order={},timestamps={}}
end
function Cache:get(key)
    local item=self.items[key]
    if item then
        local timestamp=self.timestamps[key]
        if os.time()-timestamp>self.ttl then
            self:remove(key)
            return nil
        end
        for i,v in ipairs(self.order) do
            if v==key then
                table.remove(self.order,i)
                break
            end
        end
        table.insert(self.order,key)
        return item
    end
    return nil
end
function Cache:set(key,value)
    if self.items[key] then
        self:remove(key)
    end
    if #self.order>=self.maxSize then
        local oldest=self.order[1]
        self:remove(oldest)
    end
    self.items[key]=value
    self.timestamps[key]=os.time()
    table.insert(self.order,key)
end
function Cache:remove(key)
    self.items[key]=nil
    self.timestamps[key]=nil
    for i,v in ipairs(self.order) do
        if v==key then
            table.remove(self.order,i)
            break
        end
    end
end
function Cache:clear()
    self.items={}
    self.order={}
    self.timestamps={}
end
function Cache:size()
    return #self.order
end
function Cache:has(key)
    return self.items[key]~=nil
end
function Cache:keys()
    return deepCopy(self.order)
end
function Cache:values()
    local r={}
    for _,k in ipairs(self.order) do
        table.insert(r,self.items[k])
    end
    return r
end
function Cache:cleanup()
    local now=os.time()
    local toRemove={}
    for k,v in pairs(self.timestamps) do
        if now-v>self.ttl then
            table.insert(toRemove,k)
        end
    end
    for _,k in ipairs(toRemove) do
        self:remove(k)
    end
end
local LRU={}
function LRU.new(maxSize)
    maxSize=maxSize or 100
    return {items={},maxSize=maxSize,order={}}
end
function LRU:get(key)
    local item=self.items[key]
    if item then
        for i,v in ipairs(self.order) do
            if v==key then
                table.remove(self.order,i)
                break
            end
        end
        table.insert(self.order,key)
        return item
    end
    return nil
end
function LRU:set(key,value)
    if self.items[key] then
        for i,v in ipairs(self.order) do
            if v==key then
                table.remove(self.order,i)
                break
            end
        end
    end
    if #self.order>=self.maxSize then
        local oldest=self.order[1]
        self.items[oldest]=nil
        table.remove(self.order,1)
    end
    self.items[key]=value
    table.insert(self.order,key)
end
function LRU:remove(key)
    self.items[key]=nil
    for i,v in ipairs(self.order) do
        if v==key then
            table.remove(self.order,i)
            break
        end
    end
end
function LRU:clear()
    self.items={}
    self.order={}
end
function LRU:size()
    return #self.order
end
function LRU:has(key)
    return self.items[key]~=nil
end
function LRU:keys()
    return deepCopy(self.order)
end
function LRU:values()
    local r={}
    for _,k in ipairs(self.order) do
        table.insert(r,self.items[k])
    end
    return r
end
local Timer={}
function Timer.new(duration,autoStart)
    return {duration=duration,elapsed=0,started=autoStart or false,finished=false,paused=false}
end
function Timer:start()
    self.started=true
    self.elapsed=0
    self.finished=false
    self.paused=false
end
function Timer:stop()
    self.started=false
    self.paused=false
end
function Timer:pause()
    if self.started then self.paused=true end
end
function Timer:resume()
    if self.started then self.paused=false end
end
function Timer:update(delta)
    if not self.started or self.paused or self.finished then return end
    self.elapsed=self.elapsed+delta
    if self.elapsed>=self.duration then
        self.elapsed=self.duration
        self.finished=true
    end
end
function Timer:isFinished()
    return self.finished
end
function Timer:getProgress()
    return mathClamp(self.elapsed/self.duration,0,1)
end
function Timer:getRemaining()
    return math.max(0,self.duration-self.elapsed)
end
function Timer:reset()
    self.elapsed=0
    self.finished=false
end
local Stopwatch={}
function Stopwatch.new()
    return {startTime=0,running=false,elapsed=0}
end
function Stopwatch:start()
    self.startTime=tick()
    self.running=true
    self.elapsed=0
end
function Stopwatch:stop()
    if self.running then
        self.elapsed=self.elapsed+(tick()-self.startTime)
        self.running=false
    end
end
function Stopwatch:reset()
    self.startTime=0
    self.running=false
    self.elapsed=0
end
function Stopwatch:getElapsed()
    if self.running then
        return self.elapsed+(tick()-self.startTime)
    end
    return self.elapsed
end
function Stopwatch:isRunning()
    return self.running
end
local Debouncer={}
function Debouncer.new(delay)
    return {delay=delay,lastCall=0,timer=nil}
end
function Debouncer:call(func)
    if self.timer then
        self.timer:Disconnect()
        self.timer=nil
    end
    self.timer=runService.Heartbeat:Connect(function()
        if tick()-self.lastCall>=self.delay then
            self.timer:Disconnect()
            self.timer=nil
            func()
        end
    end)
    self.lastCall=tick()
end
function Debouncer:immediate(func)
    if self.timer then
        self.timer:Disconnect()
        self.timer=nil
    end
    func()
end
function Debouncer:cancel()
    if self.timer then
        self.timer:Disconnect()
        self.timer=nil
    end
end
local Throttler={}
function Throttler.new(delay)
    return {delay=delay,lastCall=0}
end
function Throttler:call(func)
    local now=tick()
    if now-self.lastCall>=self.delay then
        self.lastCall=now
        func()
        return true
    end
    return false
end
function Throttler:reset()
    self.lastCall=0
end
local Memoizer={}
function Memoizer.new(func)
    return {func=func,cache={}}
end
function Memoizer:call(key)
    if self.cache[key]~=nil then
        return self.cache[key]
    end
    local result=self.func(key)
    self.cache[key]=result
    return result
end
function Memoizer:clear()
    self.cache={}
end
function Memoizer:remove(key)
    self.cache[key]=nil
end
local Signal={}
function Signal.new()
    return {listeners={}}
end
function Signal:connect(func)
    table.insert(self.listeners,func)
    return function()
        for i,v in ipairs(self.listeners) do
            if v==func then
                table.remove(self.listeners,i)
                break
            end
        end
    end
end
function Signal:disconnectAll()
    self.listeners={}
end
function Signal:fire(...)
    local args={...}
    for _,func in ipairs(self.listeners) do
        task.spawn(function()pcall(func,unpack(args))end)
    end
end
function Signal:count()
    return #self.listeners
end
local Promise={}
function Promise.new(executor)
    local self={state="pending",result=nil,error=nil,thenCallbacks={},catchCallbacks={}}
    function resolve(value)
        if self.state=="pending" then
            self.state="resolved"
            self.result=value
            for _,cb in ipairs(self.thenCallbacks) do
                task.spawn(function()pcall(cb,value)end)
            end
        end
    end
    function reject(err)
        if self.state=="pending" then
            self.state="rejected"
            self.error=err
            for _,cb in ipairs(self.catchCallbacks) do
                task.spawn(function()pcall(cb,err)end)
            end
        end
    end
    local success,err=pcall(function()executor(resolve,reject)end)
    if not success then reject(err) end
    self.resolve=resolve
    self.reject=reject
    return self
end
function Promise:then(callback)
    if self.state=="resolved" then
        task.spawn(function()pcall(callback,self.result)end)
    elseif self.state=="pending" then
        table.insert(self.thenCallbacks,callback)
    end
    return self
end
function Promise:catch(callback)
    if self.state=="rejected" then
        task.spawn(function()pcall(callback,self.error)end)
    elseif self.state=="pending" then
        table.insert(self.catchCallbacks,callback)
    end
    return self
end
function Promise:finally(callback)
    if self.state=="pending" then
        self:then(callback)
        self:catch(callback)
    else
        task.spawn(callback)
    end
    return self
end
function Promise.all(promises)
    return Promise.new(function(resolve,reject)
        local results={}
        local completed=0
        for i,p in ipairs(promises) do
            p:then(function(value)
                results[i]=value
                completed=completed+1
                if completed==#promises then resolve(results) end
            end):catch(reject)
        end
    end)
end
function Promise.race(promises)
    return Promise.new(function(resolve,reject)
        for _,p in ipairs(promises) do
            p:then(resolve):catch(reject)
        end
    end)
end
function Promise.resolve(value)
    return Promise.new(function(resolve)resolve(value)end)
end
function Promise.reject(err)
    return Promise.new(function(_,reject)reject(err)end)
end
local Observer={}
function Observer.new()
    return {observers={},data={}}
end
function Observer:subscribe(key,callback)
    if not self.observers[key] then self.observers[key]={} end
    table.insert(self.observers[key],callback)
    return function()
        for i,v in ipairs(self.observers[key]) do
            if v==callback then
                table.remove(self.observers[key],i)
                break
            end
        end
    end
end
function Observer:set(key,value)
    self.data[key]=value
    if self.observers[key] then
        for _,cb in ipairs(self.observers[key]) do
            task.spawn(function()pcall(cb,value,key)end)
        end
    end
end
function Observer:get(key)
    return self.data[key]
end
function Observer:remove(key)
    self.data[key]=nil
    self.observers[key]=nil
end
function Observer:clear()
    self.data={}
    self.observers={}
end
local EventBus={}
function EventBus.new()
    return {events={}}
end
function EventBus:on(event,handler)
    if not self.events[event] then self.events[event]={} end
    table.insert(self.events[event],handler)
    return function()
        for i,v in ipairs(self.events[event]) do
            if v==handler then
                table.remove(self.events[event],i)
                break
            end
        end
    end
end
function EventBus:once(event,handler)
    local wrapper
    wrapper=function(...)
        handler(...)
        for i,v in ipairs(self.events[event]) do
            if v==wrapper then
                table.remove(self.events[event],i)
                break
            end
        end
    end
    return self:on(event,wrapper)
end
function EventBus:emit(event,...)
    local handlers=self.events[event]
    if handlers then
        local args={...}
        for _,handler in ipairs(handlers) do
            task.spawn(function()pcall(handler,unpack(args))end)
        end
    end
end
function EventBus:remove(event)
    self.events[event]=nil
end
function EventBus:clear()
    self.events={}
end
function EventBus:listEvents()
    local r={}
    for k,_ in pairs(self.events) do table.insert(r,k) end
    return r
end
function EventBus:count(event)
    if event then
        return #(self.events[event] or {})
    end
    local total=0
    for _,v in pairs(self.events) do total=total+#v end
    return total
end
local Pool={}
function Pool.new(createFunc,maxSize)
    return {create=createFunc,maxSize=maxSize or 10,pool={},active={}}
end
function Pool:acquire(...)
    local obj
    if #self.pool>0 then
        obj=table.remove(self.pool)
    else
        obj=self.create(...)
    end
    table.insert(self.active,obj)
    return obj
end
function Pool:release(obj)
    for i,v in ipairs(self.active) do
        if v==obj then
            table.remove(self.active,i)
            if #self.pool<self.maxSize then
                table.insert(self.pool,obj)
            end
            return true
        end
    end
    return false
end
function Pool:clear()
    self.pool={}
    self.active={}
end
function Pool:size()
    return #self.pool
end
function Pool:activeSize()
    return #self.active
end
function Pool:totalSize()
    return #self.pool+#self.active
end
function library.Initialize(data)
    dataRef=data
    return true
end
library.deepCopy=deepCopy
library.mergeTables=mergeTables
library.tableFilter=tableFilter
library.tableMap=tableMap
library.tableReduce=tableReduce
library.tableFind=tableFind
library.tableFindAll=tableFindAll
library.tableGroupBy=tableGroupBy
library.tableSort=tableSort
library.tableKeys=tableKeys
library.tableValues=tableValues
library.tableSize=tableSize
library.tableIsEmpty=tableIsEmpty
library.tableContains=tableContains
library.tableContainsKey=tableContainsKey
library.tableRemoveValue=tableRemoveValue
library.tableRemoveKey=tableRemoveKey
library.tableInsertUnique=tableInsertUnique
library.tableChunk=tableChunk
library.tableShuffle=tableShuffle
library.tableReverse=tableReverse
library.tableUnique=tableUnique
library.tableDifference=tableDifference
library.tableIntersection=tableIntersection
library.tableMerge=tableMerge
library.tableOverride=tableOverride
library.tableSerialize=tableSerialize
library.tableDeserialize=tableDeserialize
library.tableEquals=tableEquals
library.tableToString=tableToString
library.stringSplit=stringSplit
library.stringJoin=stringJoin
library.stringTrim=stringTrim
library.stringStartsWith=stringStartsWith
library.stringEndsWith=stringEndsWith
library.stringContains=stringContains
library.stringReplace=stringReplace
library.stringToLower=stringToLower
library.stringToUpper=stringToUpper
library.stringCapitalize=stringCapitalize
library.stringReverse=stringReverse
library.stringPad=stringPad
library.stringIsEmpty=stringIsEmpty
library.stringIsNumeric=stringIsNumeric
library.stringCount=stringCount
library.stringBetween=stringBetween
library.stringToTable=stringToTable
library.stringFromTable=stringFromTable
library.stringHash=stringHash
library.stringBase64Encode=stringBase64Encode
library.stringBase64Decode=stringBase64Decode
library.stringUrlEncode=stringUrlEncode
library.stringUrlDecode=stringUrlDecode
library.mathClamp=mathClamp
library.mathLerp=mathLerp
library.mathSmoothstep=mathSmoothstep
library.mathSmootherstep=mathSmootherstep
library.mathMap=mathMap
library.mathRandomRange=mathRandomRange
library.mathRandomInt=mathRandomInt
library.mathRandomBool=mathRandomBool
library.mathRandomChoice=mathRandomChoice
library.mathRandomWeighted=mathRandomWeighted
library.mathDistance=mathDistance
library.mathVectorLerp=mathVectorLerp
library.mathVectorNormalize=mathVectorNormalize
library.mathVectorAngle=mathVectorAngle
library.mathVectorCross=mathVectorCross
library.mathVectorProject=mathVectorProject
library.mathVectorReflect=mathVectorReflect
library.mathColorLerp=mathColorLerp
library.mathColorHexToRGB=mathColorHexToRGB
library.mathColorRGBToHex=mathColorRGBToHex
library.mathColorHSVToRGB=mathColorHSVToRGB
library.mathColorRGBToHSV=mathColorRGBToHSV
library.mathColorRandom=mathColorRandom
library.mathColorFromName=mathColorFromName
library.mathClampVector=mathClampVector
library.mathAngleBetween=mathAngleBetween
library.mathRotateVector=mathRotateVector
library.mathIsVectorInRange=mathIsVectorInRange
library.mathSmoothDamp=mathSmoothDamp
library.mathIsPowerOfTwo=mathIsPowerOfTwo
library.mathNextPowerOfTwo=mathNextPowerOfTwo
library.mathBitCount=mathBitCount
library.mathIsPrime=mathIsPrime
library.mathGCD=mathGCD
library.mathLCM=mathLCM
library.mathFactorial=mathFactorial
library.mathFibonacci=mathFibonacci
library.mathBinomial=mathBinomial
library.Queue=Queue
library.Stack=Stack
library.PriorityQueue=PriorityQueue
library.Cache=Cache
library.LRU=LRU
library.Timer=Timer
library.Stopwatch=Stopwatch
library.Debouncer=Debouncer
library.Throttler=Throttler
library.Memoizer=Memoizer
library.Signal=Signal
library.Promise=Promise
library.Observer=Observer
library.EventBus=EventBus
library.Pool=Pool
return library
