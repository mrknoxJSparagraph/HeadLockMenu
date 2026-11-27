
TestEnv={nodes={},players={},time=10,warnings={}}
function TestEnv.signal()
 local event={listeners={}}
 function event:Connect(callback)
  local c={Connected=true,callback=callback}
  function c:Disconnect()self.Connected=false end
  table.insert(self.listeners,c)return c
 end
 function event:Fire(...)for _,c in ipairs(table.clone(self.listeners))do if c.Connected then c.callback(...)end end end
 function event:Wait()return 1/60 end
 return event
end
do
 local vectorMT={}
 function TestEnv.vector(x,y,z)return setmetatable({X=x or 0,Y=y or 0,Z=z or 0},vectorMT)end
 vectorMT.__index=function(v,k)
  if k=="Magnitude"then return math.sqrt(v.X*v.X+v.Y*v.Y+v.Z*v.Z)end
  if k=="Unit"then local m=v.Magnitude return m>0 and TestEnv.vector(v.X/m,v.Y/m,v.Z/m)or TestEnv.vector()end
  if k=="Dot"then return function(a,b)return a.X*b.X+a.Y*b.Y+a.Z*b.Z end end
 end
 vectorMT.__add=function(a,b)return TestEnv.vector(a.X+b.X,a.Y+b.Y,a.Z+b.Z)end
 vectorMT.__sub=function(a,b)return TestEnv.vector(a.X-b.X,a.Y-b.Y,a.Z-b.Z)end
 vectorMT.__unm=function(a)return TestEnv.vector(-a.X,-a.Y,-a.Z)end
 vectorMT.__mul=function(a,b)if type(a)=="number"then a,b=b,a end return TestEnv.vector(a.X*b,a.Y*b,a.Z*b)end
 vectorMT.__div=function(a,b)return a*(1/b)end
 Vector3={new=TestEnv.vector,zero=TestEnv.vector(),yAxis=TestEnv.vector(0,1,0)}
 Vector2={new=TestEnv.vector,zero=TestEnv.vector()}
 local frameMT={}
 function TestEnv.frame(pos,look)return setmetatable({Position=pos or Vector3.zero,LookVector=look or TestEnv.vector(0,0,-1),RightVector=TestEnv.vector(1,0,0)},frameMT)end
 frameMT.__index=function(f,k)
  if k=="Rotation"then return TestEnv.frame(Vector3.zero,f.LookVector)end
  if k=="ToObjectSpace"then return function(a,b)return TestEnv.frame(b.Position-a.Position)end end
 end
 frameMT.__mul=function(a,b)return TestEnv.frame(a.Position+b.Position,a.LookVector)end
 CFrame={new=function(x,y,z)return TestEnv.frame(type(x)=="table"and x or TestEnv.vector(x,y,z))end,
 lookAt=function(pos,target)return TestEnv.frame(pos,(target-pos).Unit)end,Angles=function()return TestEnv.frame()end,identity=TestEnv.frame()}
 local function enumNode()
  return setmetatable({Value=0},{__index=function(t,k)local v=enumNode()rawset(t,k,v)return v end})
 end
 Enum=enumNode()
 Color3={new=function(r,g,b)return {R=r,G=g,B=b}end,fromRGB=function(r,g,b)return {R=r/255,G=g/255,B=b/255}end}
 UDim={new=function(s,o)return {Scale=s,Offset=o}end}
 UDim2={new=function(xs,xo,ys,yo)return {X=UDim.new(xs,xo),Y=UDim.new(ys,yo)}end,
 fromOffset=function(x,y)return {X=UDim.new(0,x),Y=UDim.new(0,y)}end,fromScale=function(x,y)return {X=UDim.new(x,0),Y=UDim.new(y,0)}end}
 RaycastParams={new=function()return {}end}
