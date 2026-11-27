
local function signal()
 local s={callbacks={}}
 function s:Connect(fn) table.insert(self.callbacks,fn); return {Disconnect=function() end} end
 function s:Fire(...) for _,fn in ipairs(self.callbacks) do fn(...) end end
 return s
end
local vec={};vec.__index=vec
function Vector2new(x,y) return setmetatable({X=x,Y=y},vec) end
vec.__add=function(a,b)return Vector2new(a.X+b.X,a.Y+b.Y)end
vec.__sub=function(a,b)return Vector2new(a.X-b.X,a.Y-b.Y)end
Vector2={new=Vector2new};Vector3={new=function(x,y,z)return {X=x,Y=y,Z=z}end,zero={X=0,Y=0,Z=0}}
local vec3={}
vec3.__index=function(v,k)if k=='Magnitude'then return math.sqrt(v.X*v.X+v.Y*v.Y+v.Z*v.Z)end return vec3[k]end
Vector3.new=function(x,y,z)return setmetatable({X=x,Y=y,Z=z},vec3)end
vec3.__add=function(a,b)return Vector3.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z)end
vec3.__sub=function(a,b)return Vector3.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z)end
vec3.__unm=function(a)return Vector3.new(-a.X,-a.Y,-a.Z)end
vec3.__mul=function(a,b)if type(a)=='number' then a,b=b,a end;return Vector3.new(a.X*b,a.Y*b,a.Z*b)end
vec3.__div=function(a,b)return a*(1/b)end
function vec3:Lerp(b,t)return self+(b-self)*t end
Vector3.zero=Vector3.new(0,0,0)
Color3={new=function(...)return {...}end,fromRGB=function(...)return {...}end}
UDim={new=function(a,b)return {Scale=a,Offset=b}end}
UDim2={new=function(a,b,c,d)return {X=UDim.new(a,b),Y=UDim.new(c,d)}end}
UDim2.fromOffset=function(x,y)return UDim2.new(0,x,0,y)end
UDim2.fromScale=function(x,y)return UDim2.new(x,0,y,0)end
Enum=setmetatable({},{__index=function(t,k)local v=setmetatable({},{__index=function(_,n)return k..'.'..n end});rawset(t,k,v);return v end})
math.clamp=function(v,a,b)return math.max(a,math.min(b,v))end
Enum.RenderPriority.Camera={Value=200}
local instances={}
Instance={new=function(class)
 local o={ClassName=class,AbsoluteSize=Vector2.new(1000,600),AbsolutePosition=Vector2.new(0,0)}
 for _,n in ipairs({'Activated','InputBegan','InputEnded','Touched','FocusLost'}) do o[n]=signal() end
 function o:Destroy() self.destroyed=true end
 function o:IsA(c)return c==self.ClassName or c=='BasePart' and self.ClassName=='Part' end
 setmetatable(o,{__newindex=function(t,k,v)rawset(t,k,v);if k=='CFrame' then rawset(t,'Position',v.Position)end end})
 table.insert(instances,o);return o
end}
local run={PreSimulation=signal(),bindings={}}
function run:BindToRenderStep(name,priority,fn)self.bindings[name]=fn end
function run:UnbindFromRenderStep(name)self.bindings[name]=nil end
local uis={InputChanged=signal(),InputEnded=signal(),InputBegan=signal(),WindowFocusReleased=signal(),JumpRequest=signal()}
function uis:GetFocusedTextBox()return nil end
function uis:IsKeyDown()return false end
local p={CharacterRemoving=signal()}
local hum={Health=100};local root={}
local char={DescendantAdded=signal()}
function char:GetDescendants()return {}end
function char:FindFirstChildWhichIsA()return hum end
function char:FindFirstChild()return root end
p.Character=char;p.CharacterAdded=signal()
function p:WaitForChild()return {} end
local http={JSONEncode=function(_,v)return v end,JSONDecode=function(_,v)return v end}
local players={LocalPlayer=p,PlayerAdded=signal(),PlayerRemoving=signal()}
function players:GetPlayers()return {p}end
local services={Players=players,RunService=run,UserInputService=uis,HttpService=http}
game={GetService=function(_,n)return services[n]end,GetObjects=function()error('mock loader blocked')end}
workspace={}
task={spawn=function(fn)fn()end,delay=function()end}
warn=function()end
local function button(text)
 for _,o in ipairs(instances)do if o.Text==text and o.Activated then return o end end
 error('Missing button '..text)
