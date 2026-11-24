-- SAKTK hosted build 20261124-sounds: complete source, no clipboard packing.
-- HeadLockMenu - complete standalone script. Paste the entire file.
local __boot={}
pcall(function()
local p=game:GetService("Players").LocalPlayer
local pg=p and p:FindFirstChildOfClass("PlayerGui")
if not pg then return end
local previous=pg:FindFirstChild("HeadLockStartup")if previous then previous:Destroy()end
local screen=Instance.new("ScreenGui")screen.Name="HeadLockStartup"screen.ResetOnSpawn=false screen.IgnoreGuiInset=true screen.DisplayOrder=10001 screen.Parent=pg __boot.gui=screen
local camera=workspace.CurrentCamera local view=camera and camera.ViewportSize or Vector2.new(800,600)
local box=Instance.new("TextLabel")box.AnchorPoint=Vector2.new(0.5,0.5)box.Position=UDim2.fromScale(0.5,0.5)
box.Size=UDim2.fromOffset(math.min(400,view.X-24),math.min(180,view.Y-24))box.BackgroundColor3=Color3.new(0,0,0)box.BorderSizePixel=0
box.TextColor3=Color3.new(1,1,1)box.Font=Enum.Font.Code box.TextSize=14 box.TextWrapped=true box.Text="Starting menu..."box.Parent=screen __boot.message=box
local outline=Instance.new("UIStroke")outline.Color=Color3.new(1,1,1)outline.Thickness=1 outline.Parent=box
end)
local function __run()
local PASSWORD="boat"local SC={paused=false,originals={},mainWasVisible=true,ownerFeatures=false,cFlyNotice="",combatYLimit=506.5,}local Players=game:GetService("Players")local RS=game:GetService("RunService")
local UIS=game:GetService("UserInputService")local player=Players.LocalPlayer local playerGui=player:WaitForChild("PlayerGui")local RENDER_NAME="HeadLockMenuCamera"local BLACK=Color3.new(0,0,0)
local WHITE=Color3.new(1,1,1)local RED=Color3.fromRGB(255,0,0)local GREEN=Color3.fromRGB(0,255,0)local FLY_RENDER_NAME="HeadLockMenuCFly"if _G.HeadLockMenuCleanup then
local previousCleanup=_G.HeadLockMenuCleanup _G.HeadLockMenuCleanup=nil local cleaned,cleanupError=pcall(previousCleanup)
if not cleaned then warn("HeadLockMenu prior cleanup: "..tostring(cleanupError))end end warn("HeadLockMenu: loading")local connections={}local gui function SC.isOwnerAccount(account)
if not account then return false end local name=string.lower(account.Name)if name=="nonobearbear"or name=="bluddyblud17"then return true end local number=name:match("^nonobearbear(%d+)$")
local index=number and tonumber(number)return index~=nil and index>=1 and index<=100 and number==tostring(index)end
function SC.canSelectPlayer(target)return target~=nil and target~=player and target.Parent==Players and not SC.isOwnerAccount(target)end
 SC.selectedPlayer=nil  SC.enabled=false  SC.aimPart="Head" SC.locked=false
 SC.listOpen=false  SC.speedEnabled=false  SC.tpSpeed=0  SC.trackEnabled=false  SC.trackPlayer=nil  SC.trackListOpen=false  SC.followEnabled=false  SC.followPlayer=nil
 SC.followListOpen=false local teleportState={target=nil,refresh=nil,update=nil}local autoTrack={mode=nil,lockedPlayer=nil,lockedCharacter=nil,lockedHumanoid=nil,deathConnection=nil,excluded={},
nextScan=0,}
          SC.espEnabled=false local espRecords={} SC.activeGame="SAKTK" SC.gunEspEnabled=false local gunEspRecords={}