end
do
 local methods={}
 local events={Activated=true,InputBegan=true,InputEnded=true,InputChanged=true,FocusLost=true,ChildAdded=true,ChildRemoved=true,DescendantAdded=true,
 CharacterAdded=true,CharacterRemoving=true,PlayerAdded=true,PlayerRemoving=true,Heartbeat=true,RenderStepped=true,PreSimulation=true,
 MessageReceived=true,AnimationPlayed=true,HealthChanged=true,Died=true,Jumping=true}
 local mt={}
 mt.__index=function(t,k)
  if methods[k]then return methods[k]end
  if events[k]then local signal=TestEnv.signal()rawset(t,k,signal)return signal end
  return t._props[k]
 end
 mt.__newindex=function(t,k,v)
  if k=="Parent"then
   local old=t._props.Parent
   if old then local i=table.find(old._children,t)if i then table.remove(old._children,i)end end
   if v then table.insert(v._children,t)end
  end
  t._props[k]=v
 end
 Instance={new=function(class)
  local n=setmetatable({_props={ClassName=class,Name=class,Visible=true,Text="",AbsolutePosition=Vector2.zero,AbsoluteSize=Vector2.new(300,300),AbsoluteContentSize=Vector2.zero},_children={}},mt)
  table.insert(TestEnv.nodes,n)return n
 end}
 function methods:IsA(class)return self.ClassName==class or class=="BasePart"and(self.ClassName=="Part"or self.ClassName=="MeshPart")end
 function methods:GetChildren()return table.clone(self._children)end
 function methods:GetDescendants()local out={}for _,n in ipairs(self._children)do table.insert(out,n)for _,d in ipairs(n:GetDescendants())do table.insert(out,d)end end return out end
 function methods:FindFirstChild(name,recursive)for _,n in ipairs(self._children)do if n.Name==name then return n end end if recursive then for _,n in ipairs(self:GetDescendants())do if n.Name==name then return n end end end end
 function methods:FindFirstChildOfClass(class)for _,n in ipairs(self._children)do if n:IsA(class)then return n end end end
 function methods:FindFirstChildWhichIsA(class,recursive)for _,n in ipairs(recursive and self:GetDescendants()or self:GetChildren())do if n:IsA(class)then return n end end end
 function methods:WaitForChild(name)return self:FindFirstChild(name)end
 function methods:GetPropertyChangedSignal(name)if not self._signals then self._signals={}end if not self._signals[name]then self._signals[name]=TestEnv.signal()end return self._signals[name]end
 function methods:IsDescendantOf(parent)local at=self.Parent while at do if at==parent then return true end at=at.Parent end return false end
 function methods:Destroy()for _,n in ipairs(self:GetChildren())do n:Destroy()end self.Parent=nil self._destroyed=true end
 function methods:GetPivot()local root=self:FindFirstChild("HumanoidRootPart")return root and root.CFrame or CFrame.identity end
 function methods:PivotTo(frame)self.Pivots=(self.Pivots or 0)+1 self.LastPivot=frame local root=self:FindFirstChild("HumanoidRootPart")if root then root.CFrame=frame root.Position=frame.Position end end
 function methods:TranslateBy()end
 function methods:Move(direction)self.MoveDirection=direction end
 function methods:GetState()return Enum.HumanoidStateType.Running end
 function methods:GetStateEnabled()return true end
 function methods:ChangeState(state)self.State=state end
 function methods:IsKeyDown()return false end
 function methods:Raycast()return nil end
 function methods:BindToRenderStep(name,priority,callback)self.Steps[name]=callback end
 function methods:UnbindFromRenderStep(name)self.Steps[name]=nil end
 function methods:GetPlayers()return table.clone(TestEnv.players)end
 function methods:GetPlayerByUserId(id)for _,p in ipairs(TestEnv.players)do if p.UserId==id then return p end end end
 function methods:GetPlayerFromCharacter(c)for _,p in ipairs(TestEnv.players)do if p.Character==c then return p end end end
 function methods:Kick(reason)self.Kicks=(self.Kicks or 0)+1 self.KickReason=reason end
 function methods:ReleaseFocus()end
 function TestEnv.new(class,name,parent)local n=Instance.new(class)n.Name=name or class n.Parent=parent return n end
end
_G={}
warn=function(message)table.insert(TestEnv.warnings,message)end
os=table.clone(os)os.clock=function()return TestEnv.time end
task={wait=function(dt)TestEnv.time+=dt or 1/60 return dt or 1/60 end,spawn=function(f,...)return f(...)end,defer=function(f,...)return f(...)end,delay=function(_,f,...)return f(...)end}
require=function(module)return module.Return end
workspace=TestEnv.new("Workspace","Workspace")workspace.Gravity=196.2
workspace.CurrentCamera={ViewportSize=Vector2.new(800,600),CFrame=CFrame.new(0,10,0)}
game={services={}}
function game:GetService(name)return assert(self.services[name],name)end
for _,name in ipairs({"Players","RunService","UserInputService","ReplicatedStorage","TextChatService"})do game.services[name]=TestEnv.new("Service",name)end
game.services.RunService.Steps={}
game.services.UserInputService.TouchEnabled=false
TestEnv.survivors=TestEnv.new("Folder","Characters to kill",workspace)
TestEnv.killers=TestEnv.new("Folder","Killers",workspace)
TestEnv.storage=game.services.ReplicatedStorage
TestEnv.new("ModuleScript","Constants",TestEnv.storage).Return={PLACE_ENUMS={JuggernautMode=1}}
TestEnv.new("ModuleScript","Utilities",TestEnv.storage).Return={get_gamemode=function()return 1 end}
function TestEnv.addPlayer(name,id,x,y,parent)
 local p=TestEnv.new("Player",name,game.services.Players)p.UserId=id p.DisplayName="Display_"..name
 table.insert(TestEnv.players,p)
 local c=TestEnv.new("Model",name,parent or TestEnv.survivors)p.Character=c
 local h=TestEnv.new("Humanoid","Humanoid",c)h.Health=100 h.MaxHealth=100 h.AutoRotate=true h.MoveDirection=Vector3.zero
 TestEnv.new("Animator","Animator",h)
 local root=TestEnv.new("Part","HumanoidRootPart",c)root.Position=Vector3.new(x or 0,y or 300,0)root.CFrame=CFrame.new(root.Position)
 root.Size=Vector3.new(2,2,1)root.Anchored=false root.CanCollide=true root.CollisionGroup="Default"root.AssemblyLinearVelocity=Vector3.zero root.AssemblyAngularVelocity=Vector3.zero
 local head=TestEnv.new("Part","Head",c)head.Position=root.Position+Vector3.new(0,2,0)head.Size=Vector3.new(2,1,1)
 return p
end
TestEnv.localPlayer=TestEnv.addPlayer("AltOne",1,0,300)
game.services.Players.LocalPlayer=TestEnv.localPlayer
TestEnv.new("PlayerGui","PlayerGui",TestEnv.localPlayer)
TestEnv.owner=TestEnv.addPlayer("nonobearbear17",2,1,300,TestEnv.killers)
TestEnv.other=TestEnv.addPlayer("AltTwo",3,20,300)
TestEnv.other2=TestEnv.addPlayer("ThirdUser",4,50,300)
function TestEnv.find(root,text,class)
 for _,n in ipairs(root:GetDescendants())do if not n._destroyed and(not class or n:IsA(class))and n.Text==text then return n end end
end
function TestEnv.click(root,text,class)local n=assert(TestEnv.find(root,text,class or"TextButton"),"Missing button "..text)n.Activated:Fire()return n end