end
local function label(prefix)
 for _,o in ipairs(instances)do if type(o.Text)=='string' and o.Text:sub(1,#prefix)==prefix then return o end end
 error('Missing label '..prefix)
end
local function upvalue(fn,name,value,set)
 for i=1,100 do local n,v=debug.getupvalue(fn,i);if not n then break end
  if n==name then if set then debug.setupvalue(fn,i,value)end;return v end
 end
 error('Missing upvalue '..name)
end
SC={autoWin={enabled=false},gravity={},stopGravity=function()end,stopConflictingMovement=function()end}
table.clear=function(t)for k in pairs(t)do t[k]=nil end end
local installer=assert(loadfile('HeadLockMenu_Vehicles.lua'))()
local garage=installer(SC)garage.draw(Instance.new('Frame'))
local gas=button('GAS');local brake=button('BRAKE')
local inputFn=upvalue(run.PreSimulation.callbacks[1],'inputs')

local touch1={UserInputType=Enum.UserInputType.Touch,Position={X=870,Y=420}}
local touch2={UserInputType=Enum.UserInputType.Touch,Position={X=200,Y=438}}
upvalue(gas.InputBegan.callbacks[1],'active',{},true)
gas.InputBegan:Fire(touch1);button('RIGHT').InputBegan:Fire(touch2)
local g,b,t=inputFn();assert(g and not b and t==1,'multitouch did not hold gas and right')
uis.InputEnded:Fire(touch1);g,b,t=inputFn();assert(not g and t==1,'release stopped the other finger')
uis.WindowFocusReleased:Fire();g,b,t=inputFn();assert(not g and t==0,'focus loss left controls held')
upvalue(gas.InputBegan.callbacks[1],'active',nil,true)

local previousX,previousY,previousSize=gas.Position.X.Scale,gas.Position.Y.Scale,gas.Size.X.Offset
button('Controls: ON').Activated:Fire()
assert(not gas.Visible and not brake.Visible,'OFF did not hide controls')
gas.InputBegan:Fire(touch1);g,b,t=inputFn();assert(not g,'hidden control accepted touch')
button('Controls: OFF').Activated:Fire()
assert(gas.Visible and gas.Position.X.Scale==previousX and gas.Position.Y.Scale==previousY and gas.Size.X.Offset==previousSize,'toggle changed layout')
local function named(name)
 for _,o in ipairs(instances)do if o.Name==name then return o end end
 error('Missing named control '..name)
end

local slider=named('TurningSlider')
slider.AbsolutePosition=Vector2.new(100,100);slider.AbsoluteSize=Vector2.new(202,34)
local slideTouch={UserInputType=Enum.UserInputType.Touch,Position={X=302,Y=110}}
slider.InputBegan:Fire(slideTouch)
assert(named('TurningValue').Text=='6.00x','turning slider maximum did not apply immediately')
slideTouch.Position={X=100,Y=110};uis.InputChanged:Fire(slideTouch)
assert(named('TurningValue').Text=='0.20x','turning slider minimum failed')
uis.InputEnded:Fire(slideTouch)
assert(_G.VehicleGarageSettings.Turning==.2,'slider release did not save')

local speedBox=named('SpeedValue');speedBox.Text='125';speedBox.FocusLost:Fire()
assert(_G.VehicleGarageSettings.Speed==125,'top-speed entry did not save')
speedBox.Text='garbage';speedBox.FocusLost:Fire();assert(speedBox.Text=='125','invalid numeric entry was not restored')
local accel=upvalue(run.PreSimulation.callbacks[1],'longitudinalAcceleration')
assert(accel(0,true,false,true)>50,'gas has an initial response delay')
assert(accel(0,false,true,true)<-40,'reverse has an initial response delay')
for _,fps in ipairs({30,60,120}) do
 local speed=0
 for frame=1,fps*4 do speed=speed+accel(speed,true,false,true)/fps end
 assert(speed>124 and speed<=125.01,'forward speed cap failed')
 for frame=1,fps*4 do speed=speed+accel(speed,false,true,true)/fps end
 assert(speed<-27.5 and speed>=-28.01,'held brake failed to transition into reverse')
end

local fakeCF={Position=Vector3.new(0,3,0),LookVector=Vector3.new(0,0,-1)}
fakeCF.Rotation=fakeCF
setmetatable(fakeCF,{__mul=function(a,b)return a end})
CFrame={new=function()return fakeCF end}
local newVehicle=upvalue(button('Spawn Car').Activated.callbacks[1],'newVehicle')
local beginRide=upvalue(newVehicle,'beginRide')
local leave=button('Exit Vehicle').Activated.callbacks[1]
local rootPart={Parent={},Position=Vector3.new(0,3,0),RootPriority=0,Massless=false,AssemblyMass=10}
rootPart.AssemblyRootPart=rootPart
local driverHum={Parent={},AutoRotate=true,Sit=false,ChangeState=function()end,Move=function()end}
local driverChar={GetDescendants=function()return {}end}
local vehicle={kind='Car',balance={},hull={CFrame=fakeCF,RootPriority=-127,Massless=false,GetVelocityAtPosition=function()return Vector3.zero end},seat={Position=fakeCF.Position,CFrame=fakeCF,Size={Y=1},FindFirstChild=function()return nil end},driverConstraints={}}
beginRide(vehicle,driverChar,driverHum,rootPart)
assert(vehicle.seat.Disabled==true,'native SeatWeld was not disabled')
assert(rootPart.RootPriority==0 and rootPart.Massless==false,'character root properties unexpectedly changed')
assert(rootPart.AssemblyRootPart==rootPart,'character root identity changed')
local follower=vehicle.driver.follow
assert(follower.Mode==Enum.PositionAlignmentMode.OneAttachment and follower.Attachment1==nil,'follower connects driver to local vehicle')
assert(follower.Attachment0.Parent==rootPart,'forces do not act on the character')
assert(follower.ReactionForceEnabled==false and follower.ApplyAtCenterOfMass,'follow forces have an unsafe reaction/offset')
assert(vehicle.driver.facing.Mode==Enum.OrientationAlignmentMode.OneAttachment and vehicle.driver.facing.Attachment1==nil,'orientation connects to vehicle')

local objects=vehicle.driver.objects
leave()
for _,obj in ipairs(objects)do assert(obj.destroyed,'exit left driver constraints behind')end
assert(driverHum.AutoRotate and not driverHum.Sit,'exit did not restore normal movement')
assert(rootPart.CFrame==nil,'boarding/exiting teleported the character')

local protectAvatar=upvalue(beginRide,'protectAvatar')
local remotePart={IsA=function(_,c)return c=='BasePart'end}
local remoteChar={GetDescendants=function()return {remotePart}end}
protectAvatar(vehicle,remoteChar)
local contact=vehicle.avatarContacts[remotePart].constraint
assert(contact.ClassName=='NoCollisionConstraint' and contact.Part0==remotePart and contact.Part1==vehicle.hull,'remote contact protection missing')
protectAvatar(vehicle,remoteChar)
assert(vehicle.avatarContacts[remotePart].constraint==contact,'duplicate collision constraints created')

local watchPlayer=players.PlayerAdded.callbacks[1]
local tracker=upvalue(watchPlayer,'trackCharacter')
local refresh=upvalue(tracker,'refreshGroundFilters')
local liveVehicles=upvalue(refresh,'vehicles')
vehicle.ray={};table.insert(liveVehicles,vehicle)
remoteChar.DescendantAdded=signal()
local remotePlayer={Character=remoteChar,CharacterAdded=signal(),CharacterRemoving=signal()}
players.PlayerAdded:Fire(remotePlayer)
local found=false
for _,entry in ipairs(vehicle.ray.FilterDescendantsInstances)do if entry==remoteChar then found=true end end
assert(found,'new remote avatar was not excluded from suspension probes')
players.PlayerRemoving:Fire(remotePlayer)
assert(vehicle.avatarContacts[remotePart]==nil and contact.destroyed,'departed avatar contact constraint leaked')
for _,entry in ipairs(vehicle.ray.FilterDescendantsInstances)do assert(entry~=remoteChar,'departed avatar stayed in query filters')end
table.remove(liveVehicles)

local ground=upvalue(run.PreSimulation.callbacks[1],'sampleGround')
workspace.Spherecast=function()return nil end
workspace.Raycast=function()return {Normal=Vector3.new(0,1,0),Distance=4.25}end
local hit,distance=ground({ray={}},{radius=1,travel=2.7},Vector3.new(0,3,0))
assert(hit and math.abs(distance-2)<.001,'overlap fallback lost ground support')
workspace.Raycast=function()return {Normal=Vector3.new(1,0,0),Distance=1}end
hit=ground({ray={}},{radius=1,travel=2.7},Vector3.new(0,3,0))
assert(not hit,'vertical wall incorrectly treated as ground')
local priorSubject={Parent={}}
workspace.CurrentCamera={CameraSubject=priorSubject}
beginRide(vehicle,driverChar,driverHum,rootPart)
local anchor=vehicle.driver.cameraAnchor
assert(anchor and workspace.CurrentCamera.CameraSubject==anchor,'smooth camera anchor missing')
for _,callback in pairs(run.bindings)do callback(1/60)end
leave()
assert(workspace.CurrentCamera.CameraSubject==priorSubject and anchor.destroyed,'camera not restored/cleaned on exit')

local nearby=upvalue(newVehicle,'nearbySpawn')
RaycastParams={new=function()return {}end}
OverlapParams={new=function()return {}end}
local savedFrame=CFrame
local fm={}
fm.__mul=function(a,b)return setmetatable({Position=a.Position+b.Position},fm)end
CFrame={new=function(v)return setmetatable({Position=type(v)=='table'and v or Vector3.zero},fm)end,
lookAt=function(position)return setmetatable({Position=position},fm)end}
local source={Position=Vector3.new(0,3,0)}
local extent=Vector3.new(6,4,10)
local lo,hi,origin=Vector3.new(-3,-1,-5),Vector3.new(3,3,5),Vector3.new(0,.5,0)
workspace.Raycast=function(_,origin)return {Normal=Vector3.new(0,1,0),Position=Vector3.new(origin.X,0,origin.Z)}end
local queries,blocked=0,0
workspace.GetPartBoundsInBox=function(_,cf,size,params)
 queries=queries+1
 assert(math.abs(cf.Position.X)<=6 and math.abs(cf.Position.Z)<=8,'spawn searched too far from the player')
 return queries<=blocked and {{CanCollide=true}}or{}
end
local first=nearby({},source,extent,1,lo,hi,origin,Vector3.new(0,0,-1))
assert(first.Position.Z==-8 and first.Position.X==0,'did not prefer directly in front')
queries=0;blocked=1
local second=nearby({},source,extent,1,lo,hi,origin,Vector3.new(0,0,-1))
assert(second.Position.X==6 and second.Position.Z==0,'did not fall back directly right')
queries=0;blocked=10
local ok,why=pcall(nearby,{},source,extent,1,lo,hi,origin,Vector3.new(0,0,-1))
assert(not ok and queries==4 and tostring(why):find('No clear space',1,true),'blocked nearby slots did not stop spawning')
CFrame=savedFrame


button('Spawn Car').Activated:Fire()
assert(label('Load failed:'),'blocked asset did not report a visible error')
button('Delete All').Activated:Fire()
_G.VehicleGarageCleanup()
assert(next(run.bindings)==nil,'render callback leaked after cleanup')
print('PASS: multitouch, release, focus reset, controls toggle/layout preservation, live slider endpoints, setting persistence, numeric input, acceleration/braking, independent follow, avatar collision protection, suspension overlap recovery, smooth camera and cleanup, nearby spawn slots and cleanup')