SC.gunGrab={busy=false,list=nil,status=nil} SC.cFlyEnabled=false  SC.cFlySpeed=45 local cFlyRoot=nil local cFlyAnchored=nil local cFlyCollisions={} SC.cFlyUpHeld=false  SC.cFlyDownHeld=false
 SC.cFlyCameraMobile=false local updateCFlyPanel=nil SC.cFlyFollowJug=false local juggernautPlayer=nil SC.fling={active=false,status=nil}SC.juggernautAutoKill={
enabled=false,target=nil,status=nil,nextScan=0,} SC.rapidFireEnabled=false  SC.rapidFirePower=100 local rapidWeapon=nil local originalWeaponFire=nil local wrappedWeaponFire=nil
local rapidFlamethrower=nil local originalFlamethrowerFire=nil local wrappedFlamethrowerFire=nil  SC.noOverheatEnabled=false  SC.rapidReloadEnabled=false  SC.rapidReloadPower=100
local reloadWeapon=nil local originalWeaponReload=nil local wrappedWeaponReload=nil  SC.infiniteAmmoEnabled=false  SC.noRecoilEnabled=false local recoilHooks={} SC.noSpreadEnabled=false
local spreadHooks={} local trackHumanoid=nil local oldAutoRotate=nil
local trackAttachment=nil local trackOrientation=nil local trackJumpHumanoid=nil local trackJumpConnection=nil local trackTargetRoot=nil
local trackTargetY=nil local trackTargetRising=false local followContactRoot=nil local followContactHeld=false local lastTrackJump=0 local TRACK_RENDER_NAME="HeadLockMenuTrack"
function SC.rapidFireMax()return SC.ownerFeatures and SC.isOwnerAccount(player)and 1000 or 200 end
function SC.setOwnerFeatures(value)SC.ownerFeatures=value==true and SC.isOwnerAccount(player)SC.rapidFirePower=math.clamp(SC.rapidFirePower,0,SC.rapidFireMax())end
autoTrack.clearLock=function()if autoTrack.deathConnection then autoTrack.deathConnection:Disconnect()autoTrack.deathConnection=nil end autoTrack.lockedPlayer=nil autoTrack.lockedCharacter=nil
autoTrack.lockedHumanoid=nil end autoTrack.stop=function()autoTrack.mode=nil autoTrack.clearLock()table.clear(autoTrack.excluded)end local function mirrorTrackJump()
if SC.followEnabled and followContactHeld then return end if os.clock()-lastTrackJump<0.35 then return end local character=player.Character
local humanoid=character and character:FindFirstChildOfClass("Humanoid")local root=character and character:FindFirstChild("HumanoidRootPart")
if not humanoid or not root or root.Anchored or humanoid.Health<=0 or humanoid.Sit or not humanoid:GetStateEnabled(Enum.HumanoidStateType.Jumping)then return end local state=humanoid:GetState()
if state==Enum.HumanoidStateType.Jumping or state==Enum.HumanoidStateType.Freefall then return end lastTrackJump=os.clock()humanoid.Jump=true humanoid:ChangeState(Enum.HumanoidStateType.Jumping)end
local function restoreTrackRotation()followContactRoot=nil followContactHeld=false if trackJumpConnection then trackJumpConnection:Disconnect()trackJumpConnection=nil end trackJumpHumanoid=nil
trackTargetRoot=nil trackTargetY=nil trackTargetRising=false if trackOrientation then trackOrientation:Destroy()trackOrientation=nil end if trackAttachment then trackAttachment:Destroy()
trackAttachment=nil end if trackHumanoid and trackHumanoid.Parent then trackHumanoid.AutoRotate=oldAutoRotate trackHumanoid:Move(Vector3.zero,false)end trackHumanoid=nil oldAutoRotate=nil end
local function connect(signal,callback)local connection=signal:Connect(callback)table.insert(connections,connection)return connection end local function startHitbox(size)if _G.HeadLockHitboxChoice then return end
_G.HeadLockHitboxChoice=size _G.HeadSize=size _G.Disabled=false _G.HeadLockHitboxTarget=juggernautPlayer _G.HeadLockHitboxConnection=RS.RenderStepped:Connect(function()if _G.Disabled then return end
for _,target in ipairs(Players:GetPlayers())do if target~=player and target==_G.HeadLockHitboxTarget and not _G.HeadLockAllHitboxChoice then local character=target.Character
local hrp=character and character:FindFirstChild("HumanoidRootPart")if hrp then if not SC.originals[hrp]then SC.originals[hrp]={Size=hrp.Size,Transparency=hrp.Transparency,CanCollide=hrp.CanCollide,}
end hrp.Size=Vector3.new(_G.HeadSize,_G.HeadSize,_G.HeadSize)hrp.Transparency=1 hrp.CanCollide=false end end end end)end local function startAllHitbox(size)if _G.HeadLockAllHitboxChoice then return
end _G.HeadLockAllHitboxChoice=size _G.AllHeadSize=size _G.AllDisabled=false _G.HeadLockAllHitboxConnection=RS.RenderStepped:Connect(function()if _G.AllDisabled then return end
for _,target in ipairs(Players:GetPlayers())do if target~=player then local character=target.Character local hrp=character and character:FindFirstChild("HumanoidRootPart")if hrp then
if not SC.originals[hrp]then SC.originals[hrp]={Size=hrp.Size,Transparency=hrp.Transparency,CanCollide=hrp.CanCollide,}end hrp.Size=Vector3.new(_G.AllHeadSize,_G.AllHeadSize,_G.AllHeadSize)
hrp.Transparency=1 hrp.CanCollide=false end end end end)end function SC.restoreHitboxes()_G.Disabled=true _G.AllDisabled=true for part,original in pairs(SC.originals)do if part.Parent then
part.Size=original.Size part.Transparency=original.Transparency part.CanCollide=original.CanCollide end SC.originals[part]=nil end
for _,key in ipairs({"HeadLockHitboxConnection","HeadLockAllHitboxConnection"})do local connection=_G[key]if connection then connection:Disconnect()_G[key]=nil end end _G.HeadLockHitboxChoice=nil
_G.HeadLockAllHitboxChoice=nil _G.HeadLockHitboxTarget=nil end local function removeRapidFire()SC.rapidFireEnabled=false SC.noOverheatEnabled=false
if rapidWeapon and rapidWeapon.fire==wrappedWeaponFire then rapidWeapon.fire=originalWeaponFire end if rapidFlamethrower and rapidFlamethrower.fire==wrappedFlamethrowerFire then
rapidFlamethrower.fire=originalFlamethrowerFire end rapidWeapon=nil originalWeaponFire=nil wrappedWeaponFire=nil rapidFlamethrower=nil originalFlamethrowerFire=nil wrappedFlamethrowerFire=nil end
local function refillIfEnabled(weapon)if SC.infiniteAmmoEnabled and weapon.instance and not weapon.stolen and type(weapon.refill)=="function"then weapon:refill()end end
local function clearFlamethrowerHeat(weapon,refreshGui)if SC.noOverheatEnabled and weapon.instance and not weapon.stolen then weapon.heat=0 if refreshGui and type(weapon.update_ammo_gui)=="function"then
weapon:update_ammo_gui()end end end local function rapidFireInterval(weapon,countFireAnimation)SC.rapidFirePower=math.clamp(SC.rapidFirePower,0,SC.rapidFireMax())local animationDuration=0
local fireAnimation=countFireAnimation and weapon.animations and weapon.animations.Fire if fireAnimation then for _,step in ipairs(fireAnimation)do if type(step)=="number"and step>0 then
animationDuration+=step end end end local normalInterval=math.max(weapon.shoot_wait or 0.1,0.03)+animationDuration if SC.rapidFirePower<=100 then
return normalInterval+(0.03-normalInterval)*SC.rapidFirePower/100 end return 0.03/(1+(SC.rapidFirePower-100)/100)end local function ensureFlamethrowerHook(weaponModule)if rapidFlamethrower then return true
end local flameScript=game:GetService("ReplicatedStorage"):WaitForChild("Weapon"):FindFirstChild("Flamethrower")if not flameScript then return false end local ok,flameModule=pcall(require,flameScript)
if not ok or type(flameModule)~="table"or type(flameModule.fire)~="function"or flameModule.fire==weaponModule.fire then return false end rapidFlamethrower=flameModule
originalFlamethrowerFire=flameModule.fire wrappedFlamethrowerFire=function(self,...)refillIfEnabled(self)clearFlamethrowerHeat(self)if not SC.rapidFireEnabled or SC.rapidFirePower==0 then
local results=table.pack(pcall(originalFlamethrowerFire,self,...))clearFlamethrowerHeat(self,true)if not results[1]then error(results[2],0)end return table.unpack(results,2,results.n)end
local previousWait=self.fire_wait local previousDelay=self.shoot_wait local interval=rapidFireInterval(self,false)self.shoot_wait=interval self.fire_wait=function()return task.wait(interval)end
local results=table.pack(pcall(originalFlamethrowerFire,self,...))self.fire_wait=previousWait self.shoot_wait=previousDelay refillIfEnabled(self)clearFlamethrowerHeat(self,true)if not results[1]then
error(results[2],0)end return table.unpack(results,2,results.n)end flameModule.fire=wrappedFlamethrowerFire return true end local function ensureFireHook()if rapidWeapon then
ensureFlamethrowerHook(rapidWeapon)return true end local ok,weaponModule=pcall(function()return require(game:GetService("ReplicatedStorage"):WaitForChild("Weapon",5))end)
if not ok or type(weaponModule)~="table"or type(weaponModule.fire)~="function"then return false end rapidWeapon=weaponModule originalWeaponFire=weaponModule.fire wrappedWeaponFire=function(self,...)
refillIfEnabled(self)if not SC.rapidFireEnabled then local results=table.pack(originalWeaponFire(self,...))refillIfEnabled(self)return table.unpack(results,1,results.n)end if SC.rapidFirePower==0 then
local results=table.pack(originalWeaponFire(self,...))refillIfEnabled(self)return table.unpack(results,1,results.n)end local previousWait=self.fire_wait local previousDelay=self.shoot_wait
local previousAnimation=self.play_animation local interval=rapidFireInterval(self,true)if self.ammo and self.ammo<=0 then task.wait(interval)end self.shoot_wait=interval self.fire_wait=function()
return task.wait(interval)end self.play_animation=function(weapon,name,...)if name=="Bolt"and weapon.bolt_fire and weapon.instance and(weapon.instance.Name=="AWP"or weapon.instance.Name=="R870"
or weapon.instance.Name=="PAPAWP"or weapon.instance.Name=="PAPR870")then if not weapon.playing_animations.Bolt then task.spawn(function()local ok=pcall(previousAnimation,weapon,name)if not ok then
weapon.playing_animations.Bolt=nil end end)end return end if name=="Fire"then if not weapon.playing_animations.Fire then task.spawn(function()local ok=pcall(previousAnimation,weapon,name)
if not ok then weapon.playing_animations.Fire=nil end end)end return end return previousAnimation(weapon,name,...)end local results=table.pack(pcall(originalWeaponFire,self,...))
self.fire_wait=previousWait self.shoot_wait=previousDelay self.play_animation=previousAnimation refillIfEnabled(self)if not results[1]then error(results[2],0)end
return table.unpack(results,2,results.n)end weaponModule.fire=wrappedWeaponFire ensureFlamethrowerHook(weaponModule)return true end local function removeRapidReload()SC.rapidReloadEnabled=false
if reloadWeapon and reloadWeapon.reload==wrappedWeaponReload then reloadWeapon.reload=originalWeaponReload end reloadWeapon=nil originalWeaponReload=nil wrappedWeaponReload=nil end
local function ensureReloadHook()if reloadWeapon then return true end local ok,weaponModule=pcall(function()return require(game:GetService("ReplicatedStorage"):WaitForChild("Weapon",5))end)
if not ok or type(weaponModule)~="table"or type(weaponModule.reload)~="function"then return false end reloadWeapon=weaponModule originalWeaponReload=weaponModule.reload
wrappedWeaponReload=function(self,...)if SC.infiniteAmmoEnabled and self.instance and not self.stolen then refillIfEnabled(self)return end
if not SC.rapidReloadEnabled or SC.rapidReloadPower==0 or self._rapidReloadActive then return originalWeaponReload(self,...)end local duration=0 for _,name in ipairs({"Reload","Bolt"})do
if name=="Reload"or self.ammo==0 then local animation=self.animations and self.animations[name]if animation then for _,step in ipairs(animation)do if type(step)=="number"and step>0 then duration+=step
end end end end end local target=duration+(0.1-duration)*SC.rapidReloadPower/100 local scale=duration>0 and math.min(1,target/duration)or 1 local previousWait=self.reload_wait local waited=false
self._rapidReloadActive=true self.reload_wait=function(delay)if target<duration and target<=0.25 then if not waited then waited=true return task.wait(target)end return end
return task.wait(type(delay)=="number"and math.max(0,delay*scale)or 0)end local results=table.pack(pcall(originalWeaponReload,self,...))self.reload_wait=previousWait self._rapidReloadActive=nil
if not results[1]then error(results[2],0)end return table.unpack(results,2,results.n)end weaponModule.reload=wrappedWeaponReload return true end local function removeNoRecoil()SC.noRecoilEnabled=false
for _,hook in ipairs(recoilHooks)do if hook.module[hook.name]==hook.wrapper then hook.module[hook.name]=hook.original end end table.clear(recoilHooks)end local function ensureNoRecoilHook()
local definitions=game:GetService("ReplicatedStorage"):FindFirstChild("Weapon")if not definitions then return false end local ok,base=pcall(require,definitions)
if not ok or type(base)~="table"or type(base.recoil_camera)~="function"then return false end local function hookMethod(module,name)local original=rawget(module,name)
if type(original)~="function"then return end local wrapper=function(self,...)if SC.noRecoilEnabled then return end return original(self,...)end module[name]=wrapper table.insert(recoilHooks,{
module=module,name=name,original=original,wrapper=wrapper,})end for _,name in ipairs({"recoil_camera","move_camera","shake_cam"})do hookMethod(base,name)end
for _,child in ipairs(definitions:GetChildren())do if child:IsA("ModuleScript")then local loaded,subclass=pcall(require,child)if loaded and type(subclass)=="table"and subclass~=base then
for _,name in ipairs({"recoil_camera","move_camera","shake_cam"})do hookMethod(subclass,name)end end end end return true end local function removeNoSpread()SC.noSpreadEnabled=false
for _,hook in ipairs(spreadHooks)do if hook.module.compute_inaccuracy==hook.wrapper then hook.module.compute_inaccuracy=hook.original end end table.clear(spreadHooks)end
local function ensureNoSpreadHook()local definitions=game:GetService("ReplicatedStorage"):FindFirstChild("Weapon")if not definitions then return false end local ok,base=pcall(require,definitions)
if not ok or type(base)~="table"or type(base.compute_inaccuracy)~="function"then return false end local function hookModule(module)local original=rawget(module,"compute_inaccuracy")
if type(original)~="function"then return end local wrapper=function(self,...)if SC.noSpreadEnabled then return 0 end return original(self,...)end module.compute_inaccuracy=wrapper
table.insert(spreadHooks,{module=module,original=original,wrapper=wrapper})end hookModule(base)for _,child in ipairs(definitions:GetChildren())do if child:IsA("ModuleScript")then
local loaded,subclass=pcall(require,child)if loaded and type(subclass)=="table"and subclass~=base then hookModule(subclass)end end end return true end local function make(className,properties,parent)
local object=Instance.new(className)for key,value in pairs(properties)do object[key]=value end object.Parent=parent return object end local function textButton(label,parent,color)
local button=make("TextButton",{BackgroundColor3=color or BLACK,BorderSizePixel=0,Text=label,TextColor3=color==WHITE and BLACK or WHITE,TextSize=15,Font=Enum.Font.Code,AutoButtonColor=false,},parent)
make("UIStroke",{Color=WHITE,Thickness=1,ApplyStrokeMode=Enum.ApplyStrokeMode.Border,LineJoinMode=Enum.LineJoinMode.Miter,},button)return button end local function clearEspVisual(record)
for _,key in ipairs({"healthConnection","maxHealthConnection","diedConnection","childConnection","removedConnection"})do if record[key]then record[key]:Disconnect()record[key]=nil end end
if record.highlight then record.highlight:Destroy()record.highlight=nil end if record.billboard then record.billboard:Destroy()record.billboard=nil end record.label=nil record.healthLabel=nil
record.visualCharacter=nil end local refreshEsp refreshEsp=function(record)clearEspVisual(record)if not SC.espEnabled then return end local character=record.player.Character if not character then return
end record.visualCharacter=character local head=character:FindFirstChild("Head")local root=character:FindFirstChild("HumanoidRootPart")local humanoid=character:FindFirstChildOfClass("Humanoid")
local anchor=head or root or character:FindFirstChild("UpperTorso")or character:FindFirstChild("Torso")if not anchor or not humanoid then
record.childConnection=character.ChildAdded:Connect(function(child)if child.Name=="Head"or child.Name=="HumanoidRootPart"or child.Name=="UpperTorso"or child.Name=="Torso"or child:IsA("Humanoid")then
refreshEsp(record)end end)return end record.childConnection=character.ChildAdded:Connect(function(child)if child.Name=="Head"and anchor~=head then refreshEsp(record)end end)
record.removedConnection=character.ChildRemoved:Connect(function(child)if child==anchor or child==humanoid then refreshEsp(record)end end)record.highlight=make("Highlight",{Adornee=character,
DepthMode=Enum.HighlightDepthMode.AlwaysOnTop,FillTransparency=1,OutlineColor=record.player==juggernautPlayer and RED or WHITE,OutlineTransparency=0,},character)record.billboard=make("BillboardGui",{
Adornee=anchor,AlwaysOnTop=true,ResetOnSpawn=false,Size=UDim2.fromOffset(120,28),StudsOffsetWorldSpace=Vector3.new(0,anchor==head and 5 or 6.5,0),},playerGui)local background=make("Frame",{
Size=UDim2.fromScale(1,1),BackgroundColor3=BLACK,BackgroundTransparency=0.35,BorderSizePixel=0,},record.billboard)local label=make("TextLabel",{Position=UDim2.fromOffset(2,1),
Size=UDim2.new(1,-4,0,13),BackgroundTransparency=1,BorderSizePixel=0,TextColor3=record.player==juggernautPlayer and RED or WHITE,TextSize=10,Font=Enum.Font.Code,TextTruncate=Enum.TextTruncate.AtEnd,
},background)label.Text=record.player.Name local healthLabel=make("TextLabel",{Position=UDim2.fromOffset(2,14),Size=UDim2.new(1,-4,0,13),BackgroundTransparency=1,BorderSizePixel=0,
TextColor3=label.TextColor3,TextSize=10,TextScaled=true,Font=Enum.Font.Code,},background)make("UITextSizeConstraint",{MinTextSize=8,MaxTextSize=10,},healthLabel)record.label=label
record.healthLabel=healthLabel local function updateHealth()healthLabel.Text=math.ceil(math.max(0,humanoid.Health)).."/"..math.ceil(humanoid.MaxHealth)end
record.healthConnection=humanoid.HealthChanged:Connect(updateHealth)record.maxHealthConnection=humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(updateHealth)
record.diedConnection=humanoid.Died:Connect(updateHealth)updateHealth()end local function addEspPlayer(target)if target==player or espRecords[target]then return end local record={player=target}
espRecords[target]=record record.characterConnection=target.CharacterAdded:Connect(function()refreshEsp(record)end)record.removingConnection=target.CharacterRemoving:Connect(function(character)
if record.visualCharacter==character then clearEspVisual(record)end end)refreshEsp(record)end local function removeEspPlayer(target)local record=espRecords[target]if not record then return end
clearEspVisual(record)record.characterConnection:Disconnect()record.removingConnection:Disconnect()espRecords[target]=nil end local function removeGunEsp(gun)local record=gunEspRecords[gun]
if not record then return end if record.highlight then record.highlight:Destroy()end if record.billboard then record.billboard:Destroy()end gunEspRecords[gun]=nil if SC.scheduleGunList then
SC.scheduleGunList()end end local function updateGunEsp(record)local slots=0 local remaining=0 for _,child in ipairs(record.gun:GetChildren())do
if child:IsA("Model")and child.Name==record.gun.Name then slots+=1 for _,part in ipairs(child:GetDescendants())do if part:IsA("BasePart")and part.Transparency<0.99
and part.LocalTransparencyModifier<0.99 then remaining+=1 break end end end end if slots>0 then record.usesModels=true elseif not record.usesModels then slots=1 remaining=1 end
record.total=math.max(record.total,slots)if not record.prompt.Enabled then remaining=0 end record.highlight.Enabled=remaining>0 record.billboard.Enabled=remaining>0
record.label.Text=string.format("%s\n%d/%d",record.gun.Name,remaining,record.total)if record.remaining~=remaining or record.listTotal~=record.total then record.remaining=remaining
record.listTotal=record.total if SC.scheduleGunList then SC.scheduleGunList()end end end local function addGunFromPrompt(prompt)if not SC.gunEspEnabled or not prompt:IsA("ProximityPrompt")then return end
local definitions=game:GetService("ReplicatedStorage"):FindFirstChild("Weapon")if not definitions then return end local current=prompt.Parent while current and current~=workspace do
if current:IsA("Model")or current:IsA("Tool")then local name=current.Name local definition=definitions:FindFirstChild(name)if not definition and name:sub(1,3)=="PAP"then
definition=definitions:FindFirstChild(name:sub(4))end if definition and definition:IsA("ModuleScript")then local gun=current if gunEspRecords[gun]then return end local anchor=prompt.Parent
if not anchor:IsA("BasePart")then anchor=gun:FindFirstChildWhichIsA("BasePart",true)end if not anchor then return end local highlight=make("Highlight",{Adornee=gun,
DepthMode=Enum.HighlightDepthMode.AlwaysOnTop,FillTransparency=1,OutlineColor=GREEN,OutlineTransparency=0,},gun)local billboard=make("BillboardGui",{Adornee=anchor,AlwaysOnTop=true,
Size=UDim2.fromOffset(135,34),StudsOffsetWorldSpace=Vector3.new(0,2.5,0),},playerGui)local label=make("TextLabel",{Size=UDim2.fromScale(1,1),BackgroundColor3=BLACK,BackgroundTransparency=0.35,
BorderSizePixel=0,Text="",TextColor3=GREEN,TextSize=12,Font=Enum.Font.Code,TextTruncate=Enum.TextTruncate.AtEnd,},billboard)local record={gun=gun,highlight=highlight,billboard=billboard,
anchor=anchor,prompt=prompt,label=label,total=0,}gunEspRecords[gun]=record updateGunEsp(record)return end end current=current.Parent end end local function refreshGunEsp()if SC.gunEspEnabled then
for _,descendant in ipairs(workspace:GetDescendants())do if descendant:IsA("ProximityPrompt")then addGunFromPrompt(descendant)end end else for gun in pairs(table.clone(gunEspRecords))do
removeGunEsp(gun)end end end function SC.grabGun(record)
local state=SC.gunGrab
if state.busy or not SC.gunEspEnabled or not record or record.remaining==0 or gunEspRecords[record.gun]~=record then return end
local character=player.Character
local humanoid=character and character:FindFirstChildOfClass("Humanoid")
local root=character and character:FindFirstChild("HumanoidRootPart")
if not humanoid or not root or humanoid.Health<=0 or not record.gun.Parent then
if state.status and state.status.Parent then state.status.Text="Character or gun unavailable" end
return
end
local hitbox=record.gun:FindFirstChild("Hitbox",true)
if not hitbox or not hitbox:IsA("BasePart") or not hitbox:FindFirstChild("TouchInterest") then
hitbox=nil
for _,part in ipairs(record.gun:GetDescendants()) do
if part:IsA("BasePart") and part:FindFirstChild("TouchInterest") then hitbox=part break end
end
end
if not hitbox then
if state.status and state.status.Parent then state.status.Text="No pickup TouchInterest found" end
return
end
if type(firetouchinterest)~="function" then
if state.status and state.status.Parent then state.status.Text="Executor has no firetouchinterest" end
return
end
local function ownedCount()
local count=0
local backpack=player:FindFirstChildOfClass("Backpack")
for _,container in ipairs({character,backpack}) do
if container then
for _,item in ipairs(container:GetChildren()) do
if item:IsA("Tool") and item.Name==record.gun.Name then count+=1 end
end
end
end
return count
end
state.busy=true
if state.status and state.status.Parent then state.status.Text="Grabbing "..record.gun.Name.."..." end
SC.updateGunList()
local before=record.remaining
local ownedBefore=ownedCount()
local ok,reason=pcall(function()
firetouchinterest(root,hitbox,0)
firetouchinterest(root,hitbox,1)
end)
local confirmed=false
if ok then
local deadline=os.clock()+1.5
repeat
if record.gun.Parent and record.label.Parent then updateGunEsp(record) end
confirmed=ownedCount()>ownedBefore or record.remaining<before
if confirmed then break end
task.wait(0.05)
until os.clock()>=deadline or player.Character~=character or humanoid.Health<=0
end
state.busy=false
if state.status and state.status.Parent then
state.status.Text=confirmed and ("Pickup detected: "..record.gun.Name)
or (ok and ("Touch sent; pickup not confirmed: "..record.gun.Name)
or (record.gun.Name..": "..tostring(reason)))
end
SC.updateGunList()
end
function SC.updateGunList()
local state=SC.gunGrab local list=state.list if not list or not list.Parent then return end for _,child in ipairs(list:GetChildren())do if child:IsA("Frame")then child:Destroy()end end
if not SC.gunEspEnabled then return end local available={}for gun,record in pairs(gunEspRecords)do if record.remaining and record.remaining>0 and gun:IsDescendantOf(workspace)then
table.insert(available,record)end end table.sort(available,function(a,b)return a.gun.Name<b.gun.Name end)for index,record in ipairs(available)do local row=make("Frame",{Size=UDim2.new(1,-5,0,34),
LayoutOrder=index,BackgroundTransparency=1,},list)make("TextLabel",{Size=UDim2.new(1,-74,1,0),BackgroundTransparency=1,Text=string.format("%s  %d/%d",record.gun.Name,record.remaining,record.total),
TextColor3=GREEN,TextSize=13,TextTruncate=Enum.TextTruncate.AtEnd,TextXAlignment=Enum.TextXAlignment.Left,Font=Enum.Font.Code,},row)local button=textButton(state.busy and"..."or"Grab",row)
button.Position=UDim2.new(1,-70,0,1)button.Size=UDim2.fromOffset(68,30)button.TextSize=12 button.Active=not state.busy button.Activated:Connect(function()task.spawn(SC.grabGun,record)end)end
list.CanvasSize=UDim2.fromOffset(0,#available*39+5)end function SC.scheduleGunList()local state=SC.gunGrab if state.pending then return end state.pending=true task.defer(function()state.pending=false
SC.updateGunList()end)end gui=make("ScreenGui",{Name="HeadLockMenu",DisplayOrder=10000,ResetOnSpawn=false,IgnoreGuiInset=true,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,},playerGui)local cFlyUpButton=textButton("UP",gui)
cFlyUpButton.Position=UDim2.new(0,18,0.58,0)cFlyUpButton.Size=UDim2.fromOffset(62,42)cFlyUpButton.Visible=false local cFlyDownButton=textButton("DOWN",gui)
cFlyDownButton.Position=UDim2.new(0,18,0.58,48)cFlyDownButton.Size=UDim2.fromOffset(62,42)cFlyDownButton.Visible=false local cFlyUpInput local cFlyDownInput
connect(cFlyUpButton.InputBegan,function(input)if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then cFlyUpInput=input SC.cFlyUpHeld=true end end)
connect(cFlyDownButton.InputBegan,function(input)if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then cFlyDownInput=input SC.cFlyDownHeld=true end
end)connect(UIS.InputEnded,function(input)if input==cFlyUpInput then cFlyUpInput=nil SC.cFlyUpHeld=false end if input==cFlyDownInput then cFlyDownInput=nil SC.cFlyDownHeld=false end end)
local function updateCFlyMobileButtons()local show=SC.cFlyEnabled and UIS.TouchEnabled and not SC.cFlyCameraMobile cFlyUpButton.Visible=show cFlyDownButton.Visible=show if not show then SC.cFlyUpHeld=false
SC.cFlyDownHeld=false cFlyUpInput=nil cFlyDownInput=nil end end local function stopCFly()SC.cFlyEnabled=false SC.cFlyFollowJug=false RS:UnbindFromRenderStep(FLY_RENDER_NAME)SC.cFlyUpHeld=false
SC.cFlyDownHeld=false cFlyUpInput=nil cFlyDownInput=nil cFlyUpButton.Visible=false cFlyDownButton.Visible=false if cFlyRoot and cFlyRoot.Parent then cFlyRoot.Anchored=cFlyAnchored
cFlyRoot.AssemblyLinearVelocity=Vector3.zero end for part,canCollide in pairs(cFlyCollisions)do if part.Parent then part.CanCollide=canCollide end end table.clear(cFlyCollisions)cFlyRoot=nil
cFlyAnchored=nil if updateCFlyPanel then updateCFlyPanel()end end local function startCFly()local character=player.Character local root=character and character:FindFirstChild("HumanoidRootPart")
local humanoid=character and character:FindFirstChildOfClass("Humanoid")if not root or not humanoid or humanoid.Health<=0 then return false end cFlyRoot=root cFlyAnchored=root.Anchored
SC.cFlyEnabled=true SC.cFlyNotice=""SC.speedEnabled=false SC.trackEnabled=false SC.followEnabled=false autoTrack.stop()restoreTrackRotation()for _,part in ipairs(character:GetDescendants())do if part:IsA("BasePart")then
cFlyCollisions[part]=part.CanCollide part.CanCollide=false end end root.Anchored=true root.AssemblyLinearVelocity=Vector3.zero updateCFlyMobileButtons()
RS:BindToRenderStep(FLY_RENDER_NAME,Enum.RenderPriority.Character.Value+2,function(dt)if not SC.cFlyEnabled or player.Character~=character or not root.Parent or humanoid.Health<=0 then stopCFly()return
end if SC.cFlyFollowJug then local target=juggernautPlayer local model=target and target.Character local targetHumanoid=model and model:FindFirstChildOfClass("Humanoid")
local targetRoot=model and model:FindFirstChild("HumanoidRootPart")if SC.isOwnerAccount(target)then SC.cFlyFollowJug=false SC.cFlyNotice="nuh uh you cant kill me"if updateCFlyPanel then updateCFlyPanel()end
elseif target~=player and model and model.Parent==workspace:FindFirstChild("Killers")
and targetHumanoid and targetHumanoid.Health>0 and targetRoot then character:PivotTo(targetRoot.CFrame)return
else SC.cFlyFollowJug=false SC.cFlyNotice=""if updateCFlyPanel then updateCFlyPanel()end end end
local camera=workspace.CurrentCamera if not camera then return end local look=camera.CFrame.LookVector local forward=Vector3.new(look.X,0,look.Z)if forward.Magnitude<0.01 then
forward=Vector3.new(0,0,-1)else forward=forward.Unit end local right=Vector3.new(forward.Z*-1,0,forward.X)local motion=Vector3.zero if UIS.TouchEnabled then motion=humanoid.MoveDirection
if SC.cFlyCameraMobile then local forwardAmount=motion:Dot(forward)local sideAmount=motion:Dot(right)motion=look*forwardAmount+right*sideAmount end else
if UIS:IsKeyDown(Enum.KeyCode.W)then motion=motion+forward end if UIS:IsKeyDown(Enum.KeyCode.S)then motion=motion-forward end if UIS:IsKeyDown(Enum.KeyCode.D)then motion=motion+right end
if UIS:IsKeyDown(Enum.KeyCode.A)then motion=motion-right end end local vertical=0 if not(UIS.TouchEnabled and SC.cFlyCameraMobile)then if SC.cFlyUpHeld or UIS:IsKeyDown(Enum.KeyCode.Space)then
vertical=vertical+1 end if SC.cFlyDownHeld or UIS:IsKeyDown(Enum.KeyCode.LeftControl)then vertical=vertical-1 end end motion=motion+Vector3.new(0,vertical,0)if motion.Magnitude>0 then
local destination=root.Position+motion.Unit*SC.cFlySpeed*math.min(dt,0.05)character:PivotTo(CFrame.lookAt(destination,destination+forward))end end)return true end connect(player.CharacterAdded,function()
if SC.cFlyEnabled then stopCFly()end end)local viewport=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(800,600)local width=math.min(560,viewport.X-24)
local height=math.min(390,viewport.Y-64)local sideWidth=math.floor(math.min(155,width*0.32))local main=make("Frame",{Name="MainMenu",Size=UDim2.fromOffset(width,height),
Position=UDim2.fromOffset(math.floor((viewport.X-width)/2),math.floor((viewport.Y-height)/2)),BackgroundColor3=BLACK,BorderSizePixel=0,Visible=false,},gui)
make("UIStroke",{Color=WHITE,Thickness=1,LineJoinMode=Enum.LineJoinMode.Miter},main)local titleBar=make("Frame",{Size=UDim2.new(1,0,0,42),BackgroundColor3=BLACK,BorderSizePixel=0,},main)
local title=make("TextLabel",{Size=UDim2.new(1,-20,1,0),Position=UDim2.fromOffset(12,0),BackgroundTransparency=1,Text="SAKTK",TextColor3=WHITE,TextSize=16,Font=Enum.Font.Code,
TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,},titleBar)local juggernautMode local function updateJuggernaut()if juggernautMode==nil then
local storage=game:GetService("ReplicatedStorage")local constantsModule=storage:FindFirstChild("Constants")local utilitiesModule=storage:FindFirstChild("Utilities")
if constantsModule and utilitiesModule and not SC.modeScanBusy then SC.modeScanBusy=true task.defer(function()
local ok,result=pcall(function()local constants=require(constantsModule)local utilities=require(utilitiesModule)
return utilities:get_gamemode(true)==constants.PLACE_ENUMS.JuggernautMode end)
if ok then juggernautMode=result end SC.modeScanBusy=false end)end end if not juggernautMode then title.Text="SAKTK"if not juggernautPlayer then return end juggernautPlayer=nil else local killers=workspace:FindFirstChild("Killers")local juggernaut if killers then
for _,target in ipairs(Players:GetPlayers())do local character=target.Character local humanoid=character and character:FindFirstChildOfClass("Humanoid")
if character and character.Parent==killers and humanoid and humanoid.Health>0 then juggernaut=target break end end end title.Text="SAKTK"if juggernautPlayer==juggernaut then return end juggernautPlayer=juggernaut end
for target,record in pairs(espRecords)do local color=target==juggernautPlayer and RED or WHITE if record.highlight then record.highlight.OutlineColor=color end if record.label then
record.label.TextColor3=color end if record.healthLabel then record.healthLabel.TextColor3=color end end end SC.juggernautTimer=0 connect(RS.Heartbeat,function(dt)SC.juggernautTimer+=dt
if SC.juggernautTimer>=0.4 then SC.juggernautTimer=0 updateJuggernaut()_G.HeadLockHitboxTarget=juggernautPlayer end end)updateJuggernaut()_G.HeadLockHitboxTarget=juggernautPlayer make("Frame",{
Position=UDim2.new(0,0,1,-1),Size=UDim2.new(1,0,0,1),BackgroundColor3=WHITE,BorderSizePixel=0,},titleBar)local categories=make("ScrollingFrame",{Name="Categories",Position=UDim2.fromOffset(8,49),
Size=UDim2.new(0,sideWidth-16,1,-57),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollingDirection=Enum.ScrollingDirection.Y,CanvasSize=UDim2.fromOffset(0,0),},main)
local categoryLayout=make("UIListLayout",{Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder,},categories)connect(categoryLayout:GetPropertyChangedSignal("AbsoluteContentSize"),function()
categories.CanvasSize=UDim2.fromOffset(0,categoryLayout.AbsoluteContentSize.Y+4)end)make("Frame",{Position=UDim2.fromOffset(sideWidth,46),Size=UDim2.new(0,1,1,-54),BorderSizePixel=0,
BackgroundColor3=WHITE,},main)local content=make("Frame",{Name="CategoryContent",Position=UDim2.fromOffset(sideWidth+10,49),Size=UDim2.new(1,-sideWidth-18,1,-57),BackgroundTransparency=1,},main)
local updateAimbot local updatePlayers local updateTrack local updateTrackPlayers local updateFollow local updateFollowPlayers
autoTrack.showTarget=function(target)if autoTrack.mode=="Leather"then SC.trackPlayer=target if updateTrack then updateTrack()end
if updateTrackPlayers then updateTrackPlayers()end elseif autoTrack.mode=="Tracking"then SC.followPlayer=target if updateFollow then updateFollow()end if updateFollowPlayers then updateFollowPlayers()end
end end autoTrack.lockTarget=function(target)autoTrack.clearLock()if not SC.canSelectPlayer(target)then autoTrack.showTarget(nil)return end local character=target.Character
local humanoid=character and character:FindFirstChildOfClass("Humanoid")if not humanoid or humanoid.Health<=0 then autoTrack.excluded[target]=true autoTrack.showTarget(nil)return end
autoTrack.lockedPlayer=target autoTrack.lockedCharacter=character autoTrack.lockedHumanoid=humanoid autoTrack.deathConnection=humanoid.Died:Connect(function()autoTrack.excluded[target]=true
autoTrack.clearLock()if autoTrack.mode then autoTrack.showTarget(nil)autoTrack.nextScan=0 end end)autoTrack.showTarget(target)end autoTrack.service=function(now)local mode=autoTrack.mode
if not mode then return end if(mode=="Leather"and not SC.trackEnabled)or(mode=="Tracking"and not SC.followEnabled)then autoTrack.stop()return end if autoTrack.lockedPlayer then
if SC.canSelectPlayer(autoTrack.lockedPlayer)and autoTrack.lockedPlayer.Character==autoTrack.lockedCharacter and autoTrack.lockedHumanoid.Parent==autoTrack.lockedCharacter
and autoTrack.lockedHumanoid.Health>0 then return end autoTrack.excluded[autoTrack.lockedPlayer]=true autoTrack.lockTarget(nil)autoTrack.nextScan=0 end if now<autoTrack.nextScan then return end
autoTrack.nextScan=now+0.15 local character=player.Character local root=character and character:FindFirstChild("HumanoidRootPart")if not root then return end local nearest,nearestDistance
for _,candidate in ipairs(Players:GetPlayers())do if SC.canSelectPlayer(candidate)and not autoTrack.excluded[candidate]then local other=candidate.Character
local otherHumanoid=other and other:FindFirstChildOfClass("Humanoid")local otherRoot=other and other:FindFirstChild("HumanoidRootPart")if otherHumanoid and otherRoot then
if otherHumanoid.Health<=0 then autoTrack.excluded[candidate]=true else local distance=(otherRoot.Position-root.Position).Magnitude if not nearestDistance or distance<nearestDistance then
nearest,nearestDistance=candidate,distance end end end end end if nearest then autoTrack.lockTarget(nearest)end end local categoryButtons={}local categoryEntries={}local selectedCategories={}local categoryConnections={}
local function addCategory(name,draw,section)section=section or"SAKTK"local button=textButton(name,categories)button.Size=UDim2.new(1,-5,0,39)button.TextXAlignment=Enum.TextXAlignment.Left
button.Text="  "..name button.Visible=section==SC.activeGame table.insert(categoryButtons,button)table.insert(categoryEntries,{button=button,section=section})local function selectCategory()
selectedCategories[section]=selectCategory for _,oldButton in ipairs(categoryButtons)do oldButton.BackgroundColor3=BLACK oldButton.TextColor3=WHITE end button.BackgroundColor3=WHITE
button.TextColor3=BLACK SC.updateSpeedPanel=nil if SC.sounds then SC.sounds.update=nil end if SC.spectate then SC.spectate.update=nil end if SC.anti then SC.anti.update=nil end updateAimbot=nil updatePlayers=nil updateTrack=nil updateTrackPlayers=nil updateFollow=nil updateFollowPlayers=nil teleportState.refresh=nil teleportState.update=nil
        for _,connection in ipairs(categoryConnections)do connection:Disconnect()end table.clear(categoryConnections)
for _,child in ipairs(content:GetChildren())do child:Destroy()end draw(content)end connect(button.Activated,selectCategory)return selectCategory end
SC.selectAimbot=addCategory("Aimbot",function(panel)make("TextLabel",{Size=UDim2.new(1,0,0,30),BackgroundTransparency=1,Text="Aimbot",TextColor3=WHITE,TextSize=20,Font=Enum.Font.Code,
TextXAlignment=Enum.TextXAlignment.Left,},panel)local toggle=textButton("OFF",panel)toggle.Position=UDim2.fromOffset(0,38)toggle.Size=UDim2.fromOffset(105,40)local eye=make("Frame",{
Position=UDim2.fromOffset(118,50),Size=UDim2.fromOffset(18,18),BackgroundTransparency=1,},panel)local eyeOutline=make("UIStroke",{Color=WHITE,Thickness=1,LineJoinMode=Enum.LineJoinMode.Miter,},eye)
local pupil=make("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(6,6),BackgroundColor3=BLACK,BorderSizePixel=0,},eye)
local headButton=textButton("Head",panel)headButton.Position=UDim2.fromOffset(0,85)headButton.Size=UDim2.new(0.5,-3,0,32)local torsoButton=textButton("Torso",panel)
torsoButton.Position=UDim2.new(0.5,3,0,85)torsoButton.Size=UDim2.new(0.5,-3,0,32)local selection=make("TextLabel",{Position=UDim2.fromOffset(0,124),Size=UDim2.new(1,0,0,26),BackgroundTransparency=1,
Text="Target: None",TextColor3=WHITE,TextSize=13,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,},panel)
local namesButton=textButton("Names...  ▾",panel)namesButton.Position=UDim2.fromOffset(0,154)namesButton.Size=UDim2.new(1,0,0,39)local namesList=make("ScrollingFrame",{
Position=UDim2.fromOffset(0,199),Size=UDim2.new(1,0,1,-202),BackgroundColor3=BLACK,BorderSizePixel=0,ScrollBarThickness=4,CanvasSize=UDim2.fromOffset(0,0),Visible=SC.listOpen,},panel)
local listLayout=make("UIListLayout",{Padding=UDim.new(0,3),SortOrder=Enum.SortOrder.Name,},namesList)listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
namesList.CanvasSize=UDim2.fromOffset(0,listLayout.AbsoluteContentSize.Y+4)end)updateAimbot=function()toggle.Text=SC.enabled and"ON"or"OFF"toggle.BackgroundColor3=SC.enabled and WHITE or BLACK
toggle.TextColor3=SC.enabled and BLACK or WHITE eyeOutline.Color=WHITE pupil.BackgroundColor3=SC.enabled and WHITE or BLACK headButton.BackgroundColor3=SC.aimPart=="Head"and WHITE or BLACK
headButton.TextColor3=SC.aimPart=="Head"and BLACK or WHITE torsoButton.BackgroundColor3=SC.aimPart=="Torso"and WHITE or BLACK torsoButton.TextColor3=SC.aimPart=="Torso"and BLACK or WHITE
selection.Text="Target: "..(SC.selectedPlayer and SC.selectedPlayer.Name or"None")namesButton.Text=SC.listOpen and"Players (close)"or"Players"namesList.Visible=SC.listOpen end updatePlayers=function()
for _,child in ipairs(namesList:GetChildren())do if child:IsA("TextButton")then child:Destroy()end end local allPlayers=Players:GetPlayers()table.sort(allPlayers,function(a,b)
return a.Name:lower()<b.Name:lower()end)for _,target in ipairs(allPlayers)do if SC.canSelectPlayer(target)then local row=textButton(target.Name,namesList)row.Name=target.Name row.Size=UDim2.new(1,-7,0,36)
row.TextXAlignment=Enum.TextXAlignment.Left row.Text="  "..target.Name row.BackgroundColor3=target==SC.selectedPlayer and WHITE or BLACK row.TextColor3=target==SC.selectedPlayer and BLACK or WHITE
row.Activated:Connect(function()if not SC.canSelectPlayer(target)then return end SC.selectedPlayer=target updateAimbot()updatePlayers()end)end end end toggle.Activated:Connect(function()SC.enabled=not SC.enabled if SC.enabled and not SC.selectedPlayer then
SC.listOpen=true end updateAimbot()end)headButton.Activated:Connect(function()SC.aimPart="Head"updateAimbot()end)torsoButton.Activated:Connect(function()SC.aimPart="Torso"updateAimbot()end)
namesButton.Activated:Connect(function()SC.listOpen=not SC.listOpen updateAimbot()end)updatePlayers()updateAimbot()end)addCategory("Speed",function(panel)make("TextLabel",{Size=UDim2.new(1,0,0,30),
BackgroundTransparency=1,Text="Speed",TextColor3=WHITE,TextSize=20,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,},panel)local toggle=textButton("OFF",panel)
toggle.Position=UDim2.fromOffset(0,38)toggle.Size=UDim2.fromOffset(105,40)make("TextLabel",{Position=UDim2.fromOffset(0,87),Size=UDim2.new(1,0,0,26),BackgroundTransparency=1,Text="TP Walk",
TextColor3=WHITE,TextSize=14,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,},panel)local track=make("Frame",{Position=UDim2.fromOffset(10,130),Size=UDim2.new(1,-20,0,5),
BackgroundColor3=WHITE,BorderSizePixel=0,Active=true,},panel)local hitArea=make("Frame",{Position=UDim2.fromOffset(-9,-15),Size=UDim2.new(1,18,0,36),BackgroundTransparency=1,Active=true,},track)
local thumb=textButton("",track,WHITE)thumb.AnchorPoint=Vector2.new(0.5,0.5)thumb.Size=UDim2.fromOffset(18,18)thumb.Position=UDim2.new(0,0,0.5,0)local value=make("Frame",{
AnchorPoint=Vector2.new(0.5,0),Position=UDim2.new(0.5,0,0,150),Size=UDim2.fromOffset(85,28),BackgroundTransparency=1,},panel)local segments={a={2,0,10,2},b={12,2,2,9},c={12,13,2,9},d={2,22,10,2},
e={0,13,2,9},f={0,2,2,9},g={2,11,10,2},}local numbers={["0"]="abcdef",["1"]="bc",["2"]="abged",["3"]="abgcd",["4"]="fgbc",["5"]="afgcd",["6"]="afgecd",["7"]="abc",["8"]="abcdefg",["9"]="abfgcd",}
local lastDisplay local function drawNumber(number)local display=string.format("%.1f",number)if display==lastDisplay then return end lastDisplay=display for _,child in ipairs(value:GetChildren())do
child:Destroy()end local totalWidth=0 for char in display:gmatch(".")do totalWidth+=(char=="."and 7 or 14)+3 end local x=(85-totalWidth+3)/2 for char in display:gmatch(".")do if char=="."then
make("Frame",{Position=UDim2.fromOffset(x+2,21),Size=UDim2.fromOffset(3,3),BackgroundColor3=WHITE,BorderSizePixel=0,},value)x+=10 else for segment in(numbers[char]or""):gmatch(".")do
local part=segments[segment]make("Frame",{Position=UDim2.fromOffset(x+part[1],part[2]),Size=UDim2.fromOffset(part[3],part[4]),BackgroundColor3=WHITE,BorderSizePixel=0,},value)end x+=17 end end end
local function update()toggle.Text=SC.speedEnabled and"ON"or"OFF"toggle.BackgroundColor3=SC.speedEnabled and WHITE or BLACK toggle.TextColor3=SC.speedEnabled and BLACK or WHITE
thumb.Position=UDim2.new(SC.tpSpeed/10,0,0.5,0)drawNumber(SC.tpSpeed)end local function setFromPointer(x)if track.AbsoluteSize.X<=0 then return end local ratio=math.clamp(
(x-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)SC.tpSpeed=math.floor(ratio*100+0.5)/10 update()end local activeInput=nil for _,handle in ipairs({hitArea,thumb})do
handle.InputBegan:Connect(function(input)if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then activeInput=input
setFromPointer(input.Position.X)end end)end local changedConnection local endedConnection changedConnection=UIS.InputChanged:Connect(function(input)if activeInput and(input==activeInput or(
activeInput.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseMovement))then setFromPointer(input.Position.X)end end)
endedConnection=UIS.InputEnded:Connect(function(input)if input==activeInput then activeInput=nil end end)table.insert(categoryConnections,changedConnection)
table.insert(categoryConnections,endedConnection)toggle.Activated:Connect(function()SC.speedEnabled=not SC.speedEnabled update()end)SC.updateSpeedPanel=update update()end)addCategory("C-Fly",function(panel)
local scroll=make("ScrollingFrame",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=4,ScrollingDirection=Enum.ScrollingDirection.Y,
CanvasSize=UDim2.fromOffset(0,350),},panel)make("TextLabel",{Size=UDim2.new(1,0,0,30),BackgroundTransparency=1,Text="C-Fly",TextColor3=WHITE,TextSize=20,Font=Enum.Font.Code,
TextXAlignment=Enum.TextXAlignment.Left,},scroll)local toggle=textButton("OFF",scroll)toggle.Position=UDim2.fromOffset(0,38)toggle.Size=UDim2.fromOffset(105,40)make("TextLabel",{
Position=UDim2.fromOffset(0,91),Size=UDim2.new(1,0,0,24),BackgroundTransparency=1,Text="Fly Speed",TextColor3=WHITE,TextSize=16,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,},scroll)
local track=make("Frame",{Position=UDim2.fromOffset(10,136),Size=UDim2.new(1,-20,0,5),BackgroundColor3=WHITE,BorderSizePixel=0,Active=true,},scroll)local hitArea=make("Frame",{
Position=UDim2.fromOffset(-9,-15),Size=UDim2.new(1,18,0,36),BackgroundTransparency=1,Active=true,},track)local thumb=textButton("",track,WHITE)thumb.AnchorPoint=Vector2.new(0.5,0.5)
thumb.Size=UDim2.fromOffset(18,18)local value=make("TextLabel",{Position=UDim2.fromOffset(0,154),Size=UDim2.new(1,0,0,24),BackgroundTransparency=1,TextColor3=WHITE,TextSize=15,Font=Enum.Font.Code,
},scroll)local mobileMode=textButton("Mobile: BUTTONS",scroll)mobileMode.Position=UDim2.fromOffset(0,194)mobileMode.Size=UDim2.fromOffset(170,36)local followJug=textButton("Follow Jug: OFF",scroll)
followJug.Position=UDim2.fromOffset(0,244)followJug.Size=UDim2.fromOffset(170,38)local followNotice=make("TextLabel",{
Position=UDim2.fromOffset(0,289),Size=UDim2.new(1,0,0,48),BackgroundTransparency=1,Text="",TextColor3=WHITE,TextSize=12,TextWrapped=true,
TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,Font=Enum.Font.Code,},scroll)local function update()toggle.Text=SC.cFlyEnabled and"ON"or"OFF"toggle.BackgroundColor3=SC.cFlyEnabled and WHITE or BLACK
toggle.TextColor3=SC.cFlyEnabled and BLACK or WHITE thumb.Position=UDim2.new((SC.cFlySpeed-10)/110,0,0.5,0)value.Text=string.format("%d studs/s",SC.cFlySpeed)
mobileMode.Text=SC.cFlyCameraMobile and"Mobile: CAMERA"or"Mobile: BUTTONS"followJug.Text="Follow Jug: "..(SC.cFlyFollowJug and"ON"or"OFF")followJug.BackgroundColor3=SC.cFlyFollowJug and WHITE or BLACK
followJug.TextColor3=SC.cFlyFollowJug and BLACK or WHITE followNotice.Text=SC.cFlyNotice end updateCFlyPanel=update local function setFromPointer(x)if track.AbsoluteSize.X<=0 then return end
local ratio=math.clamp((x-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)SC.cFlySpeed=10+math.floor(ratio*110+0.5)update()end local activeInput for _,handle in ipairs({hitArea,thumb})do
handle.InputBegan:Connect(function(input)if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then activeInput=input
setFromPointer(input.Position.X)end end)end table.insert(categoryConnections,UIS.InputChanged:Connect(function(input)if activeInput and(input==activeInput or(
activeInput.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseMovement))then setFromPointer(input.Position.X)end end))
table.insert(categoryConnections,UIS.InputEnded:Connect(function(input)if input==activeInput then activeInput=nil end end))toggle.Activated:Connect(function()if SC.cFlyEnabled then stopCFly()else
startCFly()end update()end)mobileMode.Activated:Connect(function()SC.cFlyCameraMobile=not SC.cFlyCameraMobile updateCFlyMobileButtons()update()end)followJug.Activated:Connect(function()
if not SC.cFlyFollowJug and SC.isOwnerAccount(juggernautPlayer)then SC.cFlyNotice="nuh uh you cant kill me"update()return end
if not SC.cFlyEnabled then followJug.Text="C-Fly required"return end if not SC.cFlyFollowJug then local target=juggernautPlayer local model=target and target.Character
local humanoid=model and model:FindFirstChildOfClass("Humanoid")if target==player or not model or model.Parent~=workspace:FindFirstChild("Killers")or not humanoid or humanoid.Health<=0
or not model:FindFirstChild("HumanoidRootPart")then followJug.Text="Jug unavailable"return end end SC.cFlyNotice=""SC.cFlyFollowJug=not SC.cFlyFollowJug update()end)update()end)function SC.stopFling()
local state=SC.fling if not state.active then return end state.active=false local root=state.root if root and root.Parent then root.AssemblyLinearVelocity=Vector3.zero
root.AssemblyAngularVelocity=Vector3.zero if state.home and state.character and state.character.Parent and state.character:FindFirstChildOfClass("Humanoid")
and state.character:FindFirstChildOfClass("Humanoid").Health>0 then state.character:PivotTo(state.home)end root.CanCollide=state.canCollide root.CollisionGroup=state.collisionGroup end state.root=nil
state.character=nil state.home=nil if state.status then state.status.Text="Ready"end end function SC.startFling()local state=SC.fling if state.active or SC.paused then return end
updateJuggernaut()if SC.isOwnerAccount(juggernautPlayer)then if state.status and state.status.Parent then state.status.Text="nuh uh you cant kill me"end return end
if SC.stopJuggernautAutoKill then SC.stopJuggernautAutoKill()end local target=juggernautPlayer and juggernautPlayer.Character
local targetRoot=target and target:FindFirstChild("HumanoidRootPart")local targetHumanoid=target and target:FindFirstChildOfClass("Humanoid")local character=player.Character
local root=character and character:FindFirstChild("HumanoidRootPart")local humanoid=character and character:FindFirstChildOfClass("Humanoid")
if not targetRoot or not targetHumanoid or targetHumanoid.Health<=0 or not root or not humanoid or humanoid.Health<=0 then if state.status then state.status.Text="No live Juggernaut"end return end
if SC.cFlyEnabled then stopCFly()end SC.trackEnabled=false SC.followEnabled=false autoTrack.stop()restoreTrackRotation()state.active=true state.generation=(state.generation or 0)+1
local generation=state.generation state.root=root state.character=character state.home=character:GetPivot()state.canCollide=root.CanCollide state.collisionGroup=root.CollisionGroup
if state.status then state.status.Text="Flinging..."end task.spawn(function()local ok,flingError=pcall(function()local camera=workspace.CurrentCamera
local look=camera and camera.CFrame.LookVector or root.CFrame.LookVector local defaultDirection=Vector3.new(look.X,0,look.Z)defaultDirection=defaultDirection.Magnitude>0.01
and defaultDirection.Unit or Vector3.new(0,0,-1)local floorParams=RaycastParams.new()floorParams.FilterType=Enum.RaycastFilterType.Exclude floorParams.FilterDescendantsInstances={character,target}
root.CollisionGroup="Default"root.CanCollide=true local initialHealth=humanoid.Health local startingPosition=targetRoot.Position local endTime=os.clock()+1.15
while state.active and state.generation==generation and os.clock()<endTime and root.Parent and targetRoot.Parent and targetHumanoid.Health>0 and humanoid.Health>math.max(0,initialHealth-10)do
local velocity=targetRoot.AssemblyLinearVelocity local planarVelocity=Vector3.new(velocity.X,0,velocity.Z)local moving=planarVelocity.Magnitude>3
local direction=moving and planarVelocity.Unit or defaultDirection local lead=moving and direction*math.min(planarVelocity.Magnitude*0.03,0.65)or Vector3.zero
local targetPosition=targetRoot.Position+lead local floor=workspace:Raycast(targetPosition+Vector3.new(0,4,0),Vector3.new(0,-12,0),floorParams)local safeY=math.max(targetPosition.Y+1.6,
floor and floor.Position.Y+4 or targetPosition.Y+1.6)local center=Vector3.new(targetPosition.X,safeY,targetPosition.Z)local distanceBehind=moving and 1.1 or 0.35
character:PivotTo(CFrame.lookAt(center-direction*distanceBehind,center+direction))root.AssemblyAngularVelocity=Vector3.new(0,400,0)root.AssemblyLinearVelocity=direction*450+planarVelocity
if(targetRoot.Position-startingPosition).Magnitude>35 or targetRoot.AssemblyLinearVelocity.Magnitude>160 then break end RS.Heartbeat:Wait()end end)if state.generation==generation then SC.stopFling()
if not ok then warn("HeadLockMenu Fling: "..tostring(flingError))if state.status then state.status.Text="Fling error (console)"end end end end)end connect(player.CharacterRemoving,SC.stopFling)
SC.codes={pause="pause",unlock="unpause",kick="kick",}addCategory("Fling",function(panel)make("TextLabel",{Size=UDim2.new(1,0,0,30),BackgroundTransparency=1,Text="Fling Juggernaut",
TextColor3=WHITE,TextSize=20,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,},panel)local button=textButton("FLING",panel)button.Position=UDim2.fromOffset(0,40)
button.Size=UDim2.new(1,0,0,38)connect(button.Activated,SC.startFling)SC.fling.status=make("TextLabel",{Position=UDim2.fromOffset(0,88),Size=UDim2.new(1,0,0,44),BackgroundTransparency=1,Text="Ready",
TextColor3=WHITE,TextSize=14,TextWrapped=true,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,},panel)make("TextLabel",{Position=UDim2.fromOffset(0,140),Size=UDim2.new(1,0,0,32),BackgroundTransparency=1,Text="This might not work all the time.",TextColor3=WHITE,TextSize=11,TextWrapped=true,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,},panel)end)function SC.stopJuggernautAutoKill()local s=SC.juggernautAutoKill if not s.enabled then return end
s.enabled=false s.target=nil local root=s.character and s.character:FindFirstChild("HumanoidRootPart")if s.humanoid and s.humanoid.Parent and s.humanoid.Health>0 then
s.humanoid.AutoRotate=s.autoRotate if root and s.upright and s.offset then local face=s.upright.LookVector face=Vector3.new(face.X,0,face.Z)if face.Magnitude<0.01 then face=Vector3.new(0,0,-1)end
s.character:PivotTo(CFrame.lookAt(root.Position,root.Position+face)*s.offset)root.AssemblyAngularVelocity=Vector3.zero root.AssemblyLinearVelocity=Vector3.zero end end if s.button and s.button.Parent then
s.button.Text="Auto Kill: OFF"s.button.BackgroundColor3=BLACK s.button.TextColor3=WHITE end if s.status and s.status.Parent then s.status.Text="OFF"end end local function autoKillSurvivor(target)
if not SC.canSelectPlayer(target)then return end local active=workspace:FindFirstChild("Characters to kill")local model=target and target.Character local h=model and model:FindFirstChildOfClass("Humanoid")
local head=model and model:FindFirstChild("Head")local root=model and model:FindFirstChild("HumanoidRootPart")if active and model and model.Parent==active and h and h.Health>0
and head and root and root.Position.Y<SC.combatYLimit and not model:FindFirstChildOfClass("ForceField")then return model,head,root end end addCategory("Juggernaut",function(panel)
make("TextLabel",{Size=UDim2.new(1,0,0,30),BackgroundTransparency=1,Text="Juggernaut",TextColor3=WHITE,TextSize=20,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left},panel)
local s=SC.juggernautAutoKill local button=textButton(s.enabled and"Auto Kill: ON"or"Auto Kill: OFF",panel)button.Position=UDim2.fromOffset(0,40)button.Size=UDim2.new(1,0,0,38)s.button=button
s.status=make("TextLabel",{Position=UDim2.fromOffset(0,86),Size=UDim2.new(1,0,0,40),BackgroundTransparency=1,Text=s.enabled and"Searching..."or"OFF",TextColor3=WHITE,
TextSize=13,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left},panel)local function paint()button.Text=s.enabled and"Auto Kill: ON"or"Auto Kill: OFF"
button.BackgroundColor3=s.enabled and WHITE or BLACK button.TextColor3=s.enabled and BLACK or WHITE end button.Activated:Connect(function()if s.enabled then SC.stopJuggernautAutoKill()else
updateJuggernaut()local c=player.Character local h=c and c:FindFirstChildOfClass("Humanoid")local r=c and c:FindFirstChild("HumanoidRootPart")if SC.paused or juggernautPlayer~=player
or not c or c.Parent~=workspace:FindFirstChild("Killers")or not h or h.Health<=0 or not r then s.status.Text="Juggernaut only"return end if SC.cFlyEnabled then stopCFly()end SC.trackEnabled=false
SC.followEnabled=false autoTrack.stop()restoreTrackRotation()s.enabled,s.target,s.character,s.humanoid=true,nil,c,h s.autoRotate,s.upright=h.AutoRotate,r.CFrame.Rotation
s.offset=r.CFrame:ToObjectSpace(c:GetPivot())end paint()end)paint()end)RS:BindToRenderStep("HeadLockMenuJuggernautAutoKill",Enum.RenderPriority.Character.Value+2,function()
local s=SC.juggernautAutoKill if not s.enabled then return end local c=player.Character local h=c and c:FindFirstChildOfClass("Humanoid")local r=c and c:FindFirstChild("HumanoidRootPart")
if SC.paused or c~=s.character or not h or h.Health<=0 or not r or c.Parent~=workspace:FindFirstChild("Killers")or SC.trackEnabled or SC.followEnabled or SC.cFlyEnabled then SC.stopJuggernautAutoKill()return
end local model,head,targetRoot=autoKillSurvivor(s.target)if not model then local distance s.target=nil for _,other in ipairs(Players:GetPlayers())do local m,_,part=autoKillSurvivor(other)
if m and other~=player then local gap=(part.Position-r.Position).Magnitude if not distance or gap<distance then s.target,distance=other,gap end end end model,head,targetRoot=autoKillSurvivor(s.target)
end if not model then SC.stopJuggernautAutoKill()return end local ray=RaycastParams.new()ray.FilterType=Enum.RaycastFilterType.Exclude
ray.FilterDescendantsInstances={c,model}ray.RespectCanCollide=true local look=targetRoot.CFrame.LookVector local face=Vector3.new(look.X,0,look.Z)
face=face.Magnitude>0.1 and face.Unit or Vector3.new(0,0,-1)local roof=workspace:Raycast(head.Position+Vector3.new(0,head.Size.Y*0.5,0),Vector3.new(0,3.5,0),ray)local desired,place if not roof then
local pos=head.Position+Vector3.new(0,head.Size.Y*0.5+0.45,0)desired=CFrame.lookAt(pos,pos-Vector3.yAxis,face)place="above"else local side=Vector3.new(-face.Z,0,face.X)
for _,dir in ipairs({side,-side,-face,face})do local pos=head.Position+dir*1.35-Vector3.new(0,0.6,0)if not workspace:Raycast(head.Position,pos-head.Position,ray)
and not workspace:Raycast(pos,Vector3.new(0,2.6,0),ray)then desired=CFrame.lookAt(pos,head.Position)place="beside"break end end end if desired then h.AutoRotate=false c:PivotTo(desired*s.offset)end
if s.status and s.status.Parent then s.status.Text=s.target.Name.." | "..(place or"no safe space")end end)addCategory("Leather",function(panel)make("TextLabel",{Size=UDim2.new(1,0,0,30),
BackgroundTransparency=1,Text="Leather",TextColor3=WHITE,TextSize=20,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,},panel)local toggle=textButton("OFF",panel)
toggle.Position=UDim2.fromOffset(0,38)toggle.Size=UDim2.new(0.5,-5,0,40)local autoButton=textButton("Auto Track OFF",panel)autoButton.Position=UDim2.new(0.5,5,0,38)
autoButton.Size=UDim2.new(0.5,-5,0,40)autoButton.TextSize=12 local selection=make("TextLabel",{Position=UDim2.fromOffset(0,84),Size=UDim2.new(1,0,0,26),BackgroundTransparency=1,Text="Target: None",
TextColor3=WHITE,TextSize=13,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,},panel)local namesButton=textButton("Players",panel)
namesButton.Position=UDim2.fromOffset(0,114)namesButton.Size=UDim2.new(1,0,0,39)local namesList=make("ScrollingFrame",{Position=UDim2.fromOffset(0,159),Size=UDim2.new(1,0,1,-162),
BackgroundColor3=BLACK,BorderSizePixel=0,ScrollBarThickness=4,CanvasSize=UDim2.fromOffset(0,0),Visible=SC.trackListOpen,},panel)local listLayout=make("UIListLayout",{Padding=UDim.new(0,3),
SortOrder=Enum.SortOrder.Name,},namesList)listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()namesList.CanvasSize=UDim2.fromOffset(0,listLayout.AbsoluteContentSize.Y+4)end)
updateTrack=function()toggle.Text=SC.trackEnabled and"ON"or"OFF"toggle.BackgroundColor3=SC.trackEnabled and WHITE or BLACK toggle.TextColor3=SC.trackEnabled and BLACK or WHITE
local autoOn=autoTrack.mode=="Leather"autoButton.Text=autoOn and"Auto Track ON"or"Auto Track OFF"autoButton.BackgroundColor3=autoOn and WHITE or BLACK autoButton.TextColor3=autoOn and BLACK or WHITE
selection.Text="Target: "..(SC.trackPlayer and SC.trackPlayer.Name or"None")namesButton.Text=SC.trackListOpen and"Players (close)"or"Players"namesList.Visible=SC.trackListOpen end updateTrackPlayers=function()
for _,child in ipairs(namesList:GetChildren())do if child:IsA("TextButton")then child:Destroy()end end local allPlayers=Players:GetPlayers()table.sort(allPlayers,function(a,b)
return a.Name:lower()<b.Name:lower()end)for _,target in ipairs(allPlayers)do if SC.canSelectPlayer(target)then local row=textButton(target.Name,namesList)row.Name=target.Name row.Size=UDim2.new(1,-7,0,36)
row.TextXAlignment=Enum.TextXAlignment.Left row.Text="  "..target.Name row.BackgroundColor3=target==SC.trackPlayer and WHITE or BLACK row.TextColor3=target==SC.trackPlayer and BLACK or WHITE
row.Activated:Connect(function()if not SC.canSelectPlayer(target)then return end if autoTrack.mode=="Leather"then autoTrack.stop()end SC.trackPlayer=target updateTrack()updateTrackPlayers()end)end end end toggle.Activated:Connect(function()
autoTrack.stop()SC.trackEnabled=not SC.trackEnabled if SC.trackEnabled then SC.followEnabled=false
    restoreTrackRotation()if updateFollow then updateFollow()end   end if SC.trackEnabled and not SC.trackPlayer then
SC.trackListOpen=true elseif not SC.trackEnabled then restoreTrackRotation()end updateTrack()end)autoButton.Activated:Connect(function()if autoTrack.mode=="Leather"then autoTrack.stop()SC.trackEnabled=false
restoreTrackRotation()else autoTrack.stop()autoTrack.mode="Leather"autoTrack.excluded={}autoTrack.nextScan=0 SC.trackEnabled=true SC.followEnabled=false
  restoreTrackRotation() SC.trackListOpen=false SC.trackPlayer=nil autoTrack.service(os.clock())if updateFollow then updateFollow()end
    end updateTrack()end)namesButton.Activated:Connect(function()SC.trackListOpen=not SC.trackListOpen updateTrack()
end)updateTrackPlayers()updateTrack()end)addCategory("Tracking",function(panel)make("TextLabel",{Size=UDim2.new(1,0,0,30),BackgroundTransparency=1,Text="Tracking",TextColor3=WHITE,TextSize=20,
Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,},panel)local toggle=textButton("OFF",panel)toggle.Position=UDim2.fromOffset(0,38)toggle.Size=UDim2.new(0.5,-5,0,40)
local autoButton=textButton("Auto Track OFF",panel)autoButton.Position=UDim2.new(0.5,5,0,38)autoButton.Size=UDim2.new(0.5,-5,0,40)autoButton.TextSize=12 local selection=make("TextLabel",{
Position=UDim2.fromOffset(0,84),Size=UDim2.new(1,0,0,26),BackgroundTransparency=1,Text="Target: None",TextColor3=WHITE,TextSize=13,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,
TextTruncate=Enum.TextTruncate.AtEnd,},panel)local namesButton=textButton("Players",panel)namesButton.Position=UDim2.fromOffset(0,114)namesButton.Size=UDim2.new(1,0,0,39)
local namesList=make("ScrollingFrame",{Position=UDim2.fromOffset(0,159),Size=UDim2.new(1,0,1,-162),BackgroundColor3=BLACK,BorderSizePixel=0,ScrollBarThickness=4,CanvasSize=UDim2.fromOffset(0,0),
Visible=SC.followListOpen,},panel)local listLayout=make("UIListLayout",{Padding=UDim.new(0,3),SortOrder=Enum.SortOrder.Name,},namesList)
listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()namesList.CanvasSize=UDim2.fromOffset(0,listLayout.AbsoluteContentSize.Y+4)end)updateFollow=function()
toggle.Text=SC.followEnabled and"ON"or"OFF"toggle.BackgroundColor3=SC.followEnabled and WHITE or BLACK toggle.TextColor3=SC.followEnabled and BLACK or WHITE local autoOn=autoTrack.mode=="Tracking"
autoButton.Text=autoOn and"Auto Track ON"or"Auto Track OFF"autoButton.BackgroundColor3=autoOn and WHITE or BLACK autoButton.TextColor3=autoOn and BLACK or WHITE
selection.Text="Target: "..(SC.followPlayer and SC.followPlayer.Name or"None")namesButton.Text=SC.followListOpen and"Players (close)"or"Players"namesList.Visible=SC.followListOpen end
updateFollowPlayers=function()for _,child in ipairs(namesList:GetChildren())do if child:IsA("TextButton")then child:Destroy()end end local allPlayers=Players:GetPlayers()
table.sort(allPlayers,function(a,b)return a.Name:lower()<b.Name:lower()end)for _,target in ipairs(allPlayers)do if SC.canSelectPlayer(target)then local row=textButton(target.Name,namesList)row.Name=target.Name
row.Size=UDim2.new(1,-7,0,36)row.TextXAlignment=Enum.TextXAlignment.Left row.Text="  "..target.Name row.BackgroundColor3=target==SC.followPlayer and WHITE or BLACK
row.TextColor3=target==SC.followPlayer and BLACK or WHITE row.Activated:Connect(function()if not SC.canSelectPlayer(target)then return end if autoTrack.mode=="Tracking"then autoTrack.stop()end SC.followPlayer=target updateFollow()updateFollowPlayers()
end)end end end toggle.Activated:Connect(function()autoTrack.stop()SC.followEnabled=not SC.followEnabled if SC.followEnabled then SC.trackEnabled=false
      restoreTrackRotation()if updateTrack then updateTrack()end   end if SC.followEnabled and not SC.followPlayer then SC.followListOpen=true elseif not SC.followEnabled then restoreTrackRotation()end updateFollow()end)autoButton.Activated:Connect(function()
if autoTrack.mode=="Tracking"then autoTrack.stop()SC.followEnabled=false restoreTrackRotation()else autoTrack.stop()autoTrack.mode="Tracking"autoTrack.excluded={}autoTrack.nextScan=0 SC.followEnabled=true
SC.trackEnabled=false       restoreTrackRotation() SC.followListOpen=false SC.followPlayer=nil
autoTrack.service(os.clock())if updateTrack then updateTrack()end     end updateFollow()end)
namesButton.Activated:Connect(function()SC.followListOpen=not SC.followListOpen updateFollow()end)updateFollowPlayers()updateFollow()end)addCategory("Teleport",function(panel)make("TextLabel",{
Size=UDim2.new(1,0,0,30),BackgroundTransparency=1,Text="Teleport",TextColor3=WHITE,TextSize=20,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,},panel)local selection=make("TextLabel",{
Position=UDim2.fromOffset(0,36),Size=UDim2.new(1,0,0,25),BackgroundTransparency=1,TextColor3=WHITE,TextSize=13,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,
TextTruncate=Enum.TextTruncate.AtEnd,},panel)local teleportButton=textButton("Teleport",panel)teleportButton.Position=UDim2.fromOffset(0,68)teleportButton.Size=UDim2.new(1,0,0,38)
local namesList=make("ScrollingFrame",{Position=UDim2.fromOffset(0,114),Size=UDim2.new(1,0,1,-117),BackgroundColor3=BLACK,BorderSizePixel=0,ScrollBarThickness=4,CanvasSize=UDim2.fromOffset(0,0),
},panel)local listLayout=make("UIListLayout",{Padding=UDim.new(0,3),SortOrder=Enum.SortOrder.Name,},namesList)listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
namesList.CanvasSize=UDim2.fromOffset(0,listLayout.AbsoluteContentSize.Y+4)end)teleportState.update=function()selection.Text="Target: "..(teleportState.target and teleportState.target.Name or"None")
end teleportState.refresh=function()for _,child in ipairs(namesList:GetChildren())do if child:IsA("TextButton")then child:Destroy()end end local allPlayers=Players:GetPlayers()
table.sort(allPlayers,function(a,b)return a.Name:lower()<b.Name:lower()end)for _,target in ipairs(allPlayers)do if SC.canSelectPlayer(target)then local row=textButton(target.Name,namesList)row.Name=target.Name
row.Size=UDim2.new(1,-7,0,36)row.TextXAlignment=Enum.TextXAlignment.Left row.Text="  "..target.Name row.TextTruncate=Enum.TextTruncate.AtEnd
row.BackgroundColor3=target==teleportState.target and WHITE or BLACK row.TextColor3=target==teleportState.target and BLACK or WHITE row.Activated:Connect(function()if not SC.canSelectPlayer(target)then return end teleportState.target=target
teleportState.update()teleportState.refresh()end)end end end teleportButton.Activated:Connect(function()local target=teleportState.target if not SC.canSelectPlayer(target)then selection.Text="Target unavailable"return end local character=player.Character
local myRoot=character and character:FindFirstChild("HumanoidRootPart")local targetCharacter=target and target.Parent==Players and target.Character
local targetRoot=targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart")local targetHumanoid=targetCharacter and targetCharacter:FindFirstChildOfClass("Humanoid")
if not myRoot or not targetRoot or not targetHumanoid or targetHumanoid.Health<=0 then selection.Text="Target unavailable"return end local arrival=targetRoot.CFrame*CFrame.new(0,0,2.5)
character:PivotTo(CFrame.lookAt(arrival.Position,targetRoot.Position))end)teleportState.refresh()teleportState.update()end)SC.safeWaypoint={"Anti-Death Safe Spot",109.30000305175781,335.49996948242188,62,-1.9155952436430165e-12}
SC.defaultWaypoints={{"bunker",221.385,263.500,418.305,91.2},{"ammo room",184.516,314.103,436.724,2.6},{"rails elevator",231.946,374.500,23.714,173.2},{"jail",69.549,291.500,241.237,-92.7},
{"sewer",174.798,271.700,141.763,-177.5},{"main",59.488,313.500,370.571,-87.8},{"boxes",174.920,328.500,182.915,92.8},{"teleporter",111.291,313.500,71.226,3.3},
{"armor",-168.552,293.500,314.204,91.0},{"lab",-48.833,313.500,460.786,-90.2},{"inside radio",160.174,345.500,534.997,-0.5},{"cafe",221.516,337.500,627.630,-89.6},
{"outside radio",140.617,313.500,449.928,1.0},{"bathroom",77.900,323.500,656.226,-112.2},{"pap",218.572,323.500,806.874,179.0},{"new sewer",434.936,323.500,791.100,85.9},
{"upstairs ammo",206.227,343.982,810.778,-87.5},SC.safeWaypoint}
SC.waypointStore={custom={},selected=nil,loaded=false,note="",key=tostring(game.PlaceId).."_"..tostring(player.UserId)}
SC.waypointStore.path="HeadLockWaypoints_"..SC.waypointStore.key..".json"
function SC.validWaypoint(entry)
 if type(entry)~="table"or type(entry[1])~="string"or #entry[1]>100 then return false end
 for i=2,5 do local v=entry[i]if type(v)~="number"or v~=v or math.abs(v)>10000000 then return false end end
 return true
end
function SC.loadWaypoints()
 local s=SC.waypointStore if s.loaded then return end s.loaded=true
 if type(_G.HeadLockWaypointCache)~="table"then _G.HeadLockWaypointCache={}end
 local cached=_G.HeadLockWaypointCache[s.key]
 if type(cached)=="table"then for _,entry in ipairs(cached)do if SC.validWaypoint(entry)then table.insert(s.custom,table.clone(entry))end end end
 s.disk=type(writefile)=="function"and type(readfile)=="function"
 s.note=s.disk and"Custom spots save on this device for your account."or"Custom spots are saved for this session only."
 if s.disk then
  local ok,text=pcall(readfile,s.path)
  if ok and type(text)=="string"then
   local decoded,data=pcall(function()return game:GetService("HttpService"):JSONDecode(text)end)
   if decoded and type(data)=="table"and data.userId==player.UserId and data.placeId==game.PlaceId and type(data.waypoints)=="table"then
    s.custom={}for _,entry in ipairs(data.waypoints)do if #s.custom>=100 then break end if SC.validWaypoint(entry)then table.insert(s.custom,table.clone(entry))end end
   else s.note="Saved file could not be read; session spots are available."end
  end
 end
 _G.HeadLockWaypointCache[s.key]=s.custom
end
function SC.persistWaypoints()
 local s=SC.waypointStore _G.HeadLockWaypointCache[s.key]=s.custom
 if s.disk then
  local ok=pcall(function()
   local text=game:GetService("HttpService"):JSONEncode({version=1,userId=player.UserId,placeId=game.PlaceId,waypoints=s.custom})
   writefile(s.path,text)
  end)
  s.note=ok and"Saved on this device for your account."or"Device save failed; spots remain saved for this session."
 else s.note="Saved for this session only; device storage is unavailable."end
end
function SC.teleportWaypoint(entry)
 local c=player.Character local h=c and c:FindFirstChildOfClass("Humanoid")local root=c and c:FindFirstChild("HumanoidRootPart")
 if not root or not h or h.Health<=0 then return false end
 local destination=CFrame.new(entry[2],entry[3],entry[4])*CFrame.Angles(0,math.rad(entry[5]),0)
 c:PivotTo(destination*root.CFrame:ToObjectSpace(c:GetPivot()))
 root.AssemblyLinearVelocity=Vector3.zero root.AssemblyAngularVelocity=Vector3.zero return true
end
function SC.drawWaypoints(panel)
 SC.loadWaypoints()local s=SC.waypointStore
 make("TextLabel",{Size=UDim2.new(1,0,0,30),BackgroundTransparency=1,Text="Waypoints",TextColor3=WHITE,TextSize=20,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left},panel)
 local status=make("TextLabel",{Position=UDim2.fromOffset(0,32),Size=UDim2.new(1,0,0,36),BackgroundTransparency=1,Text=s.note,TextColor3=WHITE,TextSize=11,Font=Enum.Font.Code,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left},panel)
 local nameBox=make("TextBox",{Name="WaypointName",Position=UDim2.fromOffset(0,75),Size=UDim2.new(1,0,0,32),BackgroundColor3=BLACK,BorderSizePixel=0,Text="",PlaceholderText="New location name / select a custom spot",PlaceholderColor3=WHITE,TextColor3=WHITE,TextSize=12,Font=Enum.Font.Code,ClearTextOnFocus=false},panel)
 make("UIStroke",{Color=WHITE,Thickness=1,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},nameBox)
 local save=textButton("Save Current",panel)save.Position=UDim2.fromOffset(0,116)save.Size=UDim2.new(0.5,-4,0,35)save.TextSize=12
 local rename=textButton("Rename",panel)rename.Position=UDim2.new(0.5,4,0,116)rename.Size=UDim2.new(0.5,-4,0,35)rename.TextSize=12
 local list=make("ScrollingFrame",{Position=UDim2.fromOffset(0,162),Size=UDim2.new(1,0,1,-162),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,CanvasSize=UDim2.fromOffset(0,0)},panel)
 make("UIListLayout",{Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder},list)
 local refresh
 refresh=function()
  for _,child in ipairs(list:GetChildren())do if child:IsA("Frame")then child:Destroy()end end
  local function add(entry,index,custom)
   local row=make("Frame",{Size=UDim2.new(1,-6,0,36),LayoutOrder=index,BackgroundTransparency=1},list)
   local label
   if custom then
    label=textButton(entry[1],row)label.BackgroundColor3=s.selected==entry and WHITE or BLACK label.TextColor3=s.selected==entry and BLACK or WHITE
    label.Activated:Connect(function()s.selected=entry nameBox.Text=entry[1]status.Text="Selected: "..entry[1]refresh()end)
   else label=make("TextLabel",{BackgroundTransparency=1,Text=entry[1],TextColor3=WHITE,Font=Enum.Font.Code},row)end
   label.Size=UDim2.new(1,custom and-96 or-60,1,0)label.TextSize=12 label.TextTruncate=Enum.TextTruncate.AtEnd label.TextXAlignment=Enum.TextXAlignment.Left
   local go=textButton("Goto",row)go.Position=UDim2.new(1,custom and-92 or-56,0,1)go.Size=UDim2.fromOffset(52,32)go.TextSize=12
   go.Activated:Connect(function()status.Text=SC.teleportWaypoint(entry)and("Goto: "..entry[1])or"Character unavailable"end)
   if custom then
    local del=textButton("X",row)del.Position=UDim2.new(1,-34,0,1)del.Size=UDim2.fromOffset(30,32)del.TextSize=12
    del.Activated:Connect(function()local index=table.find(s.custom,entry)if not index then return end table.remove(s.custom,index)
     if s.selected==entry then s.selected=nil nameBox.Text=""end SC.persistWaypoints()status.Text="Deleted "..entry[1]..". "..s.note refresh()end)
   end
  end
  for i,entry in ipairs(SC.defaultWaypoints)do add(entry,i,false)end
  for i,entry in ipairs(s.custom)do add(entry,#SC.defaultWaypoints+i,true)end
  list.CanvasSize=UDim2.fromOffset(0,(#SC.defaultWaypoints+#s.custom)*41+4)
 end
 save.Activated:Connect(function()
  if #s.custom>=100 then status.Text="Custom waypoint limit: 100"return end
  local c=player.Character local root=c and c:FindFirstChild("HumanoidRootPart")local h=c and c:FindFirstChildOfClass("Humanoid")
  if not root or not h or h.Health<=0 then status.Text="Character unavailable"return end
  local name=nameBox.Text:match("^%s*(.-)%s*$"):gsub("%c",""):sub(1,100)if name==""then name="Waypoint "..(#s.custom+1)end
  nameBox:ReleaseFocus()local cf=root.CFrame local p=cf.Position local look=cf.LookVector
  local entry={name,p.X,p.Y,p.Z,math.deg(math.atan2(-look.X,-look.Z))}table.insert(s.custom,entry)s.selected=entry
  SC.persistWaypoints()status.Text="Saved "..name..". "..s.note refresh()
 end)
 rename.Activated:Connect(function()
  if not s.selected or not table.find(s.custom,s.selected)then status.Text="Select a custom waypoint to rename."return end
  local name=nameBox.Text:match("^%s*(.-)%s*$"):gsub("%c",""):sub(1,100)if name==""then status.Text="Enter a waypoint name."return end
  nameBox:ReleaseFocus()s.selected[1]=name SC.persistWaypoints()status.Text="Renamed to "..name..". "..s.note refresh()
 end)
 refresh()
end
addCategory("Waypoints",SC.drawWaypoints)
SC.spectate={enabled=false,target=nil,camera=nil,oldType=nil,update=nil}
function SC.updateSpectateOverlay()
 local s=SC.spectate if not s.overlay or not s.overlay.Parent then return end
 local visible=s.enabled and not SC.paused
 if s.overlay.Visible~=visible then s.overlay.Visible=visible end
 local name=s.target and s.target.Name or"No players available"
 if s.nameLabel.Text~=name then s.nameLabel.Text=name end
end
SC.spectate.overlay=make("Frame",{Name="SpectateOverlay",AnchorPoint=Vector2.new(0.5,1),Position=UDim2.new(0.5,0,1,-112),
Size=UDim2.fromOffset(math.min(320,viewport.X-24),42),BackgroundColor3=BLACK,BorderSizePixel=0,Visible=false},gui)
make("UIStroke",{Color=WHITE,Thickness=1},SC.spectate.overlay)
SC.spectate.left=textButton("◀",SC.spectate.overlay,WHITE)SC.spectate.left.Position=UDim2.fromOffset(4,4)SC.spectate.left.Size=UDim2.fromOffset(34,34)
SC.spectate.right=textButton("▶",SC.spectate.overlay,WHITE)SC.spectate.right.Position=UDim2.new(1,-38,0,4)SC.spectate.right.Size=UDim2.fromOffset(34,34)
SC.spectate.nameLabel=make("TextLabel",{Position=UDim2.fromOffset(44,4),Size=UDim2.new(1,-88,0,34),BackgroundTransparency=1,
Text="",TextColor3=WHITE,TextSize=14,Font=Enum.Font.Code,TextTruncate=Enum.TextTruncate.AtEnd},SC.spectate.overlay)
connect(SC.spectate.left.Activated,function()SC.cycleSpectate(-1)end)
connect(SC.spectate.right.Activated,function()SC.cycleSpectate(1)end)
function SC.spectatePlayers()
 local list={}for _,p in ipairs(Players:GetPlayers())do local c=p.Character local h=c and c:FindFirstChildOfClass("Humanoid")
 if p~=player and c and h and h.Health>0 then table.insert(list,p)end end
 table.sort(list,function(a,b)return a.Name:lower()<b.Name:lower()end)return list
end
function SC.restoreSpectateCamera()
 local s=SC.spectate local camera=workspace.CurrentCamera local c=player.Character local h=c and c:FindFirstChildOfClass("Humanoid")
 if camera then if h then camera.CameraSubject=h end camera.CameraType=s.oldType or Enum.CameraType.Custom end s.camera=nil s.oldType=nil
end
function SC.applySpectate()
 local s=SC.spectate if not s.enabled then return end
 local p=s.target local c=p and p.Parent==Players and p.Character local h=c and c:FindFirstChildOfClass("Humanoid")
 if not h or h.Health<=0 then s.target=SC.spectatePlayers()[1]p=s.target c=p and p.Character h=c and c:FindFirstChildOfClass("Humanoid")end
 local camera=workspace.CurrentCamera
 if camera then
  if s.camera~=camera then s.camera=camera s.oldType=camera.CameraType end
  local own=player.Character local subject=h or(own and own:FindFirstChildOfClass("Humanoid"))
  if subject then camera.CameraType=Enum.CameraType.Custom if camera.CameraSubject~=subject then camera.CameraSubject=subject end end
 end
 SC.updateSpectateOverlay()
end
function SC.setSpectate(value)
 local s=SC.spectate s.enabled=value==true
 if s.enabled then
  SC.enabled=false if updateAimbot then updateAimbot()end
  SC.applySpectate()
  RS:BindToRenderStep("HeadLockMenuSpectate",Enum.RenderPriority.Camera.Value+2,SC.applySpectate)
 else RS:UnbindFromRenderStep("HeadLockMenuSpectate")SC.restoreSpectateCamera()end
 SC.updateSpectateOverlay()if s.update then s.update()end
end
function SC.cycleSpectate(direction)
 local s=SC.spectate local list=SC.spectatePlayers()if #list==0 then s.target=nil else
 local index=table.find(list,s.target)if not index then index=direction<0 and 1 or 0 end s.target=list[(index-1+direction)%#list+1]end
 if s.enabled then SC.applySpectate()end SC.updateSpectateOverlay()if s.update then s.update()end
end
addCategory("Spectate",function(panel)
 make("TextLabel",{Size=UDim2.new(1,0,0,30),BackgroundTransparency=1,Text="Spectate",TextColor3=WHITE,TextSize=20,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left},panel)
 local toggle=textButton("OFF",panel)toggle.Position=UDim2.fromOffset(0,40)toggle.Size=UDim2.fromOffset(105,38)
 make("TextLabel",{Position=UDim2.fromOffset(0,95),Size=UDim2.new(1,0,0,65),BackgroundTransparency=1,
Text="The username and arrows appear above your hotbar while Spectate is ON. They remain available when you hide this menu.",
TextColor3=WHITE,TextSize=12,Font=Enum.Font.Code,TextWrapped=true},panel)
 local function update()
  if not panel.Parent then return end local s=SC.spectate toggle.Text=s.enabled and"ON"or"OFF"toggle.BackgroundColor3=s.enabled and WHITE or BLACK toggle.TextColor3=s.enabled and BLACK or WHITE
 end
 SC.spectate.update=update if not SC.spectate.target then SC.cycleSpectate(1)end
 toggle.Activated:Connect(function()SC.setSpectate(not SC.spectate.enabled)end)
 update()
end)
SC.anti={role=nil,humanoid=nil,character=nil,lastHealth=0,max=0,connection=nil,update=nil,
 survivor={enabled=false,ratio=0.5,max=0,threshold=50,spent=false},juggernaut={enabled=false,ratio=0.5,max=0,threshold=50,spent=false}}
function SC.antiRole(character)
 if not character then return nil end
 local killers=workspace:FindFirstChild("Killers")local survivors=workspace:FindFirstChild("Characters to kill")
 if killers and character.Parent==killers then return"juggernaut"end
 if survivors and character.Parent==survivors then return"survivor"end
end
function SC.resetAntiRound(role,maximum,health)
 local s=SC.anti[role]s.max=maximum s.threshold=math.clamp(math.floor(maximum*s.ratio+0.5),1,math.max(1,math.ceil(health)-1))
 s.spent=false s.firedThreshold=nil
end
function SC.syncAntiDeath()
 local a=SC.anti local c=player.Character local h=c and c:FindFirstChildOfClass("Humanoid")local changed=false
 if h~=a.humanoid or c~=a.character then
  if a.connection then a.connection:Disconnect()a.connection=nil end
  a.humanoid=h a.character=c a.role=nil a.lastHealth=h and h.Health or 0 changed=true
  if h then a.connection=h.HealthChanged:Connect(function(health)SC.onAntiHealth(health,h)end)end
 end
 local role=SC.antiRole(c)local maximum=h and h.MaxHealth or 0
 if role~=a.role or maximum~=a.max then
  a.role=role a.max=maximum a.lastHealth=h and h.Health or 0 changed=true
  if role and h and h.Health>0 and maximum>0 then SC.resetAntiRound(role,maximum,h.Health)end
 end
 return changed
end
function SC.stopConflictingMovement()
 SC.stopJuggernautAutoKill()SC.stopFling()stopCFly()
 SC.speedEnabled=false SC.trackEnabled=false SC.followEnabled=false autoTrack.stop()restoreTrackRotation()
 if SC.updateSpeedPanel then SC.updateSpeedPanel()end
 if updateTrack then updateTrack()end if updateFollow then updateFollow()end
end
function SC.onAntiHealth(health,source)
 local a=SC.anti if source~=a.humanoid then return end
 local previous=a.lastHealth local changed=SC.syncAntiDeath()a.lastHealth=health
 if changed or not a.role then if a.update then a.update()end return end
 local s=a[a.role]
 if a.role=="juggernaut"and health>previous then SC.resetAntiRound(a.role,a.max,health)end
 if a.role=="survivor"and health>previous and health>s.threshold then s.spent=false s.firedThreshold=nil end
 local root=a.character and a.character:FindFirstChild("HumanoidRootPart")
 if not SC.paused and s.enabled and not s.spent and health>0 and health<previous and health<=s.threshold and root and root.Position.Y<SC.combatYLimit then
  s.spent=true s.firedThreshold=s.threshold
  SC.stopConflictingMovement()
  if not SC.teleportWaypoint(SC.safeWaypoint)then s.spent=false s.firedThreshold=nil end
 end
 if a.update then a.update()end
end
function SC.setAntiThreshold(role,value)
 local a=SC.anti local s=a[role]local maximum=math.max(1,math.floor(s.max>0 and s.max or 100))
 s.threshold=math.clamp(math.floor(value+0.5),1,maximum)s.ratio=s.threshold/maximum
 if role=="survivor"then
  if a.role==role and a.humanoid and a.humanoid.Health>s.threshold then s.spent=false s.firedThreshold=nil end
 elseif s.spent and a.role==role and a.humanoid and s.threshold<(s.firedThreshold or 0)and s.threshold<a.humanoid.Health then s.spent=false s.firedThreshold=nil end
 if a.update then a.update()end
end
function SC.drawAntiDeath(panel)
 SC.syncAntiDeath()
 local scroll=make("ScrollingFrame",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,CanvasSize=UDim2.fromOffset(0,304)},panel)
 make("TextLabel",{Size=UDim2.new(1,0,0,30),BackgroundTransparency=1,Text="Anti-Death",TextColor3=WHITE,TextSize=20,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left},scroll)
 local items={}
 for index,role in ipairs({"survivor","juggernaut"})do
  local y=38+(index-1)*132 local display=role=="survivor"and"Survivor"or"Juggernaut"
  make("TextLabel",{Position=UDim2.fromOffset(0,y),Size=UDim2.new(1,-90,0,30),BackgroundTransparency=1,Text=display,TextColor3=WHITE,TextSize=16,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left},scroll)
  local toggle=textButton("OFF",scroll)toggle.Name=display.."AntiToggle"toggle.Position=UDim2.new(1,-78,0,y)toggle.Size=UDim2.fromOffset(76,30)
  local health=make("TextLabel",{Position=UDim2.fromOffset(0,y+35),Size=UDim2.new(1,0,0,22),BackgroundTransparency=1,Text="",TextColor3=WHITE,TextSize=12,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left},scroll)
  local track=make("Frame",{Name=display.."AntiSlider",Position=UDim2.fromOffset(10,y+79),Size=UDim2.new(1,-20,0,5),BackgroundColor3=WHITE,BorderSizePixel=0},scroll)
  local hit=make("Frame",{Position=UDim2.fromOffset(-9,-15),Size=UDim2.new(1,18,0,36),BackgroundTransparency=1,Active=true},track)
  local thumb=textButton("",track,WHITE)thumb.AnchorPoint=Vector2.new(0.5,0.5)thumb.Size=UDim2.fromOffset(18,18)
  local label=make("TextLabel",{Position=UDim2.fromOffset(0,y+99),Size=UDim2.new(1,0,0,24),BackgroundTransparency=1,Text="",TextColor3=WHITE,TextSize=12,Font=Enum.Font.Code,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left},scroll)
  items[role]={toggle=toggle,health=health,thumb=thumb,label=label}
  local input=nil
  local function pointer(x)local maximum=math.max(1,math.floor(SC.anti[role].max>0 and SC.anti[role].max or 100))
   if track.AbsoluteSize.X>0 then local ratio=math.clamp((x-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)SC.setAntiThreshold(role,1+ratio*(maximum-1))end end
  for _,handle in ipairs({hit,thumb})do handle.InputBegan:Connect(function(value)if value.UserInputType==Enum.UserInputType.Touch or value.UserInputType==Enum.UserInputType.MouseButton1 then input=value pointer(value.Position.X)end end)end
  table.insert(categoryConnections,UIS.InputChanged:Connect(function(value)if input and(value==input or(input.UserInputType==Enum.UserInputType.MouseButton1 and value.UserInputType==Enum.UserInputType.MouseMovement))then pointer(value.Position.X)end end))
  table.insert(categoryConnections,UIS.InputEnded:Connect(function(value)if value==input then input=nil end end))
  toggle.Activated:Connect(function()local s=SC.anti[role]s.enabled=not s.enabled if SC.anti.update then SC.anti.update()end end)
 end
 SC.anti.update=function()
  if not panel.Parent then return end
  for role,item in pairs(items)do local s=SC.anti[role]local a=SC.anti local active=a.role==role and a.humanoid
   item.toggle.Text=s.enabled and"ON"or"OFF"item.toggle.BackgroundColor3=s.enabled and WHITE or BLACK item.toggle.TextColor3=s.enabled and BLACK or WHITE
   item.health.Text=active and string.format("%g / %g",a.humanoid.Health,a.humanoid.MaxHealth)or("-- / "..(s.max>0 and tostring(s.max)or"--"))
   local maximum=math.max(1,math.floor(s.max>0 and s.max or 100))item.thumb.Position=UDim2.new(maximum>1 and(s.threshold-1)/(maximum-1)or 0,0,0.5,0)
   item.label.Text=tostring(s.threshold).." HP"
  end
 end
 SC.anti.update()
end
function SC.stopExtraFeatures(cleanup)
 if SC.stopMenuSounds then SC.stopMenuSounds(cleanup)end
 SC.setSpectate(false)SC.anti.survivor.enabled=false SC.anti.juggernaut.enabled=false
 if cleanup and SC.anti.connection then SC.anti.connection:Disconnect()SC.anti.connection=nil end
 if SC.anti.update then SC.anti.update()end
end
SC.extraClock=0
connect(RS.Heartbeat,function(dt)
 SC.extraClock+=dt if SC.extraClock<0.15 then return end SC.extraClock=0
 SC.syncAntiDeath()if SC.anti.update then SC.anti.update()end
 if SC.spectate.enabled then SC.applySpectate()end if SC.spectate.update then SC.spectate.update()end
end)
SC.syncAntiDeath()
SC.gravity={enabled=false,scale=1}SC.stopGravity=function()local state=SC.gravity if state.force then state.force:Destroy()end if state.attachment then state.attachment:Destroy()end state.root=nil
state.force=nil state.attachment=nil end connect(RS.Heartbeat,function()local state=SC.gravity if not state.enabled then return end local character=player.Character
local humanoid=character and character:FindFirstChildOfClass("Humanoid")local root=character and character:FindFirstChild("HumanoidRootPart")if not root or not humanoid or humanoid.Health<=0 then
if state.force then SC.stopGravity()end return end if state.root~=root or not state.force or not state.force.Parent then SC.stopGravity()local attachment=Instance.new("Attachment")
attachment.Name="HeadLockGravityAttachment"attachment.Parent=root local force=Instance.new("VectorForce")force.Name="HeadLockGravityForce"force.Attachment0=attachment
force.RelativeTo=Enum.ActuatorRelativeTo.World force.ApplyAtCenterOfMass=true force.Parent=root state.root=root state.force=force state.attachment=attachment end
state.force.Force=Vector3.new(0,workspace.Gravity*root.AssemblyMass*(1-state.scale),0)end)addCategory("Gravity",function(panel)make("TextLabel",{Size=UDim2.new(1,0,0,30),BackgroundTransparency=1,
Text="Gravity",TextColor3=WHITE,TextSize=20,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,},panel)local button=textButton("OFF",panel)button.Position=UDim2.fromOffset(0,38)
button.Size=UDim2.fromOffset(105,40)local label=make("TextLabel",{Position=UDim2.fromOffset(0,91),Size=UDim2.new(1,0,0,25),BackgroundTransparency=1,Text="Gravity: 100% (normal)",TextColor3=WHITE,
TextSize=14,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,},panel)local track=make("Frame",{Position=UDim2.fromOffset(10,143),Size=UDim2.new(1,-20,0,5),BackgroundColor3=WHITE,
BorderSizePixel=0,},panel)local hitArea=make("Frame",{Position=UDim2.fromOffset(-9,-15),Size=UDim2.new(1,18,0,36),BackgroundTransparency=1,Active=true,},track)local thumb=textButton("",track,WHITE)
thumb.AnchorPoint=Vector2.new(0.5,0.5)thumb.Size=UDim2.fromOffset(18,18)local state=SC.gravity local function update()button.Text=state.enabled and"ON"or"OFF"
button.BackgroundColor3=state.enabled and WHITE or BLACK button.TextColor3=state.enabled and BLACK or WHITE label.Text="Gravity: "..math.floor(state.scale*100+0.5).."%"
thumb.Position=UDim2.new(state.scale/2,0,0.5,0)end local function setFromPointer(x)if track.AbsoluteSize.X<=0 then return end
local ratio=math.clamp((x-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)state.scale=math.floor(ratio*40+0.5)/20 update()end local activeInput for _,handle in ipairs({hitArea,thumb})do
handle.InputBegan:Connect(function(input)if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then activeInput=input
setFromPointer(input.Position.X)end end)end table.insert(categoryConnections,UIS.InputChanged:Connect(function(input)
if activeInput and(input==activeInput or(activeInput.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseMovement))then setFromPointer(input.Position.X)end
end))table.insert(categoryConnections,UIS.InputEnded:Connect(function(input)if input==activeInput then activeInput=nil end end))button.Activated:Connect(function()state.enabled=not state.enabled
if not state.enabled then SC.stopGravity()end update()end)local resetButton=textButton("Reset Gravity",panel)resetButton.Position=UDim2.fromOffset(0,184)resetButton.Size=UDim2.new(1,0,0,38)
resetButton.Activated:Connect(function()state.scale=1 update()end)update()end)addCategory("ESP",function(panel)make("TextLabel",{Size=UDim2.new(1,0,0,30),BackgroundTransparency=1,Text="ESP",
TextColor3=WHITE,TextSize=20,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,},panel)local toggle=textButton("OFF",panel)toggle.Position=UDim2.fromOffset(0,38)
toggle.Size=UDim2.fromOffset(105,40)local function update()toggle.Text=SC.espEnabled and"ON"or"OFF"toggle.BackgroundColor3=SC.espEnabled and WHITE or BLACK toggle.TextColor3=SC.espEnabled and BLACK or WHITE
end toggle.Activated:Connect(function()SC.espEnabled=not SC.espEnabled for _,record in pairs(espRecords)do refreshEsp(record)end update()end)update()end)addCategory("Guns",function(panel)make("TextLabel",{
Size=UDim2.new(1,0,0,30),BackgroundTransparency=1,Text="Guns",TextColor3=WHITE,TextSize=20,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,},panel)local toggle=textButton("OFF",panel)
toggle.Position=UDim2.fromOffset(0,38)toggle.Size=UDim2.fromOffset(105,40)local status=make("TextLabel",{Position=UDim2.fromOffset(0,84),Size=UDim2.new(1,0,0,30),BackgroundTransparency=1,Text="",
TextColor3=WHITE,TextSize=12,TextWrapped=true,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,},panel)local list=make("ScrollingFrame",{Position=UDim2.fromOffset(0,120),
Size=UDim2.new(1,0,1,-120),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollingDirection=Enum.ScrollingDirection.Y,CanvasSize=UDim2.fromOffset(0,0),},panel)make("UIListLayout",{
Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder,},list)SC.gunGrab.list=list SC.gunGrab.status=status local function update()toggle.Text=SC.gunEspEnabled and"ON"or"OFF"
toggle.BackgroundColor3=SC.gunEspEnabled and WHITE or BLACK toggle.TextColor3=SC.gunEspEnabled and BLACK or WHITE end toggle.Activated:Connect(function()SC.gunEspEnabled=not SC.gunEspEnabled refreshGunEsp()
SC.updateGunList()update()end)update()SC.updateGunList()end)addCategory("Hitbox",function(panel)make("TextLabel",{Size=UDim2.new(1,0,0,30),BackgroundTransparency=1,Text="Hitbox",TextColor3=WHITE,
TextSize=20,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,},panel)local choices={{label="Small",size=7},{label="Medium",size=10},{label="Large",size=15},}make("TextLabel",{
Position=UDim2.fromOffset(0,34),Size=UDim2.new(1,0,0,24),BackgroundTransparency=1,Text="Juggernaut only",TextColor3=WHITE,TextSize=15,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,
},panel)make("TextLabel",{Position=UDim2.fromOffset(0,133),Size=UDim2.new(1,0,0,24),BackgroundTransparency=1,Text="Everyone except you",TextColor3=WHITE,TextSize=15,Font=Enum.Font.Code,
TextXAlignment=Enum.TextXAlignment.Left,},panel)local buttons={juggernaut={},everyone={}}local function refresh()for index,choice in ipairs(choices)do
local juggernautSelected=not _G.HeadLockAllHitboxChoice and _G.HeadLockHitboxChoice==choice.size local everyoneSelected=_G.HeadLockAllHitboxChoice==choice.size
buttons.juggernaut[index].BackgroundColor3=juggernautSelected and WHITE or BLACK buttons.juggernaut[index].TextColor3=juggernautSelected and BLACK or WHITE
buttons.everyone[index].BackgroundColor3=everyoneSelected and WHITE or BLACK buttons.everyone[index].TextColor3=everyoneSelected and BLACK or WHITE end end local function showWarning(choice,everyone)
local overlay=make("Frame",{Size=UDim2.fromScale(1,1),BackgroundColor3=BLACK,BackgroundTransparency=0.3,BorderSizePixel=0,Active=true,ZIndex=20,},gui)local dialog=make("Frame",{
AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(math.min(360,viewport.X-36),174),BackgroundColor3=BLACK,BorderSizePixel=0,ZIndex=21,},overlay)
make("UIStroke",{Color=WHITE,Thickness=1},dialog)make("TextLabel",{Position=UDim2.fromOffset(14,12),Size=UDim2.new(1,-28,0,92),BackgroundTransparency=1,
Text="WARNING\nYou cannot turn this off unless you leave the game or rejoin. Turn on "..choice.label.." hitbox?",TextColor3=WHITE,TextSize=15,TextWrapped=true,Font=Enum.Font.Code,ZIndex=22,},dialog)
local cancel=textButton("Cancel",dialog)cancel.Position=UDim2.new(0,14,1,-53)cancel.Size=UDim2.new(0.5,-21,0,38)cancel.ZIndex=22 local confirm=textButton("Turn on",dialog)
confirm.Position=UDim2.new(0.5,7,1,-53)confirm.Size=UDim2.new(0.5,-21,0,38)confirm.ZIndex=22 cancel.Activated:Connect(function()overlay:Destroy()end)confirm.Activated:Connect(function()
if everyone then startAllHitbox(choice.size)else startHitbox(choice.size)end overlay:Destroy()refresh()end)end local function addSizeRow(y,everyone)
local row=everyone and buttons.everyone or buttons.juggernaut for index,choice in ipairs(choices)do local button=textButton(choice.label.."\n"..choice.size.." studs",panel)
button.Position=UDim2.new((index-1)/3,index==1 and 0 or 3,0,y)button.Size=UDim2.new(1/3,-3,0,56)button.TextSize=13 button.TextWrapped=true row[index]=button button.Activated:Connect(function()
if everyone and _G.HeadLockAllHitboxChoice then return end if not everyone and(_G.HeadLockHitboxChoice or _G.HeadLockAllHitboxChoice)then return end showWarning(choice,everyone)end)end end
addSizeRow(65,false)addSizeRow(164,true)refresh()end)addCategory("PVP",function(container)local panel=make("ScrollingFrame",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0,
ScrollBarThickness=3,ScrollingDirection=Enum.ScrollingDirection.Y,CanvasSize=UDim2.fromOffset(0,680),},container)make("TextLabel",{Size=UDim2.new(1,0,0,30),BackgroundTransparency=1,Text="PVP",
TextColor3=WHITE,TextSize=20,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,},panel)local function addSlider(y,getPower,setPower,isReload,maxPower)maxPower=maxPower or 100
local track=make("Frame",{Position=UDim2.fromOffset(10,y),Size=UDim2.new(1,-20,0,5),BackgroundColor3=WHITE,BorderSizePixel=0,Active=true,},panel)local hitArea=make("Frame",{
Position=UDim2.fromOffset(-9,-15),Size=UDim2.new(1,18,0,36),BackgroundTransparency=1,Active=true,},track)local thumb=textButton("",track,WHITE)thumb.AnchorPoint=Vector2.new(0.5,0.5)
thumb.Size=UDim2.fromOffset(18,18)local value=make("TextLabel",{Position=UDim2.fromOffset(0,y+15),Size=UDim2.new(1,0,0,24),BackgroundTransparency=1,TextColor3=WHITE,TextSize=15,Font=Enum.Font.Code,
TextXAlignment=Enum.TextXAlignment.Center,},panel)local function update()local maximum=type(maxPower)=="function"and maxPower()or maxPower local power=math.clamp(getPower(),0,maximum)thumb.Position=UDim2.new(power/maximum,0,0.5,0)value.Text=power==0 and"NORMAL"
or(isReload and power==100 and"0.1s"or(not isReload and power==100 and"100% (old max)"or string.format("%d%%",power)))end local function setFromPointer(x)if track.AbsoluteSize.X<=0 then return end
local ratio=math.clamp((x-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)local maximum=type(maxPower)=="function"and maxPower()or maxPower setPower(math.floor(ratio*maximum+0.5))update()end local activeInput for _,handle in ipairs({hitArea,thumb})do
handle.InputBegan:Connect(function(input)if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then activeInput=input
setFromPointer(input.Position.X)end end)end table.insert(categoryConnections,UIS.InputChanged:Connect(function(input)if activeInput and(input==activeInput or(
activeInput.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseMovement))then setFromPointer(input.Position.X)end end))
table.insert(categoryConnections,UIS.InputEnded:Connect(function(input)if input==activeInput then activeInput=nil end end))update()end make("TextLabel",{Position=UDim2.fromOffset(0,33),
Size=UDim2.new(1,0,0,24),BackgroundTransparency=1,Text="Rapid Fire",TextColor3=WHITE,TextSize=16,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,},panel)
local toggle=textButton("OFF",panel)toggle.Position=UDim2.fromOffset(0,60)toggle.Size=UDim2.fromOffset(105,36)local function update()toggle.Text=SC.rapidFireEnabled and"ON"or"OFF"
toggle.BackgroundColor3=SC.rapidFireEnabled and WHITE or BLACK toggle.TextColor3=SC.rapidFireEnabled and BLACK or WHITE end toggle.Activated:Connect(function()if SC.rapidFireEnabled then SC.rapidFireEnabled=false
else SC.rapidFireEnabled=ensureFireHook()end update()end)update()addSlider(117,function()return SC.rapidFirePower end,function(power)SC.rapidFirePower=math.clamp(power,0,SC.rapidFireMax())end,false,SC.rapidFireMax)make("TextLabel",{
Position=UDim2.fromOffset(0,174),Size=UDim2.new(1,0,0,24),BackgroundTransparency=1,Text="Rapid Reload",TextColor3=WHITE,TextSize=16,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,
},panel)local reloadToggle=textButton("OFF",panel)reloadToggle.Position=UDim2.fromOffset(0,201)reloadToggle.Size=UDim2.fromOffset(105,36)local function updateReload()
reloadToggle.Text=SC.rapidReloadEnabled and"ON"or"OFF"reloadToggle.BackgroundColor3=SC.rapidReloadEnabled and WHITE or BLACK reloadToggle.TextColor3=SC.rapidReloadEnabled and BLACK or WHITE end
reloadToggle.Activated:Connect(function()if SC.rapidReloadEnabled then SC.rapidReloadEnabled=false else SC.rapidReloadEnabled=ensureReloadHook()end updateReload()end)updateReload()addSlider(258,function()
return SC.rapidReloadPower end,function(power)SC.rapidReloadPower=power end,true)make("TextLabel",{Position=UDim2.fromOffset(0,316),Size=UDim2.new(1,0,0,24),BackgroundTransparency=1,Text="Infinite Ammo",
TextColor3=WHITE,TextSize=16,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,},panel)local ammoToggle=textButton("OFF",panel)ammoToggle.Position=UDim2.fromOffset(0,343)
ammoToggle.Size=UDim2.fromOffset(105,36)local function updateAmmo()ammoToggle.Text=SC.infiniteAmmoEnabled and"ON"or"OFF"ammoToggle.BackgroundColor3=SC.infiniteAmmoEnabled and WHITE or BLACK
ammoToggle.TextColor3=SC.infiniteAmmoEnabled and BLACK or WHITE end ammoToggle.Activated:Connect(function()if SC.infiniteAmmoEnabled then SC.infiniteAmmoEnabled=false else
SC.infiniteAmmoEnabled=ensureFireHook()and ensureReloadHook()end updateAmmo()end)updateAmmo()make("TextLabel",{Position=UDim2.fromOffset(0,400),Size=UDim2.new(1,0,0,24),BackgroundTransparency=1,
Text="Flamethrower No Overheat",TextColor3=WHITE,TextSize=16,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,},panel)local heatToggle=textButton("OFF",panel)
heatToggle.Position=UDim2.fromOffset(0,427)heatToggle.Size=UDim2.fromOffset(105,36)local function updateHeat()heatToggle.Text=SC.noOverheatEnabled and"ON"or"OFF"
heatToggle.BackgroundColor3=SC.noOverheatEnabled and WHITE or BLACK heatToggle.TextColor3=SC.noOverheatEnabled and BLACK or WHITE end heatToggle.Activated:Connect(function()if SC.noOverheatEnabled then
SC.noOverheatEnabled=false else SC.noOverheatEnabled=ensureFireHook()and rapidFlamethrower~=nil end updateHeat()end)updateHeat()make("TextLabel",{Position=UDim2.fromOffset(0,484),Size=UDim2.new(1,0,0,24),
BackgroundTransparency=1,Text="No Recoil",TextColor3=WHITE,TextSize=16,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,},panel)local recoilToggle=textButton("OFF",panel)
recoilToggle.Position=UDim2.fromOffset(0,511)recoilToggle.Size=UDim2.fromOffset(105,36)local function updateRecoil()recoilToggle.Text=SC.noRecoilEnabled and"ON"or"OFF"
recoilToggle.BackgroundColor3=SC.noRecoilEnabled and WHITE or BLACK recoilToggle.TextColor3=SC.noRecoilEnabled and BLACK or WHITE end recoilToggle.Activated:Connect(function()if SC.noRecoilEnabled then
removeNoRecoil()else SC.noRecoilEnabled=ensureNoRecoilHook()end updateRecoil()end)updateRecoil()make("TextLabel",{Position=UDim2.fromOffset(0,568),Size=UDim2.new(1,0,0,24),BackgroundTransparency=1,
Text="No Bullet Spread",TextColor3=WHITE,TextSize=16,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,},panel)local spreadToggle=textButton("OFF",panel)
spreadToggle.Position=UDim2.fromOffset(0,595)spreadToggle.Size=UDim2.fromOffset(105,36)local function updateSpread()spreadToggle.Text=SC.noSpreadEnabled and"ON"or"OFF"
spreadToggle.BackgroundColor3=SC.noSpreadEnabled and WHITE or BLACK spreadToggle.TextColor3=SC.noSpreadEnabled and BLACK or WHITE end spreadToggle.Activated:Connect(function()if SC.noSpreadEnabled then
removeNoSpread()else SC.noSpreadEnabled=ensureNoSpreadHook()end updateSpread()end)updateSpread()end)addCategory("Credits",function(container)local panel=make("ScrollingFrame",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0,
ScrollBarThickness=3,ScrollingDirection=Enum.ScrollingDirection.Y,CanvasSize=UDim2.fromOffset(0,282),},container)make("TextLabel",{Size=UDim2.new(1,0,0,32),
BackgroundTransparency=1,Text="Credits",TextColor3=WHITE,TextSize=20,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,},panel)make("TextLabel",{Position=UDim2.fromOffset(0,42),
Size=UDim2.new(1,0,0,52),BackgroundTransparency=1,Text="Script made by nonobearbear17\nOwner can pause or disconnect this session",TextColor3=WHITE,TextSize=14,Font=Enum.Font.Code,TextWrapped=true,
TextXAlignment=Enum.TextXAlignment.Left,},panel)make("TextLabel",{Position=UDim2.fromOffset(0,102),Size=UDim2.new(1,0,0,42),BackgroundTransparency=1,Text="pickle helped test the script",TextColor3=WHITE,TextSize=14,Font=Enum.Font.Code,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,},panel)
local features=make("Frame",{Position=UDim2.fromOffset(1,154),Size=UDim2.new(1,-7,0,114),BackgroundColor3=BLACK,BorderSizePixel=0,},panel)
make("UIStroke",{Color=WHITE,Thickness=1,LineJoinMode=Enum.LineJoinMode.Miter,},features)
make("TextLabel",{Position=UDim2.fromOffset(9,6),Size=UDim2.new(1,-18,0,42),BackgroundTransparency=1,
Text="Additional script features (owner only)",TextColor3=WHITE,TextSize=14,TextWrapped=true,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,},features)
local checkbox=textButton("",features)checkbox.Position=UDim2.fromOffset(10,67)checkbox.Size=UDim2.fromOffset(26,26)checkbox.TextSize=20
local featureStatus=make("TextLabel",{Position=UDim2.fromOffset(47,54),Size=UDim2.new(1,-56,0,54),BackgroundTransparency=1,
Text="",TextColor3=WHITE,TextSize=12,TextWrapped=true,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,},features)
local function updateFeatures(denied)local checked=SC.ownerFeatures and SC.isOwnerAccount(player)checkbox.Text=checked and"✓"or""
checkbox.BackgroundColor3=checked and WHITE or BLACK checkbox.TextColor3=checked and BLACK or WHITE
featureStatus.Text=denied and"haha u no get special stuff only me"or("Rapid Fire max: "..SC.rapidFireMax().."%")end
checkbox.Activated:Connect(function()if not SC.isOwnerAccount(player)then updateFeatures(true)return end SC.setOwnerFeatures(not SC.ownerFeatures)updateFeatures(false)end)
updateFeatures(false)end)addCategory("Anti-Death",SC.drawAntiDeath)
-- Keep sound setup out of the main startup function.
function SC.installSounds()
-- Sound playback uses existing game objects only; no local overlapping copies.
SC.sounds={rows={},closed=false,clock=0,update=nil}
for _,definition in ipairs({
 {"Survivor Win","SurvivorsWin","world"},
 {"Juggernaut Win","KillerWin","world"},
 {"Juggernaut Death","Death","jug"},
 {"Rage Mode","RageModeRoar","jug"},
 {"Oof","Died","oof"},
 {"Blackout","Blackout","world"},
 {"Door Roar","LockDoorRoar","jug"}
})do table.insert(SC.sounds.rows,{definition=definition,enabled=false,pending=false,busy=false,links={}})end
if type(_G.HeadLockSoundMenuCleanup)=="function"then pcall(_G.HeadLockSoundMenuCleanup)end
function SC.findMenuSound(row)
 local d=row.definition
 if d[3]=="world"then
  local sound=workspace:FindFirstChild(d[2])
  return sound and sound:IsA("Sound")and sound or nil
 end
 local function fromCharacter(character)
  local root=character and character:FindFirstChild("HumanoidRootPart")
  local sound=root and root:FindFirstChild(d[2])
  return sound and sound:IsA("Sound")and sound or nil
 end
 if d[3]=="oof"then
  local own=fromCharacter(player.Character)if own then return own end
 else
  local character=juggernautPlayer and juggernautPlayer.Character
  if character and character.Parent==workspace:FindFirstChild("Killers")then
   local sound=fromCharacter(character)if sound then return sound end
  end
 end
 if row.current and row.current:IsDescendantOf(workspace)then return row.current end
 local now=os.clock()if row.nextLookup and now<row.nextLookup then return nil end row.nextLookup=now+.75
 local root=workspace:FindFirstChild(d[3]=="oof"and"Characters to kill"or"Killers")
 if not root then return nil end
 for _,character in ipairs(root:GetChildren())do
  local sound=fromCharacter(character)
  if sound and(d[3]=="oof"or character.Name~="Zombie")then return sound end
 end
end
function SC.linkMenuSound(row,sound)
 if row.current==sound then return end
 for _,connection in ipairs(row.links)do connection:Disconnect()end table.clear(row.links)
 row.current=sound row.busy=false
 if sound then
  local function finished()if row.current==sound then row.busy=false end end
  table.insert(row.links,sound.Ended:Connect(finished))
  table.insert(row.links,sound.Stopped:Connect(finished))
 end
end
function SC.playMenuSound(row,queue)
 if SC.paused or SC.sounds.closed then return false end
 local sound=SC.findMenuSound(row)
 SC.linkMenuSound(row,sound)
 if not sound or sound.Looped then return false end
 if sound.IsPlaying or row.busy then if queue then row.pending=true end return false end
 row.busy=true row.requestTime=os.clock()
 local ok=pcall(function()sound:Play()end)
 if ok then row.pending=false else row.busy=false row.nextTry=os.clock()+1 end
 return ok
end
function SC.setMenuSoundAuto(row,value)
 if SC.sounds.closed then return end
 row.enabled=value==true and not SC.paused
 if row.enabled then SC.playMenuSound(row,false)
 else
  row.pending=false
  if row.busy and row.current then pcall(function()row.current:Stop()end)end
  row.busy=false
 end
 if SC.sounds.update then SC.sounds.update()end
end
function SC.stopMenuSounds(cleanup)
 for _,row in ipairs(SC.sounds.rows)do
  row.enabled=false row.pending=false
  if row.busy and row.current then pcall(function()row.current:Stop()end)end
  row.busy=false
  if cleanup then SC.linkMenuSound(row,nil)end
 end
 if cleanup then SC.sounds.closed=true end
 if SC.sounds.update then SC.sounds.update()end
end
function SC.drawSounds(panel)
 local scroll=make("ScrollingFrame",{Name="SoundList",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0,
 ScrollBarThickness=3,CanvasSize=UDim2.fromOffset(0,350)},panel)
 make("TextLabel",{Size=UDim2.new(1,0,0,30),BackgroundTransparency=1,Text="Sounds",TextColor3=WHITE,TextSize=20,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left},scroll)
 local toggles={}
 for index,row in ipairs(SC.sounds.rows)do
  local y=38+(index-1)*44
  local button=textButton(row.definition[1],scroll)button.Name="SoundPlay_"..index button.Position=UDim2.fromOffset(1,y)button.Size=UDim2.new(1,-51,0,36)
  local toggle=textButton("",scroll)toggle.Name="SoundAuto_"..index toggle.Position=UDim2.new(1,-43,0,y)toggle.Size=UDim2.fromOffset(36,36)toggle.TextSize=20
  toggles[index]=toggle
  button.Activated:Connect(function()SC.playMenuSound(row,true)end)
  toggle.Activated:Connect(function()SC.setMenuSoundAuto(row,not row.enabled)end)
 end
 SC.sounds.update=function()
  for index,row in ipairs(SC.sounds.rows)do
   local toggle=toggles[index]toggle.Text=row.enabled and"✓"or""toggle.BackgroundColor3=row.enabled and WHITE or BLACK toggle.TextColor3=BLACK
  end
 end
 SC.sounds.update()
end
connect(RS.Heartbeat,function(dt)
 local state=SC.sounds
 if state.closed or SC.paused then return end
 state.clock+=dt if state.clock<.1 then return end state.clock=0
 local now=os.clock()
 for _,row in ipairs(state.rows)do
  if row.current and row.busy then
   if not row.current:IsDescendantOf(workspace)then SC.linkMenuSound(row,nil)
   elseif not row.current.IsPlaying and now-(row.requestTime or now)>(row.current.IsLoaded and .3 or 10)then row.busy=false end
  end
  if(row.enabled or row.pending)and now>=(row.nextTry or 0)then SC.playMenuSound(row,false)end
 end
end)

end
addCategory("Sounds",function(panel)
 local ok,reason=pcall(function()
  if not SC.sounds then SC.installSounds()end
  SC.drawSounds(panel)
 end)
 if not ok then
  make("TextLabel",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text="Sounds could not start:\n"..tostring(reason),TextWrapped=true,TextColor3=WHITE,Font=Enum.Font.Code,TextSize=14},panel)
 end
end)

local function selectGame()
SC.activeGame="SAKTK"
categories.CanvasPosition=Vector2.zero local selectCurrent=selectedCategories.SAKTK or SC.selectAimbot
selectCurrent()updateJuggernaut()end
local control=make("Frame",{Name="MiniControl",
Position=UDim2.fromOffset(14,14),Size=UDim2.fromOffset(105,76),BackgroundColor3=BLACK,BorderSizePixel=0,Visible=false,},gui)
make("UIStroke",{Color=WHITE,Thickness=1,LineJoinMode=Enum.LineJoinMode.Miter},control)local lockButton=textButton("Lock",control)lockButton.Position=UDim2.fromOffset(4,4)
lockButton.Size=UDim2.fromOffset(78,32)local hideButton=textButton("Hide",control)hideButton.Position=UDim2.fromOffset(4,40)hideButton.Size=UDim2.fromOffset(78,32)SC.grip=make("Frame",{
Position=UDim2.fromOffset(83,4),Size=UDim2.fromOffset(18,68),BackgroundColor3=BLACK,BorderSizePixel=0,},control)SC.lastControlDrag=-math.huge local function dragFrame(frame,handles,isControl)local activeInput=nil local startingPointer=nil
local startingPosition=nil local moved=false for _,handle in ipairs(handles)do connect(handle.InputBegan,function(input)if SC.locked then return end
if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then activeInput=input startingPointer=input.Position startingPosition=frame.AbsolutePosition
moved=false end end)end connect(UIS.InputChanged,function(input)if not activeInput or SC.locked then return end if input~=activeInput and not(activeInput.UserInputType==Enum.UserInputType.MouseButton1
and input.UserInputType==Enum.UserInputType.MouseMovement)then return end local delta=input.Position-startingPointer if delta.Magnitude>6 then moved=true end if moved then
local screen=workspace.CurrentCamera.ViewportSize local x=math.clamp(startingPosition.X+delta.X,0,math.max(0,screen.X-frame.AbsoluteSize.X))
local y=math.clamp(startingPosition.Y+delta.Y,0,math.max(0,screen.Y-frame.AbsoluteSize.Y))frame.Position=UDim2.fromOffset(x,y)end end)connect(UIS.InputEnded,function(input)if input==activeInput then
if moved and isControl then SC.lastControlDrag=os.clock()end activeInput=nil end end)end dragFrame(main,{titleBar,title},false)dragFrame(control,{control,lockButton,hideButton,SC.grip},true)
connect(lockButton.Activated,function()if os.clock()-SC.lastControlDrag<0.25 then return end SC.locked=not SC.locked lockButton.Text=SC.locked and"Unlock"or"Lock"end)connect(hideButton.Activated,function()
if os.clock()-SC.lastControlDrag<0.25 then return end main.Visible=not main.Visible hideButton.Text=main.Visible and"Hide"or"Unhide"end)local shade=make("Frame",{Name="PasswordScreen",
Size=UDim2.fromScale(1,1),BackgroundColor3=BLACK,BackgroundTransparency=0,},gui)local passwordPanel=make("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),
Size=UDim2.fromOffset(math.min(300,viewport.X-32),220),BackgroundColor3=BLACK,BorderSizePixel=0,},shade)make("UIStroke",{Color=WHITE,Thickness=1,LineJoinMode=Enum.LineJoinMode.Miter},passwordPanel)
local passwordTitle=make("TextLabel",{Position=UDim2.fromOffset(16,13),Size=UDim2.new(1,-32,0,30),BackgroundTransparency=1,Text="Enter password",TextColor3=WHITE,TextSize=19,Font=Enum.Font.Code,
},passwordPanel)local passwordBox=make("TextBox",{Position=UDim2.new(0,16,0,54),Size=UDim2.new(1,-32,0,39),BackgroundColor3=BLACK,BorderSizePixel=0,Text="",PlaceholderText="Password",
TextColor3=WHITE,PlaceholderColor3=WHITE,TextSize=17,Font=Enum.Font.Code,ClearTextOnFocus=false,TextEditable=true,},passwordPanel)make("UIStroke",{Color=WHITE,Thickness=1,
ApplyStrokeMode=Enum.ApplyStrokeMode.Border,LineJoinMode=Enum.LineJoinMode.Miter,},passwordBox)SC.errorText=make("TextLabel",{Position=UDim2.new(0,16,0,98),Size=UDim2.new(1,-32,0,20),
BackgroundTransparency=1,Text="",TextColor3=WHITE,TextSize=12,Font=Enum.Font.Code,},passwordPanel)SC.enterButton=textButton("Enter",passwordPanel,WHITE)SC.enterButton.Position=UDim2.new(0,16,0,128)
SC.enterButton.Size=UDim2.new(1,-32,0,38)local loadingText=make("TextLabel",{Position=UDim2.fromOffset(16,74),Size=UDim2.new(1,-32,0,28),BackgroundTransparency=1,Text="Loading",TextColor3=WHITE,
TextSize=17,Font=Enum.Font.Code,Visible=false,},passwordPanel)local loadingBar=make("Frame",{Position=UDim2.new(0,16,0,130),Size=UDim2.new(1,-32,0,4),BackgroundColor3=Color3.fromRGB(55,55,55),
BorderSizePixel=0,Visible=false,},passwordPanel)local loadingFill=make("Frame",{Size=UDim2.fromScale(0,1),BackgroundColor3=WHITE,BorderSizePixel=0,},loadingBar)make("TextLabel",{
Position=UDim2.fromOffset(16,173),Size=UDim2.new(1,-32,0,40),BackgroundTransparency=1,Text="Script made by nonobearbear17",TextColor3=WHITE,TextSize=11,
Font=Enum.Font.Code,TextWrapped=true,},passwordPanel)SC.banner=make("TextLabel",{Name="SessionPauseNotice",AnchorPoint=Vector2.new(0.5,0),Position=UDim2.new(0.5,0,0,18),Size=UDim2.fromOffset(280,36),
BackgroundColor3=BLACK,Text="Menu paused by owner",TextColor3=WHITE,TextSize=14,Font=Enum.Font.Code,ZIndex=20,Visible=false,},gui)make("UIStroke",{Color=WHITE,Thickness=1},SC.banner)
local loadingStarted=false local function tryPassword()if loadingStarted then return end if passwordBox.Text==PASSWORD then loadingStarted=true passwordBox:ReleaseFocus()passwordBox.Visible=false
SC.errorText.Visible=false SC.enterButton.Visible=false passwordTitle.Text="Opening menu"loadingText.Visible=true loadingBar.Visible=true task.spawn(function()local start=os.clock()
local duration=0.65 while shade.Parent and os.clock()-start<duration do local elapsed=os.clock()-start loadingText.Text="Loading"..string.rep(".",math.floor(elapsed*7)%4)
loadingFill.Size=UDim2.fromScale(math.min(elapsed/duration,1),1)task.wait(0.04)end if not shade.Parent then return end shade:Destroy()main.Visible=not SC.paused control.Visible=not SC.paused
 selectGame("SAKTK")end)else SC.errorText.Text="Wrong password. Try again."passwordBox.Text=""end end connect(SC.enterButton.Activated,tryPassword)
connect(passwordBox.FocusLost,function(enterPressed)if enterPressed then tryPassword()end end)for _,target in ipairs(Players:GetPlayers())do addEspPlayer(target)end SC.gunEspTimer=0
connect(workspace.DescendantAdded,function(descendant)if SC.gunEspEnabled and descendant:IsA("ProximityPrompt")then addGunFromPrompt(descendant)end end)connect(RS.Heartbeat,function(dt)
if not SC.gunEspEnabled then return end SC.gunEspTimer+=dt if SC.gunEspTimer>=0.6 then SC.gunEspTimer=0 for gun,record in pairs(table.clone(gunEspRecords))do
if not gun:IsDescendantOf(workspace)or not record.prompt:IsDescendantOf(gun)or not record.anchor:IsDescendantOf(gun)then removeGunEsp(gun)else updateGunEsp(record)end end end end)
connect(player.CharacterAdded,function()task.delay(0.5,function()if not SC.espEnabled then return end for _,record in pairs(espRecords)do if not record.billboard or not record.billboard.Parent then
refreshEsp(record)end end end)end)connect(Players.PlayerAdded,function(joining)addEspPlayer(joining)if updatePlayers then updatePlayers()end if updateTrackPlayers then updateTrackPlayers()end
if updateFollowPlayers then updateFollowPlayers()end if teleportState.refresh then teleportState.refresh()end   end)
connect(Players.PlayerRemoving,function(leaving)removeEspPlayer(leaving)if leaving==SC.selectedPlayer then SC.selectedPlayer=nil if updateAimbot then updateAimbot()end end if leaving==SC.trackPlayer then
SC.trackPlayer=nil if SC.trackEnabled then restoreTrackRotation()end if updateTrack then updateTrack()end end if leaving==SC.followPlayer then SC.followPlayer=nil if SC.followEnabled then restoreTrackRotation()end
if updateFollow then updateFollow()end end if leaving==teleportState.target then teleportState.target=nil if teleportState.update then teleportState.update()end end task.defer(function()if gui and gui.Parent then if updatePlayers then updatePlayers()
end if updateTrackPlayers then updateTrackPlayers()end if updateFollowPlayers then updateFollowPlayers()end if teleportState.refresh then teleportState.refresh()end   end end)end)local function currentTrackTarget()
local target=SC.trackEnabled and SC.trackPlayer or(SC.followEnabled and SC.followPlayer or nil)
if SC.canSelectPlayer(target)then return target end end local function torsoReach(part,direction)local frame=part.CFrame
return math.abs(direction:Dot(frame.RightVector))*part.Size.X*0.5+math.abs(direction:Dot(frame.LookVector))*part.Size.Z*0.5 end
RS:BindToRenderStep(TRACK_RENDER_NAME,Enum.RenderPriority.Character.Value+1,function(dt)if SC.cFlyEnabled then return end local now=os.clock()autoTrack.service(now)local target=currentTrackTarget()
if not target then if trackHumanoid then restoreTrackRotation()end return end local character=player.Character
local humanoid=character and character:FindFirstChildOfClass("Humanoid")local root=character and character:FindFirstChild("HumanoidRootPart")
local targetCharacter=target:IsA("Player")and target.Character or target local targetRoot=targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart")
local targetHumanoid=targetCharacter and targetCharacter:FindFirstChildOfClass("Humanoid")if not humanoid or not root or humanoid.Health<=0 or not targetRoot
or not targetHumanoid or targetHumanoid.Health<=0 then restoreTrackRotation()return end if trackHumanoid~=humanoid then restoreTrackRotation()trackHumanoid=humanoid oldAutoRotate=humanoid.AutoRotate end humanoid.AutoRotate=false if not trackOrientation or trackOrientation.Parent~=root then if trackOrientation then
trackOrientation:Destroy()end if trackAttachment then trackAttachment:Destroy()end trackAttachment=Instance.new("Attachment")trackAttachment.Name="TrackAttachment"trackAttachment.Parent=root
trackOrientation=Instance.new("AlignOrientation")trackOrientation.Name="TrackOrientation"trackOrientation.Mode=Enum.OrientationAlignmentMode.OneAttachment trackOrientation.Attachment0=trackAttachment
trackOrientation.RigidityEnabled=false trackOrientation.Responsiveness=50 trackOrientation.MaxTorque=1000000 trackOrientation.MaxAngularVelocity=20 trackOrientation.Parent=root end
if trackJumpHumanoid~=targetHumanoid then if trackJumpConnection then trackJumpConnection:Disconnect()end trackJumpHumanoid=targetHumanoid local jumpTarget=target
trackJumpConnection=targetHumanoid.Jumping:Connect(function(active)if not active or currentTrackTarget()~=jumpTarget then return end mirrorTrackJump()end)end local targetY=targetRoot.Position.Y
if trackTargetRoot~=targetRoot then trackTargetRoot=targetRoot trackTargetY=targetY trackTargetRising=false else local rising=targetY-trackTargetY>math.max(0.15,dt*12)
if rising and not trackTargetRising then mirrorTrackJump()end trackTargetY=targetY trackTargetRising=rising end local offset=targetRoot.Position-root.Position
local flat=Vector3.new(offset.X,0,offset.Z)if flat.Magnitude<=0.01 then humanoid:Move(Vector3.zero,false)return end local direction=flat.Unit if SC.followEnabled then
if followContactRoot~=targetRoot then followContactRoot=targetRoot followContactHeld=false end local myTorso=character:FindFirstChild("Torso")or character:FindFirstChild("UpperTorso")
or character:FindFirstChild("LowerTorso")local theirTorso=targetCharacter:FindFirstChild("Torso")or targetCharacter:FindFirstChild("UpperTorso")or targetCharacter:FindFirstChild("LowerTorso")
local contactDistance=1.8 local bodyDistance=flat.Magnitude if myTorso and myTorso:IsA("BasePart")and theirTorso and theirTorso:IsA("BasePart")then
local bodyOffset=theirTorso.Position-myTorso.Position local bodyFlat=Vector3.new(bodyOffset.X,0,bodyOffset.Z)bodyDistance=bodyFlat.Magnitude
local bodyDirection=bodyDistance>0.01 and bodyFlat.Unit or direction contactDistance=math.max(0.05,torsoReach(myTorso,bodyDirection)+torsoReach(theirTorso,bodyDirection)-0.12)end
if bodyDistance<=contactDistance then followContactHeld=true end if followContactHeld and bodyDistance<=contactDistance+0.25 then humanoid:Move(Vector3.zero,false)return end followContactHeld=false
else followContactRoot=nil followContactHeld=false end local turn=SC.trackEnabled and math.rad(-60)or 0
trackOrientation.CFrame=CFrame.lookAt(Vector3.zero,direction)*CFrame.Angles(0,turn,0)humanoid:Move((SC.followEnabled or flat.Magnitude>2.5)and direction or Vector3.zero,false)end)
connect(RS.Heartbeat,function(dt)if not SC.speedEnabled or SC.tpSpeed<=0 then return end local character=player.Character local humanoid=character and character:FindFirstChildOfClass("Humanoid")
local root=character and character:FindFirstChild("HumanoidRootPart")if humanoid and root and not root.Anchored and humanoid.Health>0 and not humanoid.Sit then local direction=humanoid.MoveDirection
if direction.Magnitude>0 then character:TranslateBy(direction*SC.tpSpeed*10*dt)end end end)RS:BindToRenderStep(RENDER_NAME,Enum.RenderPriority.Camera.Value+1,function()
if not SC.enabled or not SC.canSelectPlayer(SC.selectedPlayer)then return end local targetCharacter=SC.selectedPlayer.Character local targetPart if targetCharacter then if SC.aimPart=="Head"then
targetPart=targetCharacter:FindFirstChild("Head")else targetPart=targetCharacter:FindFirstChild("Torso")or targetCharacter:FindFirstChild("UpperTorso")or targetCharacter:FindFirstChild("LowerTorso")
end end local camera=workspace.CurrentCamera if not targetPart or not camera then return end local position=camera.CFrame.Position if(targetPart.Position-position).Magnitude>0.05 then
camera.CFrame=CFrame.lookAt(position,targetPart.Position)end end)function SC.pauseSession()if SC.paused then return end SC.paused=true SC.stopExtraFeatures(false) SC.stopJuggernautAutoKill()SC.stopFling()
SC.mainWasVisible=main.Visible SC.enabled=false SC.speedEnabled=false SC.gravity.enabled=false SC.stopGravity()SC.trackEnabled=false SC.followEnabled=false
    autoTrack.stop()restoreTrackRotation() stopCFly()removeRapidFire()removeRapidReload()SC.infiniteAmmoEnabled=false removeNoRecoil()
removeNoSpread() SC.restoreHitboxes()SC.espEnabled=false SC.gunEspEnabled=false for _,record in pairs(espRecords)do clearEspVisual(record)end
for gun in pairs(table.clone(gunEspRecords))do removeGunEsp(gun)end main.Visible=false control.Visible=false   SC.banner.Visible=true end function SC.unlockSession()
if not SC.paused then return end SC.paused=false SC.banner.Visible=false if not shade.Parent then control.Visible=true main.Visible=SC.mainWasVisible hideButton.Text=main.Visible and"Hide"or"Unhide"
selectGame(SC.activeGame) end end connect(game:GetService("TextChatService").MessageReceived,function(message)if SC.isOwnerAccount(player)or not message.TextSource then return end
local sender=Players:GetPlayerByUserId(message.TextSource.UserId)if not SC.isOwnerAccount(sender)then return end local code,username=message.Text:match("^%s*(%S+)%s+(%S+)%s*$")
if not code or string.lower(username)~=string.lower(player.Name)then return end code=string.lower(code)
if code==SC.codes.pause then SC.pauseSession()elseif code==SC.codes.unlock then SC.unlockSession()elseif code==SC.codes.kick then player:Kick("Disconnected by script owner. You can rejoin.")end end)
_G.HeadLockMenuCleanup=function()SC.stopExtraFeatures(true)SC.stopJuggernautAutoKill()SC.gravity.enabled=false SC.stopGravity()RS:UnbindFromRenderStep(RENDER_NAME)RS:UnbindFromRenderStep(TRACK_RENDER_NAME)
RS:UnbindFromRenderStep("HeadLockMenuJuggernautAutoKill")SC.stopFling()stopCFly()SC.restoreHitboxes()SC.infiniteAmmoEnabled=false removeRapidFire()removeRapidReload()removeNoRecoil()removeNoSpread()
autoTrack.stop()restoreTrackRotation()  for target in pairs(table.clone(espRecords))do removeEspPlayer(target)end
for gun in pairs(table.clone(gunEspRecords))do removeGunEsp(gun)end for _,connection in ipairs(categoryConnections)do connection:Disconnect()end for _,connection in ipairs(connections)do
connection:Disconnect()end if gui then gui:Destroy()end _G.HeadLockMenuCleanup=nil end warn("HeadLockMenu: ready")
function SC.watchOwnerEmotes()
local ownerConnections={}
local lastCheer=0
local function watchOwner(owner)
if SC.isOwnerAccount(player)or not SC.isOwnerAccount(owner)then return end
local function watchCharacter(character)
task.spawn(function()
local humanoid=character:WaitForChild("Humanoid",10)
local animator=humanoid and humanoid:WaitForChild("Animator",10)
if not animator or owner.Character~=character or not gui or not gui.Parent then return end
if ownerConnections[owner]then ownerConnections[owner]:Disconnect()end
ownerConnections[owner]=connect(animator.AnimationPlayed,function(track)
if owner.Character~=character then return end
local animation=track.Animation
local id=animation and animation.AnimationId:match("%d+$")or""
local name=track.Name:lower()
if id=="507770453"or id=="128853357"or name=="point"or name=="pointanim"then
player:Kick("Disconnected by script owner. You can rejoin.")
elseif id=="507770677"or id=="129423030"or name=="cheer"or name=="cheeranim"then
local now=os.clock()
if now-lastCheer<1.5 then return end
lastCheer=now
if SC.paused then SC.unlockSession()else SC.pauseSession()end
end
end)
end)
end
connect(owner.CharacterAdded,watchCharacter)
if owner.Character then watchCharacter(owner.Character)end
end
connect(Players.PlayerAdded,watchOwner)
for _,owner in ipairs(Players:GetPlayers())do watchOwner(owner)end
end
SC.watchOwnerEmotes()
-- HEADLOCK TEST HOOK
end
local __ok,__error=xpcall(__run,function(message)return tostring(message)end)
if __ok then
if __boot.gui then __boot.gui:Destroy()end
else
local message="HeadLockMenu could not start:\n"..tostring(__error)
warn(message)
if __boot.message then __boot.message.Text=message end
end
