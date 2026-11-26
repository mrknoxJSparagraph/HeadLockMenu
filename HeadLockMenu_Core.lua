

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
SC.autoWin={enabled=false,role=nil,target=nil}
function SC.autoWinCombat()
 local aw=SC.autoWin
 if not aw.enabled or aw.role~="survivor" or not aw.target or SC.paused or SC.closing or not SC.ownerFeatures then return false end
 local c=aw.target.Character local h=c and c:FindFirstChildOfClass("Humanoid")
 return aw.target.Parent==Players and not aw.skipped[aw.target.UserId] and c and c.Parent==workspace:FindFirstChild("Killers") and h and h.Health>0
end
function SC.rapidFireMax()return SC.ownerFeatures and SC.isOwnerAccount(player)and 1000 or 200 end
function SC.setOwnerFeatures(value)
 SC.ownerFeatures=value==true and SC.isOwnerAccount(player)
 if not SC.ownerFeatures and SC.setAutoWin then SC.setAutoWin(false)end
 SC.rapidFirePower=math.clamp(SC.rapidFirePower,0,SC.rapidFireMax())
 if SC.refreshOwnerCategories then SC.refreshOwnerCategories()end
end
autoTrack.clearLock=function()if autoTrack.deathConnection then autoTrack.deathConnection:Disconnect()autoTrack.deathConnection=nil end autoTrack.lockedPlayer=nil autoTrack.lockedCharacter=nil
autoTrack.lockedHumanoid=nil end autoTrack.stop=function()autoTrack.mode=nil autoTrack.clearLock()table.clear(autoTrack.excluded)end local function mirrorTrackJump()
if SC.followEnabled and followContactHeld then return end if os.clock()-lastTrackJump<0.35 then return end local character=player.Character
local humanoid=character and character:FindFirstChildOfClass("Humanoid")local root=character and character:FindFirstChild("HumanoidRootPart")
if not humanoid or not root or root.Anchored or humanoid.Health<=0 or humanoid.Sit or not humanoid:GetStateEnabled(Enum.HumanoidStateType.Jumping)then return end local state=humanoid:GetState()
if state==Enum.HumanoidStateType.Jumping or state==Enum.HumanoidStateType.Freefall then return end lastTrackJump=os.clock()humanoid.Jump=true humanoid:ChangeState(Enum.HumanoidStateType.Jumping)end
local function restoreTrackRotation()followContactRoot=nil followContactHeld=false if trackJumpConnection then trackJumpConnection:Disconnect()trackJumpConnection=nil end trackJumpHumanoid=nil
trackTargetRoot=nil trackTargetY=nil trackTargetRising=false if trackOrientation then trackOrientation:Destroy()trackOrientation=nil end if trackAttachment then trackAttachment:Destroy()
trackAttachment=nil end if trackHumanoid and trackHumanoid.Parent then trackHumanoid.AutoRotate=oldAutoRotate trackHumanoid:Move(Vector3.zero,false)end trackHumanoid=nil oldAutoRotate=nil end
local function connect(signal,callback)local connection=signal:Connect(callback)table.insert(connections,connection)return connection end
if type(_G.HeadLockAntiFlingCleanup)=="function"then pcall(_G.HeadLockAntiFlingCleanup)end
SC.antiFling={enabled=false,modified={},lastCharacter=nil,safeFrame=nil,connection=nil,update=nil,updateCredits=nil}
function SC.restoreAntiFlingPlayer(target)
 local state=SC.antiFling local record=state.modified[target]if not record then return end
 for part,original in pairs(record)do if part.Parent then pcall(function()
  part.CanCollide=original.canCollide part.CustomPhysicalProperties=original.physical
 end)end end
 state.modified[target]=nil
end
function SC.restoreAntiFling()
 for target in pairs(SC.antiFling.modified)do SC.restoreAntiFlingPlayer(target)end
end
function SC.protectAntiFlingTarget(target,character)
 local state=SC.antiFling local record=state.modified[target]
 if not record then record={}state.modified[target]=record end
 for _,part in ipairs(character:GetDescendants())do if part:IsA("BasePart")then
  if not record[part]then record[part]={canCollide=part.CanCollide,physical=part.CustomPhysicalProperties}end
  pcall(function()
   part.CanCollide=false part.AssemblyAngularVelocity=Vector3.zero part.AssemblyLinearVelocity=Vector3.zero
   part.CustomPhysicalProperties=PhysicalProperties.new(0,0,0)
  end)
 end end
end
function SC.stepAntiFling()
 local state=SC.antiFling if not state.enabled or SC.closing then return end
 local active={}
 for _,target in ipairs(Players:GetPlayers())do if target~=player then
  local character=target.Character local root=character and character:FindFirstChild("HumanoidRootPart")
  if root and character:IsDescendantOf(workspace)and(root.AssemblyAngularVelocity.Magnitude>50 or root.AssemblyLinearVelocity.Magnitude>100)then
   active[target]=true SC.protectAntiFlingTarget(target,character)
  end
 end end
 for target in pairs(state.modified)do if not active[target]then SC.restoreAntiFlingPlayer(target)end end
 local character=player.Character
 if character~=state.lastCharacter then state.lastCharacter=character state.safeFrame=nil end
 local root=character and(character.PrimaryPart or character:FindFirstChild("HumanoidRootPart"))
 local humanoid=character and character:FindFirstChildOfClass("Humanoid")
 if not root or(humanoid and humanoid.Health<=0)then return end
 local linear=root.AssemblyLinearVelocity.Magnitude local angular=root.AssemblyAngularVelocity.Magnitude
 if linear<50 and angular<50 then state.safeFrame=root.CFrame
 elseif linear>250 or angular>250 then
  root.AssemblyAngularVelocity=Vector3.zero root.AssemblyLinearVelocity=Vector3.zero
  if state.safeFrame then root.CFrame=state.safeFrame end
 end
end
function SC.setAntiFling(value)
 local state=SC.antiFling value=value==true
 if state.enabled==value then return end
 state.enabled=value _G.HeadLockAntiFlingEnabled=value
 if value then
  state.lastCharacter=nil state.safeFrame=nil state.connection=RS.Heartbeat:Connect(SC.stepAntiFling)
 else
  if state.connection then state.connection:Disconnect()state.connection=nil end
  SC.restoreAntiFling()state.safeFrame=nil
 end
 if state.update then state.update()end if state.updateCredits then state.updateCredits()end
end
_G.HeadLockAntiFlingEnabled=false
local playerScripts=player:FindFirstChild("PlayerScripts")
local checksScript=playerScripts and playerScripts:FindFirstChild("Checks")
local originalChecksEnabled=checksScript and checksScript.Enabled
SC.wallClip={update=nil}
function SC.setWallClip(enabled)
 if checksScript and checksScript.Parent then checksScript.Enabled=enabled==true end
 if SC.wallClip.update then SC.wallClip.update()end
end
if checksScript then connect(checksScript:GetPropertyChangedSignal("Enabled"),function()if SC.wallClip.update then SC.wallClip.update()end end)end
SC.setWallClip(false)
local function startHitbox(size)if _G.HeadLockHitboxChoice then return end
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
if SC.autoWin.enabled then return end
if SC.removeWeaponCaptureHooks then SC.removeWeaponCaptureHooks()end
if rapidWeapon and rapidWeapon.fire==wrappedWeaponFire then rapidWeapon.fire=originalWeaponFire end if rapidFlamethrower and rapidFlamethrower.fire==wrappedFlamethrowerFire then
rapidFlamethrower.fire=originalFlamethrowerFire end rapidWeapon=nil originalWeaponFire=nil wrappedWeaponFire=nil rapidFlamethrower=nil originalFlamethrowerFire=nil wrappedFlamethrowerFire=nil end
local function refillIfEnabled(weapon)if (SC.infiniteAmmoEnabled or SC.autoWinCombat()) and weapon.instance and not weapon.stolen and type(weapon.refill)=="function"then weapon:refill()end end
local function clearFlamethrowerHeat(weapon,refreshGui)if SC.noOverheatEnabled and weapon.instance and not weapon.stolen then weapon.heat=0 if refreshGui and type(weapon.update_ammo_gui)=="function"then
weapon:update_ammo_gui()end end end local function rapidFireInterval(weapon,countFireAnimation)SC.rapidFirePower=math.clamp(SC.rapidFirePower,0,SC.rapidFireMax())
local power=SC.autoWinCombat() and 1000 or SC.rapidFirePower local animationDuration=0
local fireAnimation=countFireAnimation and weapon.animations and weapon.animations.Fire if fireAnimation then for _,step in ipairs(fireAnimation)do if type(step)=="number"and step>0 then
animationDuration+=step end end end local normalInterval=math.max(weapon.shoot_wait or 0.1,0.03)+animationDuration if power<=100 then
return normalInterval+(0.03-normalInterval)*power/100 end return 0.03/(1+(power-100)/100)end local function ensureFlamethrowerHook(weaponModule)if rapidFlamethrower then return true
end local flameScript=game:GetService("ReplicatedStorage"):WaitForChild("Weapon"):FindFirstChild("Flamethrower")if not flameScript then return false end local ok,flameModule=pcall(require,flameScript)
if not ok or type(flameModule)~="table"or type(flameModule.fire)~="function"or flameModule.fire==weaponModule.fire then return false end rapidFlamethrower=flameModule
originalFlamethrowerFire=flameModule.fire wrappedFlamethrowerFire=function(self,...)refillIfEnabled(self)clearFlamethrowerHeat(self)if not SC.rapidFireEnabled or SC.rapidFirePower==0 then
local results=table.pack(pcall(originalFlamethrowerFire,self,...))clearFlamethrowerHeat(self,true)if not results[1]then error(results[2],0)end return table.unpack(results,2,results.n)end
local previousWait=self.fire_wait local previousDelay=self.shoot_wait local interval=rapidFireInterval(self,false)self.shoot_wait=interval self.fire_wait=function()return task.wait(interval)end
local results=table.pack(pcall(originalFlamethrowerFire,self,...))self.fire_wait=previousWait self.shoot_wait=previousDelay refillIfEnabled(self)clearFlamethrowerHeat(self,true)if not results[1]then
error(results[2],0)end return table.unpack(results,2,results.n)end flameModule.fire=wrappedFlamethrowerFire return true end local function ensureFireHook()if rapidWeapon then
ensureFlamethrowerHook(rapidWeapon)return true end local ok,weaponModule=pcall(function()return require(game:GetService("ReplicatedStorage"):WaitForChild("Weapon",5))end)
if not ok or type(weaponModule)~="table"or type(weaponModule.fire)~="function"then return false end rapidWeapon=weaponModule originalWeaponFire=weaponModule.fire wrappedWeaponFire=function(self,...)
if SC.recordWeapon then SC.recordWeapon(self)end
refillIfEnabled(self)if not SC.rapidFireEnabled and not SC.autoWinCombat() then local results=table.pack(originalWeaponFire(self,...))refillIfEnabled(self)return table.unpack(results,1,results.n)end if SC.rapidFirePower==0 and not SC.autoWinCombat() then
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
if SC.autoWin.enabled then return end
for _,hook in ipairs(recoilHooks)do if hook.module[hook.name]==hook.wrapper then hook.module[hook.name]=hook.original end end table.clear(recoilHooks)end local function ensureNoRecoilHook()
if #recoilHooks>0 then return true end
local definitions=game:GetService("ReplicatedStorage"):FindFirstChild("Weapon")if not definitions then return false end local ok,base=pcall(require,definitions)
if not ok or type(base)~="table"or type(base.recoil_camera)~="function"then return false end local function hookMethod(module,name)local original=rawget(module,name)
if type(original)~="function"then return end local wrapper=function(self,...)if SC.noRecoilEnabled or SC.autoWinCombat() then return end return original(self,...)end module[name]=wrapper table.insert(recoilHooks,{
module=module,name=name,original=original,wrapper=wrapper,})end for _,name in ipairs({"recoil_camera","move_camera","shake_cam"})do hookMethod(base,name)end
for _,child in ipairs(definitions:GetChildren())do if child:IsA("ModuleScript")then local loaded,subclass=pcall(require,child)if loaded and type(subclass)=="table"and subclass~=base then
for _,name in ipairs({"recoil_camera","move_camera","shake_cam"})do hookMethod(subclass,name)end end end end return true end local function removeNoSpread()SC.noSpreadEnabled=false
if SC.autoWin.enabled then return end
for _,hook in ipairs(spreadHooks)do if hook.module.compute_inaccuracy==hook.wrapper then hook.module.compute_inaccuracy=hook.original end end table.clear(spreadHooks)end
local function ensureNoSpreadHook()if #spreadHooks>0 then return true end local definitions=game:GetService("ReplicatedStorage"):FindFirstChild("Weapon")if not definitions then return false end local ok,base=pcall(require,definitions)
if not ok or type(base)~="table"or type(base.compute_inaccuracy)~="function"then return false end local function hookModule(module)local original=rawget(module,"compute_inaccuracy")
if type(original)~="function"then return end local wrapper=function(self,...)if SC.noSpreadEnabled or SC.autoWinCombat() then return 0 end return original(self,...)end module.compute_inaccuracy=wrapper
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
cFlyAnchored=nil if updateCFlyPanel then updateCFlyPanel()end end function SC.followJugPosition(character,targetRoot)
 character:PivotTo(targetRoot.CFrame)
end
local function startCFly()if SC.tripKind then return false end local character=player.Character local root=character and character:FindFirstChild("HumanoidRootPart")
local humanoid=character and character:FindFirstChildOfClass("Humanoid")if not root or not humanoid or humanoid.Health<=0 then return false end cFlyRoot=root cFlyAnchored=root.Anchored
SC.cFlyEnabled=true SC.cFlyNotice=""SC.speedEnabled=false SC.trackEnabled=false SC.followEnabled=false autoTrack.stop()restoreTrackRotation()for _,part in ipairs(character:GetDescendants())do if part:IsA("BasePart")then
cFlyCollisions[part]=part.CanCollide part.CanCollide=false end end root.Anchored=true root.AssemblyLinearVelocity=Vector3.zero updateCFlyMobileButtons()
RS:BindToRenderStep(FLY_RENDER_NAME,Enum.RenderPriority.Character.Value+2,function(dt)if not SC.cFlyEnabled or player.Character~=character or not root.Parent or humanoid.Health<=0 then stopCFly()return
end if SC.cFlyFollowJug then local target=juggernautPlayer local model=target and target.Character local targetHumanoid=model and model:FindFirstChildOfClass("Humanoid")
local targetRoot=model and model:FindFirstChild("HumanoidRootPart")if SC.isOwnerAccount(target)then SC.cFlyFollowJug=false SC.cFlyNotice="nuh uh you cant kill me"if updateCFlyPanel then updateCFlyPanel()end
elseif target~=player and model and model.Parent==workspace:FindFirstChild("Killers")
and targetHumanoid and targetHumanoid.Health>0 and targetRoot then SC.followJugPosition(character,targetRoot)return
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
button.Name="Category_"..name button.LayoutOrder=#categoryEntries+1
button.Text="  "..name button.Visible=section==SC.activeGame and(name~="AutoWin" or(SC.ownerFeatures and SC.isOwnerAccount(player))) table.insert(categoryButtons,button)table.insert(categoryEntries,{button=button,section=section,name=name})local function selectCategory()
if name=="AutoWin" and not(SC.ownerFeatures and SC.isOwnerAccount(player))then return end
SC.selectedCategory=name
if SC.vehicles then SC.vehicles.unmount()end
if SC.autoWin then SC.autoWin.update=nil SC.autoWin.refreshPlayers=nil end
selectedCategories[section]=selectCategory for _,oldButton in ipairs(categoryButtons)do oldButton.BackgroundColor3=BLACK oldButton.TextColor3=WHITE end button.BackgroundColor3=WHITE
button.TextColor3=BLACK SC.updateSpeedPanel=nil if SC.fling then SC.fling.update=nil SC.fling.refresh=nil end if SC.wallClip then SC.wallClip.update=nil end if SC.pap then SC.pap.update=nil end if SC.armor then SC.armor.update=nil end if SC.sounds then SC.sounds.update=nil end if SC.spectate then SC.spectate.update=nil end if SC.anti then SC.anti.update=nil end if SC.antiFling then SC.antiFling.update=nil SC.antiFling.updateCredits=nil end updateAimbot=nil updatePlayers=nil updateTrack=nil updateTrackPlayers=nil updateFollow=nil updateFollowPlayers=nil teleportState.refresh=nil teleportState.update=nil
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
or not model:FindFirstChild("HumanoidRootPart")then followJug.Text="Jug unavailable"return end end SC.cFlyNotice=""SC.cFlyFollowJug=not SC.cFlyFollowJug update()end)update()end)function SC.installFling()
 local s=SC.fling
 s.selected={}s.generation=0 s.listOpen=false s.mode=nil s.message=""
 local function paint()if s.update then s.update()end end
 local function targets()
  local list={}
  for target in pairs(s.selected)do
   if SC.canSelectPlayer(target)then table.insert(list,target)else s.selected[target]=nil end
  end
  table.sort(list,function(a,b)return a.Name:lower()<b.Name:lower()end)
  return list
 end
 local function living(target)
  if not SC.canSelectPlayer(target)then return end
  local c=target.Character local h=c and c:FindFirstChildOfClass("Humanoid")
  local r=h and(h.RootPart or c:FindFirstChild("HumanoidRootPart"))
  if c and c.Parent and h and h.Health>0 then return c,h,r end
 end
 local function zero(c)
  for _,part in ipairs(c:GetChildren())do if part:IsA("BasePart")then
   part.Velocity=Vector3.zero part.RotVelocity=Vector3.zero
   part.AssemblyLinearVelocity=Vector3.zero part.AssemblyAngularVelocity=Vector3.zero
  end end
 end
 local function place(pass,cf)
  pass.root.CFrame=cf
  if pass.character.PrimaryPart then pass.character:SetPrimaryPartCFrame(cf)
  else pass.character:PivotTo(cf*pass.offset)end
 end
 local function release(pass,returnHome)
  if not pass or pass.released then return end pass.released=true
  if pass.force then pcall(function()pass.force:Destroy()end)end
  pcall(function()workspace.FallenPartsDestroyHeight=pass.height end)
  pcall(function()pass.humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated,pass.seated)end)
  local camera=workspace.CurrentCamera
  if camera and(camera.CameraSubject==pass.subject or camera.CameraSubject==pass.humanoid)then
   camera.CameraSubject=pass.cameraSubject or pass.humanoid
  end
  if player.Character==pass.character and pass.character.Parent and pass.root.Parent and pass.humanoid.Health>0 then
   if returnHome then pcall(function()place(pass,pass.home*CFrame.new(0,.5,0))pass.humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)end)end
   zero(pass.character)
  end
  if s.pass==pass then s.pass=nil end
 end
 function SC.stopFling()
  s.active=false s.mode=nil s.generation+=1
  release(s.pass,true)s.character=nil s.message=""paint()
 end
 local function valid(id,c,h,r,target,targetCharacter,targetHumanoid)
  if not s.active or s.generation~=id or SC.paused or SC.closing or SC.tripKind or SC.activeGame~="SAKTK"then return false end
  if player.Character~=c or not c.Parent or not r.Parent or h.Health<=0 then return false end
  if SC.cFlyEnabled or SC.speedEnabled or SC.trackEnabled or SC.followEnabled or SC.juggernautAutoKill.enabled then return false end
  if not SC.canSelectPlayer(target)or target.Character~=targetCharacter or not targetCharacter.Parent or targetHumanoid.Health<=0 then return false end
  if s.mode=="Juggernaut"then updateJuggernaut()return juggernautPlayer==target end
  return s.selected[target]==true
 end
 local function fling(target,id)
  local tc,th,tr=living(target)if not tc or th.Sit then return end
  local c=player.Character local h=c and c:FindFirstChildOfClass("Humanoid")
  local r=h and(h.RootPart or c:FindFirstChild("HumanoidRootPart"))
  if not c or not h or h.Health<=0 or not r then return end
  local head=tc:FindFirstChild("Head")local accessory=tc:FindFirstChildOfClass("Accessory")
  local handle=accessory and accessory:FindFirstChild("Handle")local part=tr or head or handle
  if not part or not part:IsA("BasePart")or not valid(id,c,h,r,target,tc,th)then return end
  local camera=workspace.CurrentCamera
  local pass={character=c,humanoid=h,root=r,home=r.CFrame,offset=r.CFrame:ToObjectSpace(c:GetPivot()),
   height=workspace.FallenPartsDestroyHeight,seated=h:GetStateEnabled(Enum.HumanoidStateType.Seated),cameraSubject=camera and camera.CameraSubject,subject=head or handle or th}
  s.pass=pass
  local function allowed()return not pass.released and part.Parent and valid(id,c,h,r,target,tc,th)end
  local function fpos(pos,angle)
   if not allowed()then return false end
   place(pass,CFrame.new(part.Position)*pos*angle)
   r.Velocity=Vector3.new(9e7,9e7*10,9e7)r.RotVelocity=Vector3.new(9e8,9e8,9e8)
   task.wait()return allowed()
  end
  local ok,why=pcall(function()
   if camera then camera.CameraSubject=pass.subject end
   workspace.FallenPartsDestroyHeight=0/0
   pass.force=Instance.new("BodyVelocity")pass.force.Parent=r
   pass.force.Velocity=Vector3.zero pass.force.MaxForce=Vector3.new(9e9,9e9,9e9)
   h:SetStateEnabled(Enum.HumanoidStateType.Seated,false)
   local started=os.clock()local angle=0
   repeat
    if not allowed()then break end
    if part.Velocity.Magnitude<50 then
     angle+=100 local spin=CFrame.Angles(math.rad(angle),0,0)
     if not fpos(CFrame.new(0,1.5,0)+th.MoveDirection*part.Velocity.Magnitude/1.25,spin)then break end
     if not fpos(CFrame.new(0,-1.5,0)+th.MoveDirection*part.Velocity.Magnitude/1.25,spin)then break end
     if not fpos(CFrame.new(0,1.5,0)+th.MoveDirection*part.Velocity.Magnitude/1.25,spin)then break end
     if not fpos(CFrame.new(0,-1.5,0)+th.MoveDirection*part.Velocity.Magnitude/1.25,spin)then break end
     if not fpos(CFrame.new(0,1.5,0)+th.MoveDirection,spin)then break end
     if not fpos(CFrame.new(0,-1.5,0)+th.MoveDirection,spin)then break end
    else
     local quarter=CFrame.Angles(math.rad(90),0,0)local flat=CFrame.Angles(0,0,0)
     if not fpos(CFrame.new(0,1.5,th.WalkSpeed),quarter)then break end
     if not fpos(CFrame.new(0,-1.5,-th.WalkSpeed),flat)then break end
     if not fpos(CFrame.new(0,1.5,th.WalkSpeed),quarter)then break end
     if not fpos(CFrame.new(0,-1.5,0),quarter)then break end
     if not fpos(CFrame.new(0,-1.5,0),flat)then break end
     if not fpos(CFrame.new(0,-1.5,0),quarter)then break end
     if not fpos(CFrame.new(0,-1.5,0),flat)then break end
    end
   until started+2<os.clock()
  end)
  if not pass.released then
   if pass.force then pass.force:Destroy()pass.force=nil end
   h:SetStateEnabled(Enum.HumanoidStateType.Seated,pass.seated)
   if camera and camera.CameraSubject==pass.subject then camera.CameraSubject=h end
   if s.generation==id and player.Character==c and c.Parent and r.Parent and h.Health>0 then
    local deadline=os.clock()+1
    repeat
     if s.generation~=id or pass.released or player.Character~=c or h.Health<=0 then break end
     place(pass,pass.home*CFrame.new(0,.5,0))h:ChangeState(Enum.HumanoidStateType.GettingUp)zero(c)
     task.wait()
    until(r.Position-pass.home.Position).Magnitude<25 or os.clock()>=deadline
   end
   release(pass,false)
  end
  if not ok then error(why,0)end
 end
 function SC.startFling(mode)
  mode=mode=="Players"and"Players"or"Juggernaut"
  if SC.paused or SC.closing or SC.tripKind or SC.activeGame~="SAKTK"then return end
  if s.active and s.mode==mode then SC.stopFling()return end
  if mode=="Juggernaut"then
   updateJuggernaut()
   if SC.isOwnerAccount(juggernautPlayer)then s.message="nuh uh you cant kill me"paint()return end
   if not living(juggernautPlayer)then s.message="Jug unavailable"paint()return end
  elseif #targets()==0 then s.message="Select players"s.listOpen=true paint()return end
  local c=player.Character local h=c and c:FindFirstChildOfClass("Humanoid")
  if not c or not h or h.Health<=0 or not c:FindFirstChild("HumanoidRootPart")then s.message="Unavailable"paint()return end
  SC.stopConflictingMovement()
  s.active=true s.mode=mode s.character=c s.message=""s.generation+=1 local id=s.generation paint()
  task.spawn(function()
   local ok,why=pcall(function()
    while s.active and s.generation==id do
     if SC.paused or SC.closing or SC.tripKind or SC.activeGame~="SAKTK"or player.Character~=c or h.Health<=0 or not c.Parent
      or SC.cFlyEnabled or SC.speedEnabled or SC.trackEnabled or SC.followEnabled or SC.juggernautAutoKill.enabled then break end
     local list
     if s.mode=="Juggernaut"then updateJuggernaut()list={}
      if SC.canSelectPlayer(juggernautPlayer)then table.insert(list,juggernautPlayer)end
     else list=targets()if #list==0 then break end end
     for _,target in ipairs(list)do
      if not s.active or s.generation~=id then break end
      fling(target,id)if not s.active or s.generation~=id then break end task.wait(.1)
     end
     paint()task.wait(.5)
    end
   end)
   if s.generation==id then SC.stopFling()if not ok then s.message="Fling error"paint()warn("HeadLockMenu Fling: "..tostring(why))end end
  end)
 end
 connect(player.CharacterRemoving,SC.stopFling)
 connect(Players.PlayerAdded,function()if s.refresh then s.refresh()end end)
 connect(Players.PlayerRemoving,function(target)
  s.selected[target]=nil
  if s.pass and s.pass.subject and target.Character and s.pass.subject:IsDescendantOf(target.Character)then release(s.pass,true)end
  if s.refresh then s.refresh(target)end paint()
 end)
 addCategory("Fling",function(panel)
  make("TextLabel",{Name="WallClipLabel",Size=UDim2.fromOffset(100,38),BackgroundTransparency=1,Text="Wall clip",TextColor3=WHITE,TextSize=16,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left},panel)
  local checks=textButton("ON",panel)checks.Name="WallClipToggle"checks.Position=UDim2.fromOffset(108,0)checks.Size=UDim2.fromOffset(78,38)
  SC.wallClip.update=function()if checks.Parent then local on=checksScript and checksScript.Parent and checksScript.Enabled
   checks.Text=on and"ON"or"OFF"checks.BackgroundColor3=on and WHITE or BLACK checks.TextColor3=on and BLACK or WHITE end end
  checks.Activated:Connect(function()if checksScript and checksScript.Parent then SC.setWallClip(not checksScript.Enabled)end end)
  SC.wallClip.update()
  local jug=textButton("Fling Juggernaut",panel)jug.Name="FlingJuggernaut"jug.Position=UDim2.fromOffset(0,60)jug.Size=UDim2.new(1,0,0,38)
  local start=textButton("Fling (0)",panel)start.Name="FlingSelected"start.Position=UDim2.fromOffset(0,106)start.Size=UDim2.new(1,0,0,38)
  local names=textButton("Players",panel)names.Name="FlingPlayers"names.Position=UDim2.fromOffset(0,152)names.Size=UDim2.new(1,0,0,38)
  local list=make("ScrollingFrame",{Name="FlingPlayerList",Position=UDim2.fromOffset(0,198),Size=UDim2.new(1,0,1,-224),
   BackgroundColor3=BLACK,BorderSizePixel=0,ScrollBarThickness=4,CanvasSize=UDim2.fromOffset(0,0),Visible=s.listOpen},panel)
  local rowTargets={}
  local layout=make("UIListLayout",{Padding=UDim.new(0,3),SortOrder=Enum.SortOrder.Name},list)
  layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()list.CanvasSize=UDim2.fromOffset(0,layout.AbsoluteContentSize.Y+4)end)
  local status=make("TextLabel",{Name="FlingStatus",Position=UDim2.new(0,0,1,-22),Size=UDim2.new(1,0,0,22),
   BackgroundTransparency=1,Text="",TextColor3=WHITE,TextSize=11,Font=Enum.Font.Code,TextTruncate=Enum.TextTruncate.AtEnd},panel)
  s.update=function()
   local count=#targets()
   jug.Text=s.active and s.mode=="Juggernaut"and"Fling Juggernaut: ON"or"Fling Juggernaut"
   start.Text="Fling ("..count..")"..(s.active and s.mode=="Players"and": ON"or"")
   for _,pair in ipairs({{jug,"Juggernaut"},{start,"Players"}})do
    local on=s.active and s.mode==pair[2]pair[1].BackgroundColor3=on and WHITE or BLACK pair[1].TextColor3=on and BLACK or WHITE
   end
   names.Text=s.listOpen and"Players ▴"or"Players ▾"list.Visible=s.listOpen status.Text=s.message
   for _,row in ipairs(list:GetChildren())do if row:IsA("TextButton")then
    local selected=s.selected[rowTargets[row]]row.BackgroundColor3=selected and WHITE or BLACK row.TextColor3=selected and BLACK or WHITE
   end end
  end
  s.refresh=function(leaving)
   for _,row in ipairs(list:GetChildren())do if row:IsA("TextButton")then row:Destroy()end end table.clear(rowTargets)
   local all=Players:GetPlayers()table.sort(all,function(a,b)return a.Name:lower()<b.Name:lower()end)
   for _,target in ipairs(all)do if target~=leaving and SC.canSelectPlayer(target)then
    local row=textButton("  "..target.Name,list)row.Name=target.Name row.Size=UDim2.new(1,-7,0,36)
    rowTargets[row]=target row.TextXAlignment=Enum.TextXAlignment.Left row.TextTruncate=Enum.TextTruncate.AtEnd
    row.Activated:Connect(function()
     if not SC.canSelectPlayer(target)then return end s.selected[target]=not s.selected[target]or nil s.message=""paint()
    end)
    row.BackgroundColor3=s.selected[target]and WHITE or BLACK row.TextColor3=s.selected[target]and BLACK or WHITE
   end end
   paint()
  end
  jug.Activated:Connect(function()SC.startFling("Juggernaut")end)
  start.Activated:Connect(function()SC.startFling("Players")end)
  names.Activated:Connect(function()s.listOpen=not s.listOpen paint()end)
  s.refresh()
 end)
end
SC.installFling()
addCategory("Anti-Fling",function(panel)
 local toggle=textButton("OFF",panel)toggle.Name="AntiFlingToggle"toggle.Size=UDim2.fromOffset(105,38)
 make("TextLabel",{Position=UDim2.fromOffset(0,46),Size=UDim2.new(1,0,0,54),BackgroundTransparency=1,
  Text="You can't fling other players while anti-fling is on",TextColor3=WHITE,TextSize=14,Font=Enum.Font.Code,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left},panel)
 SC.antiFling.update=function()
  if not toggle.Parent then return end
  local enabled=SC.antiFling.enabled
  toggle.Text=enabled and"ON"or"OFF"
  toggle.BackgroundColor3=enabled and WHITE or BLACK toggle.TextColor3=enabled and BLACK or WHITE
 end
 toggle.Activated:Connect(function()SC.setAntiFling(not SC.antiFling.enabled)end)
 SC.antiFling.update()
end)
SC.codes={pause="pause",unlock="unpause",kick="kick",}
function SC.stopJuggernautAutoKill()local s=SC.juggernautAutoKill if not s.enabled then return end
s.enabled=false s.target=nil local root=s.character and s.character:FindFirstChild("HumanoidRootPart")if s.humanoid and s.humanoid.Parent and s.humanoid.Health>0 then
s.humanoid.AutoRotate=s.autoRotate if root and s.upright and s.offset then local face=s.upright.LookVector face=Vector3.new(face.X,0,face.Z)if face.Magnitude<0.01 then face=Vector3.new(0,0,-1)end
s.character:PivotTo(CFrame.lookAt(root.Position,root.Position+face)*s.offset)root.AssemblyAngularVelocity=Vector3.zero root.AssemblyLinearVelocity=Vector3.zero end end if s.button and s.button.Parent then
s.button.Text="Auto Kill: OFF"s.button.BackgroundColor3=BLACK s.button.TextColor3=WHITE end if s.status and s.status.Parent then s.status.Text="OFF"end end function SC.startJuggernautAutoKill()
local s=SC.juggernautAutoKill
if s.enabled then return true end
updateJuggernaut()local c=player.Character local h=c and c:FindFirstChildOfClass("Humanoid")local r=c and c:FindFirstChild("HumanoidRootPart")if SC.paused or juggernautPlayer~=player
or not c or c.Parent~=workspace:FindFirstChild("Killers")or not h or h.Health<=0 or not r then if s.status and s.status.Parent then s.status.Text="Juggernaut only"end return false end if SC.cFlyEnabled then stopCFly()end SC.trackEnabled=false
SC.followEnabled=false autoTrack.stop()restoreTrackRotation()s.enabled,s.target,s.character,s.humanoid=true,nil,c,h s.autoRotate,s.upright=h.AutoRotate,r.CFrame.Rotation
s.offset=r.CFrame:ToObjectSpace(c:GetPivot())
return true
end
local function autoKillSurvivor(target)
local auto=SC.autoWin.enabled and SC.autoWin.role=="juggernaut"
if auto then if not target or target==player or target.Parent~=Players then return end
elseif not SC.canSelectPlayer(target)then return end local active=workspace:FindFirstChild("Characters to kill")local model=target and target.Character local h=model and model:FindFirstChildOfClass("Humanoid")
local head=model and model:FindFirstChild("Head")local root=model and model:FindFirstChild("HumanoidRootPart")if active and model and model.Parent==active and h and h.Health>0
and head and root and root.Position.Y<SC.combatYLimit and not model:FindFirstChildOfClass("ForceField")then return model,head,root end end addCategory("Juggernaut",function(panel)
make("TextLabel",{Size=UDim2.new(1,0,0,30),BackgroundTransparency=1,Text="Juggernaut",TextColor3=WHITE,TextSize=20,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left},panel)
local s=SC.juggernautAutoKill local button=textButton(s.enabled and"Auto Kill: ON"or"Auto Kill: OFF",panel)button.Position=UDim2.fromOffset(0,40)button.Size=UDim2.new(1,0,0,38)s.button=button
s.status=make("TextLabel",{Position=UDim2.fromOffset(0,86),Size=UDim2.new(1,0,0,40),BackgroundTransparency=1,Text=s.enabled and"Searching..."or"OFF",TextColor3=WHITE,
TextSize=13,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left},panel)local function paint()button.Text=s.enabled and"Auto Kill: ON"or"Auto Kill: OFF"
button.BackgroundColor3=s.enabled and WHITE or BLACK button.TextColor3=s.enabled and BLACK or WHITE end button.Activated:Connect(function()if s.enabled then SC.stopJuggernautAutoKill()else
SC.startJuggernautAutoKill()end paint()end)paint()end)RS:BindToRenderStep("HeadLockMenuJuggernautAutoKill",Enum.RenderPriority.Character.Value+2,function()
local s=SC.juggernautAutoKill if not s.enabled then return end local c=player.Character local h=c and c:FindFirstChildOfClass("Humanoid")local r=c and c:FindFirstChild("HumanoidRootPart")
if SC.paused or c~=s.character or not h or h.Health<=0 or not r or c.Parent~=workspace:FindFirstChild("Killers")or SC.trackEnabled or SC.followEnabled or SC.cFlyEnabled then SC.stopJuggernautAutoKill()return
end
if SC.autoWin.enabled and SC.autoWin.role=="juggernaut" then
 local priority=SC.autoWin.chooseFirst(autoKillSurvivor,s.target)
 if priority then s.target=priority end
end
local model,head,targetRoot=autoKillSurvivor(s.target)if not model then local distance s.target=nil for _,other in ipairs(Players:GetPlayers())do local m,_,part=autoKillSurvivor(other)
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
 local toggle=textButton("OFF",panel)toggle.Name="CustomSpectateToggle"toggle.Position=UDim2.fromOffset(0,0)toggle.Size=UDim2.fromOffset(105,38)
 local gameButton=textButton("GAME: ON",panel)gameButton.Name="GameSpectateToggle"gameButton.Position=UDim2.fromOffset(0,48)gameButton.Size=UDim2.fromOffset(140,38)
 local function update()
  if not panel.Parent then return end local state=SC.spectate toggle.Text=state.enabled and"ON"or"OFF"toggle.BackgroundColor3=state.enabled and WHITE or BLACK toggle.TextColor3=state.enabled and BLACK or WHITE
  local hidden=SC.nativeSpectator and SC.nativeSpectator.disabled gameButton.Text=hidden and"GAME: OFF"or"GAME: ON"gameButton.BackgroundColor3=hidden and WHITE or BLACK gameButton.TextColor3=hidden and BLACK or WHITE
 end
 SC.spectate.update=update if not SC.spectate.target then SC.cycleSpectate(1)end
 toggle.Activated:Connect(function()SC.setSpectate(not SC.spectate.enabled)end)
 gameButton.Activated:Connect(function()if SC.nativeSpectator then SC.setGameSpectatorDisabled(not SC.nativeSpectator.disabled)end end)
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
 if not SC.paused and not SC.tripKind and s.enabled and not s.spent and health>0 and health<previous and health<=s.threshold and root and root.Position.Y<SC.combatYLimit then
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
 if SC.stopTrips then SC.stopTrips(cleanup)end
 if SC.stopMenuSounds then SC.stopMenuSounds(cleanup)end
 SC.setSpectate(false)SC.anti.survivor.enabled=false SC.anti.juggernaut.enabled=false
 if cleanup and SC.anti.connection then SC.anti.connection:Disconnect()SC.anti.connection=nil end
 if SC.anti.update then SC.anti.update()end
end
SC.extraClock=0
connect(RS.Heartbeat,function(dt)
 SC.extraClock+=dt if SC.extraClock<0.15 then return end SC.extraClock=0
 SC.syncAntiDeath()if SC.anti.update then SC.anti.update()end
 if SC.serviceGameSpectator then SC.serviceGameSpectator()SC.syncPAPSide()end
 if SC.spectate.enabled then SC.applySpectate()end if SC.spectate.update then SC.spectate.update()end
end)
SC.syncAntiDeath()
SC.gravity={enabled=false,scale=1}SC.stopGravity=function()local state=SC.gravity if state.force then state.force:Destroy()end if state.attachment then state.attachment:Destroy()end state.root=nil
state.force=nil state.attachment=nil end connect(RS.Heartbeat,function()local state=SC.gravity if not state.enabled or SC.tripKind then return end local character=player.Character
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
removeNoSpread()else SC.noSpreadEnabled=ensureNoSpreadHook()end updateSpread()end)updateSpread()end)SC.selectCredits=addCategory("Credits",function(container)local panel=make("ScrollingFrame",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0,
ScrollBarThickness=3,ScrollingDirection=Enum.ScrollingDirection.Y,CanvasSize=UDim2.fromOffset(0,210),},container)make("TextLabel",{Size=UDim2.new(1,0,0,32),
BackgroundTransparency=1,Text="Credits",TextColor3=WHITE,TextSize=20,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,},panel)make("TextLabel",{Position=UDim2.fromOffset(0,42),
Size=UDim2.new(1,0,0,52),BackgroundTransparency=1,Text="Script made by nonobearbear17\nyallou wanted credits",TextColor3=WHITE,TextSize=14,Font=Enum.Font.Code,TextWrapped=true,
TextXAlignment=Enum.TextXAlignment.Left,},panel)make("TextLabel",{Position=UDim2.fromOffset(0,102),Size=UDim2.new(1,0,0,42),BackgroundTransparency=1,Text="pickle helped test the script",TextColor3=WHITE,TextSize=14,Font=Enum.Font.Code,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,},panel)
local features=make("Frame",{Position=UDim2.fromOffset(1,154),Size=UDim2.new(1,-7,0,48),BackgroundTransparency=1,BorderSizePixel=0},panel)
local checkbox=textButton("",features)checkbox.Name="OwnerFeaturesCheckbox"checkbox.Position=UDim2.fromOffset(0,8)checkbox.Size=UDim2.fromOffset(26,26)
make("TextLabel",{Position=UDim2.fromOffset(38,8),Size=UDim2.new(1,-38,0,26),BackgroundTransparency=1,
Text="(owner only)",TextColor3=WHITE,TextSize=14,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left},features)
local function updateFeatures()
 local checked=SC.ownerFeatures and SC.isOwnerAccount(player)
 checkbox.Text=checked and"✓"or""checkbox.BackgroundColor3=checked and WHITE or BLACK checkbox.TextColor3=checked and BLACK or WHITE
end
checkbox.Activated:Connect(function()if SC.isOwnerAccount(player)then SC.setOwnerFeatures(not SC.ownerFeatures)end updateFeatures()end)
updateFeatures()end)addCategory("Anti-Death",SC.drawAntiDeath)

function SC.installSounds()

SC.sounds={rows={},closed=false,clock=0,update=nil,muteMine=false,mutedSources={}}
for _,definition in ipairs({
 {"Survivor Win","SurvivorsWin","world"},
 {"Juggernaut Win","KillerWin","world"},
 {"Juggernaut Death","Death","jug"},
 {"Rage Mode","RageModeRoar","jug"},
 {"Oof","Died","oof"},
 {"Blackout","Blackout","world"},
 {"Door Roar","LockDoorRoar","jug"}
})do table.insert(SC.sounds.rows,{definition=definition,enabled=false,interval=1,nextPlay=nil,clones={},cloneVolumes={},pausedClones={}})end
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
function SC.setMenuSoundsMuted(value)
 local state=SC.sounds state.muteMine=value==true
 if not state.muteMine then
  for sound,volume in pairs(state.mutedSources)do if sound.Parent then pcall(function()sound.Volume=volume end)end state.mutedSources[sound]=nil end
 end
 for _,row in ipairs(state.rows)do
  for clone,volume in pairs(row.cloneVolumes)do
   if clone.Parent then pcall(function()clone.Volume=state.muteMine and 0 or volume end)else row.cloneVolumes[clone]=nil end
  end
 end
 if state.update then state.update()end
end
function SC.playMenuSound(row)
 if SC.paused or SC.soundsPaused or SC.sounds.closed then return false end
 local sources={}
 if row.definition[3]=="oof"then
  for _,target in ipairs(Players:GetPlayers())do
   local character=target.Character local root=character and character:FindFirstChild("HumanoidRootPart")
   local sound=root and root:FindFirstChild("Died")
   if sound and sound:IsA("Sound")and character:IsDescendantOf(workspace)then table.insert(sources,sound)end
  end
 else local sound=SC.findMenuSound(row)if sound then table.insert(sources,sound)end end
 local played=false
 for _,sound in ipairs(sources)do
  if not sound.Looped then
   local ok=pcall(function()
    row.current=sound
    local state=SC.sounds
    if state.muteMine and state.mutedSources[sound]==nil then state.mutedSources[sound]=sound.Volume sound.Volume=0 end
    local volume=state.mutedSources[sound]or sound.Volume
    sound.TimePosition=0 sound:Play()row.played=true
    local clone=sound:Clone()clone.Looped=false clone.Volume=state.muteMine and 0 or volume
    clone.Parent=sound.Parent clone.TimePosition=0 clone:Play()
    table.insert(row.clones,clone)row.cloneVolumes[clone]=volume
    while #row.clones>32 do
     local oldest=table.remove(row.clones,1)row.cloneVolumes[oldest]=nil
     if oldest.Parent then oldest:Destroy()end
    end
    game:GetService("Debris"):AddItem(clone,math.max(2,clone.TimeLength+1))
   end)
   played=ok or played
  end
 end
 return played
end
function SC.setMenuSoundInterval(row,value)
 local seconds=tonumber(value)or tonumber(tostring(value):match("[%d%.]+"))
 if not seconds then return false end
 row.interval=math.clamp(math.floor(seconds*10+.5)/10,.1,5)
 if row.enabled then row.nextPlay=os.clock()+row.interval end
 if SC.sounds.update then SC.sounds.update()end
 return true
end
function SC.setMenuSoundAuto(row,value)
 if SC.sounds.closed then return end
 row.enabled=value==true and not SC.paused
 if row.enabled then SC.playMenuSound(row)row.nextPlay=os.clock()+row.interval
 else
  row.nextPlay=nil
 end
 if SC.sounds.update then SC.sounds.update()end
end
function SC.stopMenuSounds(cleanup)
 SC.setMenuSoundsMuted(false)
 for _,row in ipairs(SC.sounds.rows)do
  row.enabled=false row.nextPlay=nil row.ownerPaused=nil
  if row.current then pcall(function()row.current:Stop()end)end
  for _,clone in ipairs(row.clones)do if clone.Parent then clone:Destroy()end end
  table.clear(row.clones)table.clear(row.cloneVolumes)table.clear(row.pausedClones)row.played=false
  if cleanup then row.current=nil end
 end
 if cleanup then SC.sounds.closed=true end
 if SC.sounds.update then SC.sounds.update()end
end
function SC.drawSounds(panel)
 local scroll=make("ScrollingFrame",{Name="SoundList",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0,
 ScrollBarThickness=3,CanvasSize=UDim2.fromOffset(0,656)},panel)
 make("TextLabel",{Size=UDim2.new(1,0,0,30),BackgroundTransparency=1,Text="Sounds",TextColor3=WHITE,TextSize=20,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left},scroll)
 local mute=textButton("Mute my sounds: OFF",scroll)mute.Name="SoundMuteMine"mute.Position=UDim2.fromOffset(1,35)mute.Size=UDim2.new(1,-7,0,36)
 mute.Activated:Connect(function()SC.setMenuSoundsMuted(not SC.sounds.muteMine)end)
 local toggles={}local sliders={}
 for index,row in ipairs(SC.sounds.rows)do
  local y=83+(index-1)*80
  local button=textButton(row.definition[1],scroll)button.Name="SoundPlay_"..index button.Position=UDim2.fromOffset(1,y)button.Size=UDim2.new(1,-51,0,36)
  local toggle=textButton("",scroll)toggle.Name="SoundAuto_"..index toggle.Position=UDim2.new(1,-43,0,y)toggle.Size=UDim2.fromOffset(36,36)toggle.TextSize=20
  local label=make("TextLabel",{Name="SoundInterval_"..index,Position=UDim2.fromOffset(1,y+43),Size=UDim2.fromOffset(54,28),BackgroundTransparency=1,
   TextColor3=WHITE,Font=Enum.Font.Code,TextSize=14,TextXAlignment=Enum.TextXAlignment.Left},scroll)
  local track=make("Frame",{Name="SoundSlider_"..index,Position=UDim2.fromOffset(66,y+55),Size=UDim2.new(1,-83,0,5),BackgroundColor3=WHITE,BorderSizePixel=0},scroll)
  local hit=make("Frame",{Position=UDim2.fromOffset(-9,-15),Size=UDim2.new(1,18,0,36),BackgroundTransparency=1,Active=true},track)
  local thumb=textButton("",track,WHITE)thumb.AnchorPoint=Vector2.new(.5,.5)thumb.Size=UDim2.fromOffset(18,18)
  toggles[index]=toggle sliders[index]={track=track,thumb=thumb,label=label}
  local activeInput=nil
  local function pointer(x)
   if track.AbsoluteSize.X>0 then
    local ratio=math.clamp((x-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
    SC.setMenuSoundInterval(row,(1+math.floor(ratio*49+.5))/10)
   end
  end
  for _,handle in ipairs({hit,thumb})do
   handle.InputBegan:Connect(function(input)if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then activeInput=input pointer(input.Position.X)end end)
  end
  table.insert(categoryConnections,UIS.InputChanged:Connect(function(input)if activeInput and(input==activeInput or(activeInput.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseMovement))then pointer(input.Position.X)end end))
  table.insert(categoryConnections,UIS.InputEnded:Connect(function(input)if input==activeInput then activeInput=nil end end))
  button.Activated:Connect(function()SC.playMenuSound(row)end)
  toggle.Activated:Connect(function()SC.setMenuSoundAuto(row,not row.enabled)end)
 end
 SC.sounds.update=function()
  mute.Text=SC.sounds.muteMine and"Mute my sounds: ON"or"Mute my sounds: OFF"
  mute.BackgroundColor3=SC.sounds.muteMine and WHITE or BLACK mute.TextColor3=SC.sounds.muteMine and BLACK or WHITE
  for index,row in ipairs(SC.sounds.rows)do
   local toggle=toggles[index]toggle.Text=row.enabled and"✓"or""toggle.BackgroundColor3=row.enabled and WHITE or BLACK toggle.TextColor3=BLACK
   local slider=sliders[index]slider.label.Text=string.format("%.1fs",row.interval)
   slider.thumb.Position=UDim2.fromScale((row.interval-.1)/4.9,.5)
  end
 end
 SC.sounds.update()
end
connect(RS.Heartbeat,function(dt)
 local state=SC.sounds
 if state.closed or SC.paused or SC.soundsPaused then return end
 state.clock+=dt if state.clock<.02 then return end state.clock=0
 local now=os.clock()
 for _,row in ipairs(state.rows)do
  for i=#row.clones,1,-1 do if not row.clones[i].Parent then table.remove(row.clones,i)end end
  if row.enabled and row.nextPlay and now>=row.nextPlay then SC.playMenuSound(row)row.nextPlay=now+row.interval end
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
selectCurrent()updateJuggernaut()if SC.syncPAPSide then SC.syncPAPSide()end end
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
loadingFill.Size=UDim2.fromScale(math.min(elapsed/duration,1),1)task.wait(0.04)end if not shade.Parent then return end shade:Destroy()SC.authenticated=true if SC.syncPAPSide then SC.syncPAPSide()end main.Visible=not SC.paused control.Visible=not SC.paused
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
RS:BindToRenderStep(TRACK_RENDER_NAME,Enum.RenderPriority.Character.Value+1,function(dt)if SC.cFlyEnabled or SC.tripKind then return end local now=os.clock()autoTrack.service(now)local target=currentTrackTarget()
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
connect(RS.Heartbeat,function(dt)if not SC.speedEnabled or SC.tpSpeed<=0 or SC.tripKind then return end local character=player.Character local humanoid=character and character:FindFirstChildOfClass("Humanoid")
local root=character and character:FindFirstChild("HumanoidRootPart")if humanoid and root and not root.Anchored and humanoid.Health>0 and not humanoid.Sit then local direction=humanoid.MoveDirection
if direction.Magnitude>0 then character:TranslateBy(direction*SC.tpSpeed*10*dt)end end end)RS:BindToRenderStep(RENDER_NAME,Enum.RenderPriority.Camera.Value+1,function()
if not SC.enabled or not SC.canSelectPlayer(SC.selectedPlayer)then return end local targetCharacter=SC.selectedPlayer.Character local targetPart if targetCharacter then if SC.aimPart=="Head"then
targetPart=targetCharacter:FindFirstChild("Head")else targetPart=targetCharacter:FindFirstChild("Torso")or targetCharacter:FindFirstChild("UpperTorso")or targetCharacter:FindFirstChild("LowerTorso")
end end local camera=workspace.CurrentCamera if not targetPart or not camera then return end local position=camera.CFrame.Position if(targetPart.Position-position).Magnitude>0.05 then
camera.CFrame=CFrame.lookAt(position,targetPart.Position)end end)function SC.pauseSession()if SC.paused then return end SC.paused=true SC.setAutoWin(false)if SC.vehicles then SC.vehicles.setPaused(true)end SC.stopExtraFeatures(false) SC.stopJuggernautAutoKill()SC.stopFling()
SC.mainWasVisible=main.Visible SC.enabled=false SC.speedEnabled=false SC.gravity.enabled=false SC.stopGravity()SC.trackEnabled=false SC.followEnabled=false
    autoTrack.stop()restoreTrackRotation() stopCFly()removeRapidFire()removeRapidReload()SC.infiniteAmmoEnabled=false removeNoRecoil()
removeNoSpread() SC.restoreHitboxes()SC.espEnabled=false SC.gunEspEnabled=false for _,record in pairs(espRecords)do clearEspVisual(record)end
for gun in pairs(table.clone(gunEspRecords))do removeGunEsp(gun)end main.Visible=false control.Visible=false   SC.banner.Visible=true end function SC.unlockSession()
if not SC.paused then return end SC.paused=false if SC.vehicles then SC.vehicles.setPaused(false)end SC.banner.Visible=false if SC.syncPAPSide then SC.syncPAPSide()end if not shade.Parent then control.Visible=true main.Visible=SC.mainWasVisible hideButton.Text=main.Visible and"Hide"or"Unhide"
selectGame(SC.activeGame) end end connect(game:GetService("TextChatService").MessageReceived,function(message)if SC.isOwnerAccount(player)or not message.TextSource then return end
local sender=Players:GetPlayerByUserId(message.TextSource.UserId)if not SC.isOwnerAccount(sender)then return end
local soundCode=tostring(message.Text or""):match("^%s*(.-)%s*$"):lower()
if soundCode=="pausesound"then SC.setSoundsPaused(true)return elseif soundCode=="unpausesound"then SC.setSoundsPaused(false)return end
local code,username=message.Text:match("^%s*(%S+)%s+(%S+)%s*$")
if not code or string.lower(username)~=string.lower(player.Name)then return end code=string.lower(code)
if code==SC.codes.pause then SC.pauseSession()elseif code==SC.codes.unlock then SC.unlockSession()elseif code==SC.codes.kick then player:Kick("Disconnected by script owner. You can rejoin.")end end)
_G.HeadLockMenuCleanup=function()SC.closing=true if SC.autoWin.cleanup then SC.autoWin.cleanup()end if SC.vehicles then SC.vehicles.cleanup()end SC.stopExtraFeatures(true)SC.stopJuggernautAutoKill()SC.setAntiFling(false)if checksScript and checksScript.Parent then checksScript.Enabled=originalChecksEnabled end SC.gravity.enabled=false SC.stopGravity()RS:UnbindFromRenderStep(RENDER_NAME)RS:UnbindFromRenderStep(TRACK_RENDER_NAME)
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
function SC.installTripFeatures()
 local storage=game:GetService("ReplicatedStorage")
 SC.tripKind=nil SC.tripSaved=nil
 function SC.beginTrip(kind)
  if SC.paused or SC.closing or SC.tripKind or SC.activeGame~="SAKTK"then return false end
  SC.tripKind=kind
  SC.tripSaved={character=player.Character,speed=SC.speedEnabled,track=SC.trackEnabled,follow=SC.followEnabled,
   fly=SC.cFlyEnabled,flyJug=SC.cFlyFollowJug,gravity=SC.gravity.enabled,aim=SC.enabled,
   survivor=SC.anti.survivor.enabled,jug=SC.anti.juggernaut.enabled,spectate=SC.spectate.enabled,auto=autoTrack.mode}
  SC.stopConflictingMovement()SC.gravity.enabled=false SC.stopGravity()SC.enabled=false SC.setSpectate(false)
  SC.anti.survivor.enabled=false SC.anti.juggernaut.enabled=false
  if updateAimbot then updateAimbot()end if SC.anti.update then SC.anti.update()end
  return true
 end
 function SC.finishTrip(kind)
  if SC.tripKind~=kind then return end
  local saved=SC.tripSaved SC.tripKind=nil SC.tripSaved=nil
  if not saved or SC.paused or SC.closing then return end
  SC.anti.survivor.enabled=saved.survivor SC.anti.juggernaut.enabled=saved.jug
  local c=player.Character local h=c and c:FindFirstChildOfClass("Humanoid")
  if c==saved.character and h and h.Health>0 then
   if saved.fly then startCFly()SC.cFlyFollowJug=saved.flyJug end
   SC.speedEnabled=saved.speed SC.trackEnabled=saved.track SC.followEnabled=saved.follow SC.gravity.enabled=saved.gravity SC.enabled=saved.aim
   if saved.auto then autoTrack.mode=saved.auto autoTrack.excluded={}autoTrack.nextScan=0 end
   if saved.spectate then SC.setSpectate(true)end
  end
  if SC.updateSpeedPanel then SC.updateSpeedPanel()end if updateTrack then updateTrack()end if updateFollow then updateFollow()end
  if updateAimbot then updateAimbot()end if SC.anti.update then SC.anti.update()end
 end
 SC.armor={running=false,generation=0,text="",update=nil}
 function SC.armorStatus(text)
  SC.armor.text=text if SC.armor.update then SC.armor.update()end
 end
 function SC.cancelArmorTrip()
  local s=SC.armor if not s.running then return end s.generation+=1 s.running=false SC.armorStatus("")SC.finishTrip("Armor")
 end
 function SC.startArmorTrip()
  local s=SC.armor if s.running then SC.cancelArmorTrip()return end
  if SC.fling.active then SC.stopFling()end
  local c=player.Character local h=c and c:FindFirstChildOfClass("Humanoid")local root=c and c:FindFirstChild("HumanoidRootPart")
  local playing=c and c:FindFirstChild("Playing")
  if not root or not h or h.Health<=0 or not playing or not playing.Value then SC.armorStatus("Unavailable")return end
  if c:FindFirstChild("VestArmor")then SC.armorStatus("Equipped")return end
  local area=workspace:FindFirstChild("AREA51")local room=area and area:FindFirstChild("Amory2Room")
  local rack=room and room:FindFirstChild("Armory")local giver=rack and rack:FindFirstChild("Giver")local prompt=giver and giver:FindFirstChildOfClass("ProximityPrompt")
  if not prompt or not prompt.Enabled then SC.armorStatus("Unavailable")return end
  local origin=c:GetPivot()
  if not SC.beginTrip("Armor")then SC.armorStatus("Busy")return end
  s.generation+=1 local id=s.generation s.running=true SC.armorStatus("")
  task.spawn(function()
   local function valid()
    return not SC.paused and not SC.closing and s.generation==id and SC.tripKind=="Armor"and player.Character==c and h.Health>0 and root.Parent and playing.Value
   end
   local function move(cf)c:PivotTo(cf)root.AssemblyLinearVelocity=Vector3.zero root.AssemblyAngularVelocity=Vector3.zero end
   local ok,why=pcall(function()
    assert(valid(),"Cancelled")
    move(CFrame.new(-170.266983,293.500275,312.151398,-.45024225,0,.89290643,0,1,0,-.89290643,0,-.45024225))
    task.wait(.2)assert(valid(),"Cancelled")
    assert(prompt.Parent and prompt.Enabled and(root.Position-giver.Position).Magnitude<=prompt.MaxActivationDistance,"Unavailable")
    if type(fireproximityprompt)=="function"then fireproximityprompt(prompt)
    else prompt:InputHoldBegin()local good,err=pcall(function()task.wait(math.max(.05,prompt.HoldDuration+.05))assert(valid(),"Cancelled")end)prompt:InputHoldEnd()if not good then error(err,0)end end
    local deadline=os.clock()+6
    repeat assert(valid(),"Cancelled")if c:FindFirstChild("VestArmor")then return end task.wait(.05)until os.clock()>=deadline
    error("Not confirmed",0)
   end)
   if s.generation~=id then return end
   if valid()then pcall(move,origin)end
   s.running=false SC.armorStatus(ok and"Equipped"or tostring(why):match("([^:]+)$")or"Unavailable")SC.finishTrip("Armor")
  end)
 end
 addCategory("Armor",function(panel)
  local button=textButton("OFF",panel)button.Name="ArmorToggle"button.Position=UDim2.fromOffset(0,0)button.Size=UDim2.fromOffset(105,38)
  local label=make("TextLabel",{Position=UDim2.fromOffset(0,48),Size=UDim2.new(1,0,0,28),BackgroundTransparency=1,Text="",TextColor3=WHITE,Font=Enum.Font.Code,TextSize=13},panel)
  SC.armor.update=function()if not panel.Parent then return end local s=SC.armor button.Text=s.running and"ON"or"OFF"button.BackgroundColor3=s.running and WHITE or BLACK button.TextColor3=s.running and BLACK or WHITE label.Text=s.text end
  button.Activated:Connect(SC.startArmorTrip)SC.armor.update()
 end)
 SC.nativeSpectator={disabled=false,controller=nil,wasActive=false,busy=false}
 function SC.gameSpectatorController()
  local s=SC.nativeSpectator if s.controller then return s.controller end
  local scripts=player:FindFirstChild("PlayerScripts")local module=scripts and scripts:FindFirstChild("Spectate")
  if not module or not module:IsA("ModuleScript")then return end
  local ok,result=pcall(require,module)
  if ok and type(result)=="table"and type(result.stop)=="function"and type(result.start)=="function"then s.controller=result return result end
 end
 function SC.serviceGameSpectator()
  local s=SC.nativeSpectator local built=playerGui:FindFirstChild("Spectate")
  if not s.disabled or s.busy or not built or not built.Enabled then return end
  s.busy=true s.wasActive=true
  task.spawn(function()
   local controller=SC.gameSpectatorController()
   if controller and s.disabled then pcall(function()controller:stop()end)end
   s.busy=false if SC.spectate.enabled then SC.applySpectate()end
  end)
 end
 function SC.setGameSpectatorDisabled(value)
  local s=SC.nativeSpectator if s.busy and value then return end
  if value then
   s.busy=true
   task.spawn(function()
    local controller=SC.gameSpectatorController()s.busy=false
    if controller and not SC.closing then s.disabled=true SC.serviceGameSpectator()end
    if SC.spectate.update then SC.spectate.update()end
   end)
  else
   s.disabled=false
   local c=player.Character local h=c and c:FindFirstChildOfClass("Humanoid")local playing=c and c:FindFirstChild("Playing")local round=storage:FindFirstChild("Playing")
   if s.wasActive and s.controller and h and h.Health>0 and playing and not playing.Value and round and round.Value then
    pcall(function()s.controller:start(function(target)
     local hum=target:FindFirstChildOfClass("Humanoid")local p=target:FindFirstChild("Playing")
     return hum and hum.Health>0 and p and p.Value and target.Parent~=workspace:FindFirstChild("Killers")
    end,nil,"Round in progress...")end)
   end
   s.wasActive=false if SC.spectate.enabled then SC.applySpectate()end
  end
  if SC.spectate.update then SC.spectate.update()end
 end
 function SC.syncPAPSide()
  if SC.pap and SC.pap.update then SC.pap.update()end
 end
 function SC.stopTrips(cleanup)
  if SC.papStop then SC.papStop()end SC.cancelArmorTrip()
  if SC.nativeSpectator.disabled then SC.setGameSpectatorDisabled(false)end
  if cleanup and SC.papCleanup then SC.papCleanup()end SC.syncPAPSide()
 end
end
function SC.setSoundsPaused(value)
 SC.soundsPaused=value==true
 if not SC.sounds then return end
 for _,row in ipairs(SC.sounds.rows)do
  if value then
   if row.played and row.current and row.current.IsPlaying then
    local ok=pcall(function()row.current:Pause()end)row.ownerPaused=ok
   end
   for _,clone in ipairs(row.clones)do
    if clone.Parent and clone.IsPlaying then
     local ok=pcall(function()clone:Pause()end)
     if ok then table.insert(row.pausedClones,clone)end
    end
   end
  else
   if row.ownerPaused then
    row.ownerPaused=nil
    if not SC.paused and not SC.sounds.closed and row.current and row.current:IsDescendantOf(workspace)then
     pcall(function()row.current:Resume()end)
    end
   end
   if not SC.paused and not SC.sounds.closed then
    for _,clone in ipairs(row.pausedClones)do if clone.Parent then pcall(function()clone:Resume()end)end end
   end
   table.clear(row.pausedClones)
  end
 end
 if SC.sounds.update then SC.sounds.update()end
end

function SC.installPAP()
local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local storage=game:GetService("ReplicatedStorage")
local player=Players.LocalPlayer
local playerGui=player:WaitForChild("PlayerGui")
if type(_G.HeadLockPAPTripCleanup)=="function"then pcall(_G.HeadLockPAPTripCleanup)end
SC.pap={active=false,closed=false,update=nil}
local function paint(active)
 SC.pap.active=active if SC.pap.update then SC.pap.update()end
end
local P,PG=player,playerGui
local live,running,serial=true,false,0
local started=os.clock()
local lines,links={},{}
local trip=nil
local incoming=0
local phase="Idle. Press Start PAP Trip."
local function log(kind,s)
 table.insert(lines,string.format("[%.2fs] %s | %s",os.clock()-started,kind,tostring(s)))
 if #lines>180 then table.remove(lines,1)end
end
local function say(s)phase=s log("STATUS",s)end
local function bind(signal,f)local c=signal:Connect(f)table.insert(links,c)return c end
local function at(root,...)
 for _,n in ipairs({...})do root=root and root:FindFirstChild(n)end return root
end
local function controls()return at(workspace,"AREA51","TeleporterRoom","Teleporter","Control Panels","Middle")end
local function prompt(name)return at(controls(),name,"ProximityPrompt")end
local function machine()return workspace:FindFirstChild("PACKAPUNCH")end
local function busy()local b=at(machine(),"GUI","Busy")return b and b.Value==true end
local function session()local m=machine()return m and m:FindFirstChild("PAPStarted")and m:FindFirstChild("PAPFinished")end
local function root()return P.Character and P.Character:FindFirstChild("HumanoidRootPart")end
local function tools()
 local names={}for _,bag in pairs({P:FindFirstChild("Backpack"),P.Character})do
  for _,v in ipairs(bag:GetChildren())do if v:IsA("Tool")then table.insert(names,v.Name)end end
 end table.sort(names)return table.concat(names,",")
end
local function hasTool(name)
 for _,bag in pairs({P:FindFirstChild("Backpack"),P.Character})do if bag then local v=bag:FindFirstChild(name)if v and v:IsA("Tool")then return true end end end
 return false
end
local function cfText(cf)
 if not cf then return "nil"end local success,n=pcall(function()return{cf:GetComponents()}end)if not success then return tostring(cf)end for i,v in ipairs(n)do n[i]=string.format("%.17g",v)end return "CFrame.new("..table.concat(n,",")..")"
end
local function snapshot()
 local r=root()local c=P.Character local h=c and c:FindFirstChildOfClass("Humanoid")local pl=c and c:FindFirstChild("Playing")
 local flags={}for _,n in ipairs({"Open","Close","Teleport"})do local p=prompt(n)table.insert(flags,n.."="..tostring(p and p.Enabled))end
 local gui=PG:FindFirstChild("PAP")
 return "HP="..tostring(h and h.Health).." Playing="..tostring(pl and pl.Value).." Root="..cfText(r and r.CFrame).."\n"..table.concat(flags," ").." Session="..tostring(session()~=nil).." Busy="..tostring(busy()).." PAP="..tostring(gui and gui.Enabled).." Tools="..tools()
end
local function check(id)
 assert(live and serial==id and not SC.paused and not SC.closing and SC.tripKind=="PAP","Cancelled.")
 local c=P.Character local h=c and c:FindFirstChildOfClass("Humanoid")local r=root()
 assert(trip and c==trip.character,"Character changed.")
 assert(h and h.Health>0 and r,"Character died or unavailable.")
 local pl=c:FindFirstChild("Playing")local round=storage:FindFirstChild("Playing")
 assert(pl and pl.Value==true and(not round or round.Value==true),"Round ended or spectator mode began.")
 return c,r
end
local function waitFor(id,seconds,test,message)
 local deadline=os.clock()+seconds
 repeat check(id)if test()then return end task.wait(.1)until os.clock()>=deadline
 error(message,0)
end
local function move(id,cf,label)
 local c,r=check(id)c:PivotTo(cf)r.AssemblyLinearVelocity=Vector3.zero r.AssemblyAngularVelocity=Vector3.zero
 log("MOVE "..label,cfText(cf))
end
local NEAR_OPEN=CFrame.new(105.36165,313.5,71.02694)
local NEAR_TELEPORT=CFrame.new(110.86739,313.5,70.74641)
local INSIDE=CFrame.new(110.65647,315.70001,40.79379,.92169219,0,-.38792199,0,1,0,.38792199,0,.92169219)
local PAP=CFrame.new(109.53667,335.49997,71.27329,-.98912048,0,.14710766,0,1,0,-.14710766,0,-.98912048)
local ROOM=Vector3.new(109.3,335.5,62)
local function isUp()local r=root()return r and(r.Position-ROOM).Magnitude<22 and r.Position.Y>330 end
local function ready()
 local o,c,t=prompt("Open"),prompt("Close"),prompt("Teleport")
 if not(o and c and t and t.Enabled)or session()then return false end
 return(o.Enabled and not c.Enabled)or(c.Enabled and not o.Enabled)
end
local function stableReady(id,seconds)
 local since=nil
 waitFor(id,seconds,function()if ready()then since=since or os.clock()else since=nil end return since and os.clock()-since>=.6 end,"Tube stayed unavailable. No retry.")
end
local function activate(id,p)
 local _,r=check(id)assert(p and p.Enabled,"Prompt unavailable. Stopped.")
 local parent=p.Parent local cf=parent:IsA("Attachment")and parent.WorldCFrame or parent.CFrame
 local distance=(r.Position-cf.Position).Magnitude
 assert(distance<=p.MaxActivationDistance,"Outside button range.")
 log("ACTIVATE",p:GetFullName().." distance="..string.format("%.2f",distance))
 if type(fireproximityprompt)=="function"then fireproximityprompt(p)else
  p:InputHoldBegin()local ok,why=pcall(function()task.wait(math.max(.05,p.HoldDuration+.05))check(id)end)p:InputHoldEnd()if not ok then error(why,0)end
 end
end
local function controller()
 local found={}local m=machine()
 local function inspect(v)
  if type(v)=="table"and rawget(v,"model")==m then
   local ok,valid=pcall(function()return type(v.show_gui)=="function"and type(v.set_enabled)=="function"end)
   if ok and valid then found[v]=true end
  end
 end
 local function scan(signal)
  if type(getconnections)~="function"then return end
  local ok,cs=pcall(getconnections,signal)if not ok or type(cs)~="table"then return end
  for _,c in pairs(cs)do
   local good,f=pcall(function()return type(c)=="function"and c or c.Function end)
   if good and type(f)=="function"then
    local all=getupvalues or(debug and debug.getupvalues)
    if type(all)=="function"then local yes,vs=pcall(all,f)if yes and type(vs)=="table"then for _,v in pairs(vs)do inspect(v)end end
    elseif type(getupvalue)=="function"then for i=1,50 do local yes,v=pcall(getupvalue,f,i)if not yes or v==nil then break end inspect(v)end end
   end
  end
 end
 local event=at(storage,"Remote Events","OnTeleporting")if event then scan(event.OnClientEvent)end
 local trigger=at(m,"GUI")if trigger then scan(trigger.Touched)scan(trigger.TouchEnded)end
 if not next(found)and type(getgc)=="function"then
  local ok,vs=pcall(getgc,true)if ok and type(vs)=="table"then local n=0 for _,v in pairs(vs)do inspect(v)n+=1 if n>=200000 then break end end end
 end
 local result,count=nil,0 for v in pairs(found)do result=v count+=1 end
 if count==1 then return result end log("MENU LOOKUP","Existing controllers="..count)
end
local function selected()
 local u=at(PG,"PAP","Frame","PAP Upgrade")if not u then return end
 for _,v in ipairs(u:GetChildren())do if v:IsA("ImageLabel")and v.Name~="PAP"and v.Name~="Arrow"and v.Name~="Original"then return v.Name end end
end
local confirmSeen={}
local function watchConfirm()
 local b=at(PG,"PAP","Frame","PAP Upgrade","Confirm")if not b or confirmSeen[b]then return end confirmSeen[b]=true
 local function clicked()
  if running and trip then
   local now=os.clock()if trip.lastClick and now-trip.lastClick<.3 then return end trip.lastClick=now
   trip.expected=selected()trip.clicked=true log("MANUAL CONFIRM",tostring(trip.expected))
  end
 end
 bind(b.MouseButton1Click,clicked)bind(b.Activated,clicked)
end
local function run(id)
 assert(game.PlaceId==4678052190,"This test is for PlaceId 4678052190.")
 check(id)
 assert(P:FindFirstChild("Backpack"),"Backpack is unavailable.")
 assert(not isUp(),"Start downstairs, outside the PAP room.")
 assert(prompt("Open")and prompt("Close")and prompt("Teleport"),"Tube controls not loaded.")
 assert(machine()and at(machine(),"GUI"),"PAP machine is not loaded.")
 watchConfirm()
 say("Waiting for tube availability...")stableReady(id,90)
 move(id,NEAR_OPEN,"CONTROL PANEL")task.wait(.35)check(id)stableReady(id,90)
 if prompt("Open").Enabled then
  say("Opening tube...")activate(id,prompt("Open"))
  waitFor(id,12,function()return prompt("Close").Enabled and prompt("Teleport").Enabled and not prompt("Open").Enabled end,"Open was not confirmed. No retry sent.")
 end
 move(id,NEAR_TELEPORT,"TELEPORT BUTTON")task.wait(.25)check(id)
 assert(prompt("Close").Enabled and prompt("Teleport").Enabled,"Tube state changed. Stopped.")
 local before=incoming
 say("Starting tube; moving inside...")activate(id,prompt("Teleport"))
 waitFor(id,2,function()return not prompt("Teleport").Enabled or incoming>before end,"Teleport unconfirmed. No retry.")
 move(id,INSIDE,"INSIDE TUBE")
 waitFor(id,20,function()return incoming>before or session()or isUp()end,"No teleport session observed. Press Copy Report.")
 say("Waiting for PAP room arrival...")
 waitFor(id,40,function()return isUp()and session()end,"PAP arrival unconfirmed. Copy report.")
 trip.inbound=incoming log("ARRIVED PAP",snapshot())
 waitFor(id,15,function()return not busy()end,"PAP machine stayed busy.")
 move(id,PAP,"PAP MACHINE")
 local pap=at(PG,"PAP")local untilTime=os.clock()+1.5
 repeat check(id)task.wait(.1)until pap.Enabled or not isUp()or os.clock()>=untilTime
 if not pap.Enabled and isUp()and session()and not busy()then
  local v=controller()check(id)if v and v.enabled then local ok,why=pcall(function()v:show_gui()end)log("SHOW MENU",ok and tostring(pap.Enabled)or tostring(why))end
 end
 say(pap.Enabled and"Choose and confirm your weapon. Waiting for game return."or"At machine. Step closer if needed; awaiting game return.")
 local stable=nil local deadline=os.clock()+150 local lastTools=tools()local lastBusy=busy()
 repeat
  check(id)watchConfirm()
  local b=busy()if b~=lastBusy then log("MACHINE BUSY",b)lastBusy=b end if b then trip.busySeen=true end
  local list=tools()if list~=lastTools then log("TOOLS",list)lastTools=list end
  if trip.expected and hasTool("PAP"..trip.expected)then trip.upgraded=true end
  local r=root()
  local returned=(r.Position-ROOM).Magnitude>70 and not session()and incoming>trip.inbound
  if returned then stable=stable or os.clock()else stable=nil end
  if stable and os.clock()-stable>=.5 then break end
  task.wait(.1)
 until os.clock()>=deadline
 assert(stable and os.clock()-stable>=.5,"Game return unconfirmed. Staying here.")
 log("GAME RETURN CONFIRMED",snapshot())
 waitFor(id,15,function()return not busy()end,"Machine still processing. Staying here.")
 if trip.expected and trip.busySeen and not trip.upgraded then
  say("Checking upgraded tool...")local untilTool=os.clock()+8
  repeat check(id)trip.upgraded=hasTool("PAP"..trip.expected)if trip.upgraded then break end task.wait(.1)until os.clock()>=untilTool
 end
 move(id,trip.origin,"ORIGINAL POSITION")task.wait(.3)
 local _,r=check(id)assert((r.Position-trip.origin.Position).Magnitude<6,"Game corrected return position. No retry.")
 say(trip.upgraded and"Complete. Upgraded tool observed; returned to start."or trip.clicked and"Returned to start. Upgrade not confirmed."or"Returned to start; no upgrade confirmed.")
end
local function report()
 return "PAP TRIP TEST REPORT\nPlaceId="..tostring(game.PlaceId).." User="..P.Name.."\nStatus="..phase.."\nRunning="..tostring(running).." IncomingTeleportEvents="..incoming.."\nOne activation per button, within range. You confirm purchases. Client observations only.\n=== Current ===\n"..snapshot().."\n=== Timeline ===\n"..table.concat(lines,"\n").."\n=== PAP TRIP REPORT END ==="
end
local event=at(storage,"Remote Events","OnTeleporting")
if event then bind(event.OnClientEvent,function()incoming+=1 log("INCOMING TELEPORT "..incoming,snapshot())end)end
local function remember()_G.HeadLockPAPTripLastReport=report()end
SC.papActivate=function()
 if not live or SC.paused or not SC.authenticated then return end
 if running then serial+=1 running=false paint(false)say("Cancelled.")SC.finishTrip("PAP")remember()return end
 if SC.fling.active then SC.stopFling()end
 local c=P.Character local r=root()if not c or not r then say("Wait for a living character.")remember()return end
 local savedOrigin=c:GetPivot()if not SC.beginTrip("PAP")then return end
 serial+=1 local id=serial trip={character=c,origin=savedOrigin}running=true paint(true)
 log("START",snapshot())
 task.spawn(function()
  local ok,why=pcall(run,id)
  if serial==id then
   running=false paint(false)SC.finishTrip("PAP")
   if not ok then say("Stopped: "..tostring(why))log("STOP SNAPSHOT",snapshot())end
   remember()
  end
 end)
end
addCategory("PAP",function(panel)
 local toggle=textButton("OFF",panel)toggle.Name="PAPToggle"toggle.Size=UDim2.new(1,0,0,40)
 SC.pap.update=function()
  local active=SC.pap.active toggle.Text=active and"ON"or"OFF"
  toggle.BackgroundColor3=active and WHITE or BLACK toggle.TextColor3=active and BLACK or WHITE
 end
 toggle.Activated:Connect(SC.papActivate)SC.pap.update()
end)
_G.HeadLockPAPTripCleanup=function()
 if not live then return end serial+=1 running=false SC.finishTrip("PAP")remember()live=false
 for _,c in ipairs(links)do pcall(function()c:Disconnect()end)end
 SC.pap.closed=true SC.pap.update=nil _G.HeadLockPAPTripCleanup=nil
end
paint(false)
SC.papStop=function()if live and running then serial+=1 running=false paint(false)say("Cancelled.")SC.finishTrip("PAP")remember()end end
SC.papCleanup=_G.HeadLockPAPTripCleanup

end
SC.installTripFeatures()
SC.installPAP()

-- INTEGRATED_VEHICLES_BEGIN
function SC.installVehicles()
 return (function(SC)
local Players=game:GetService('Players')
local Run=game:GetService('RunService')
local UIS=game:GetService('UserInputService')
local Http=game:GetService('HttpService')
local player=Players.LocalPlayer
local api={paused=false}
for _,key in ipairs({'ClassicJeepCleanup','LocalYellowCarCleanup','VehicleGarageCleanup'}) do
    if type(_G[key])=='function' then pcall(_G[key]) end
end
local CONFIG={Car=1269895074,Bike=719165150,Speed=80,Reverse=28,Acceleration=62,ReverseAcceleration=52,Brake=90,Coast=12,Turning=2}
local settingSpecs={
    {key='Speed',label='TOP SPEED',min=1,max=300,step=1},
    {key='Turning',label='TURN TIGHTNESS',min=.2,max=6,step=.05},
    {key='Acceleration',label='FORWARD ACCELERATION',min=5,max=200,step=1},
    {key='ReverseAcceleration',label='REVERSE ACCELERATION',min=5,max=200,step=1},
    {key='Reverse',label='REVERSE TOP SPEED',min=1,max=150,step=1},
    {key='Brake',label='BRAKING STRENGTH',min=10,max=250,step=1},
}
local settingsFile='LocalVehicleGarage_Settings.json'
local buttonsVisible=true
local function acceptSettings(saved)
    if type(saved)~='table' then return end
    for _,spec in ipairs(settingSpecs) do
        local value=saved[spec.key]
        if type(value)=='number' and value==value then CONFIG[spec.key]=math.clamp(value,spec.min,spec.max) end
    end
    if type(saved.ButtonsVisible)=='boolean' then buttonsVisible=saved.ButtonsVisible end
end
acceptSettings(_G.VehicleGarageSettings)
if type(readfile)=='function' and type(isfile)=='function' then
    pcall(function() if isfile(settingsFile) then acceptSettings(Http:JSONDecode(readfile(settingsFile))) end end)
end
local function saveSettings()
    local saved={ButtonsVisible=buttonsVisible}
    for _,spec in ipairs(settingSpecs) do saved[spec.key]=CONFIG[spec.key] end
    _G.VehicleGarageSettings=saved
    if type(writefile)=='function' then pcall(function() writefile(settingsFile,Http:JSONEncode(saved)) end) end
end
local UP=Vector3.new(0,1,0)
local ZERO=Vector3.zero
local folder=Instance.new('Folder'); folder.Name='LocalVehicleGarage'; folder.Parent=workspace
local gui=Instance.new('ScreenGui')
gui.Name='VehicleGarageUI'; gui.ResetOnSpawn=false; gui.IgnoreGuiInset=false; gui.DisplayOrder=9999
gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; gui.Parent=player:WaitForChild('PlayerGui')
local connections={}
local function listen(signal,fn)
    local c=signal:Connect(fn); table.insert(connections,c); return c
end
local function make(class,parent,props)
    local o=Instance.new(class)
    if class=='TextButton' or class=='TextLabel' or class=='TextBox' then o.Font=Enum.Font.Code end
    for k,v in pairs(props or {}) do o[k]=v end
    o.Parent=parent; return o
end
local function round(o) make('UIStroke',o,{Color=Color3.new(1,1,1),Thickness=1,ApplyStrokeMode=Enum.ApplyStrokeMode.Border}) end
local layout={Gas={x=.87,y=.70,size=68},Brake={x=.76,y=.81,size=68},Left={x=.09,y=.73,size=68},Right={x=.20,y=.73,size=68}}
local function acceptLayout(saved)
    if type(saved)~='table' then return end
    for name,def in pairs(layout) do
        local p=saved[name]
        if type(p)=='table' and type(p.x)=='number' and type(p.y)=='number' and type(p.size)=='number'
            and p.x==p.x and p.y==p.y and p.size==p.size then
            def.x=math.clamp(p.x,.03,.97); def.y=math.clamp(p.y,.05,.95)
            def.size=math.clamp(p.size,44,118)
        end
    end
end
acceptLayout(_G.VehicleGarageLayout)
local layoutFile='LocalVehicleGarage_Controls.json'
if type(readfile)=='function' and type(isfile)=='function' then
    pcall(function() if isfile(layoutFile) then acceptLayout(Http:JSONDecode(readfile(layoutFile))) end end)
end
local vehicles={}
local active=nil
local held={Gas={},Brake={},Left={},Right={}}
local inputOwners={}
local controls={}
local body,status
local lastStatus="Spawn a vehicle, then walk onto its seat."
local menuLinks={}
local sliderViews={}
local function menuListen(signal,fn)
 local c=signal:Connect(fn); table.insert(menuLinks,c); return c
end
local sliderDrag=nil
local closed=false
local busy=false
local exitRide,deleteVehicle
local function resetHeld()
    for name in pairs(held) do
        held[name]={}
        if controls[name] then
            controls[name].BackgroundColor3=Color3.new(0,0,0)
            controls[name].TextColor3=Color3.new(1,1,1)
        end
    end
    inputOwners={}
end
local function isHeld(name) return next(held[name])~=nil end
local function viewport() return gui.AbsoluteSize end
local function refreshControl(name)
    local b=controls[name]; local l=layout[name]
    b.Size=UDim2.fromOffset(l.size,l.size)
    b.Position=UDim2.fromScale(l.x,l.y)
    b.BackgroundColor3=Color3.new(0,0,0)
    b.TextColor3=Color3.new(1,1,1)
    b.Visible=buttonsVisible and not api.paused
end
for _,name in ipairs({'Gas','Brake','Left','Right'}) do
    local b=make('TextButton',gui,{Name=name,AnchorPoint=Vector2.new(.5,.5),Text=string.upper(name),
        TextColor3=Color3.new(1,1,1),Font=Enum.Font.Code,TextSize=15,
        BackgroundTransparency=0,AutoButtonColor=false,Active=true,ZIndex=3})
    round(b); controls[name]=b; refreshControl(name)
    listen(b.InputBegan,function(input)
        if input.UserInputType~=Enum.UserInputType.Touch and input.UserInputType~=Enum.UserInputType.MouseButton1 then return end
        if active and buttonsVisible and not api.paused then
            held[name][input]=true; inputOwners[input]=name
            b.BackgroundColor3=Color3.new(1,1,1)
            b.TextColor3=Color3.new(0,0,0)
        end
    end)
end
local function report(message)
    lastStatus=message
    if status and status.Parent and not closed then status.Text=message end
end
local function menuButton(text,x,y,w,callback)
    local b=make('TextButton',body,{Text=text,Position=x==114 and UDim2.new(.5,0,0,y) or UDim2.fromOffset(x,y),Size=w==222 and UDim2.new(1,-8,0,34) or UDim2.new(.5,-8,0,34),
        BackgroundColor3=Color3.new(0,0,0),TextColor3=Color3.new(1,1,1),
        Font=Enum.Font.Code,TextSize=13,ZIndex=7})
    round(b); menuListen(b.Activated,callback); return b
end
local function refreshSlider(spec)
    local view=sliderViews[spec.key]
    if not view then return end
    local value=CONFIG[spec.key]
    local fraction=(value-spec.min)/(spec.max-spec.min)
    view.fill.Size=UDim2.fromScale(fraction,1)
    view.knob.Position=UDim2.fromScale(fraction,.5)
    view.entry.Text=spec.key=='Turning' and string.format('%.2fx',value) or tostring(math.floor(value+.5))
end
local function sliderAt(input)
    local item=sliderDrag and sliderViews[sliderDrag.key]
    if not item or not item.track.Parent then return end
    local spec=item.spec
    local fraction=math.clamp((input.Position.X-item.track.AbsolutePosition.X)/math.max(1,item.track.AbsoluteSize.X),0,1)
    CONFIG[spec.key]=math.clamp(math.floor((spec.min+fraction*(spec.max-spec.min))/spec.step+.5)*spec.step,spec.min,spec.max)
    refreshSlider(spec)
end
listen(UIS.InputChanged,function(input)
    if sliderDrag and (input==sliderDrag.input or (sliderDrag.input.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseMovement)) then
        sliderAt(input); return
    end
end)
listen(UIS.InputEnded,function(input)
    local name=inputOwners[input]
    if name then
        held[name][input]=nil; inputOwners[input]=nil
        if not isHeld(name) then refreshControl(name) end
    end
    if input.UserInputType==Enum.UserInputType.MouseButton1 then
        for key,owner in pairs(inputOwners) do
            if key.UserInputType==Enum.UserInputType.MouseButton1 then held[owner][key]=nil; inputOwners[key]=nil; refreshControl(owner) end
        end
    end
    if sliderDrag and (input==sliderDrag.input or input.UserInputType==Enum.UserInputType.MouseButton1) then
        sliderDrag=nil; if body and body.Parent then body.ScrollingEnabled=true end; saveSettings()
    end
end)
listen(UIS.WindowFocusReleased,function()
    resetHeld(); sliderDrag=nil; if body and body.Parent then body.ScrollingEnabled=true end
    for name in pairs(controls) do refreshControl(name) end
    saveSettings()
end)

local function character()
    local c=player.Character
    local h=c and c:FindFirstChildWhichIsA('Humanoid')
    local r=c and c:FindFirstChild('HumanoidRootPart')
    if not h or not r or h.Health<=0 then return end
    return c,h,r
end
local function weld(a,b)
    local w=Instance.new('WeldConstraint'); w.Part0=a; w.Part1=b; w.Parent=b; return w
end
-- Keep every player's avatar out of local vehicle collisions and ground probes.
local trackedCharacters={}
local function refreshGroundFilters()
    local exclusions={folder}
    for c in pairs(trackedCharacters) do table.insert(exclusions,c) end
    for _,v in ipairs(vehicles) do v.ray.FilterDescendantsInstances=exclusions end
end
local function protectAvatar(v,c)
    v.avatarContacts=v.avatarContacts or {}
    for _,p in ipairs(c:GetDescendants()) do
        if p:IsA('BasePart') and not v.avatarContacts[p] then
            local nc=make('NoCollisionConstraint',v.hull,{Part0=p,Part1=v.hull})
            v.avatarContacts[p]={constraint=nc,character=c}
        end
    end
end
local function trackCharacter(c)
    if trackedCharacters[c] then return end
    local record={}; trackedCharacters[c]=record
    for _,v in ipairs(vehicles) do protectAvatar(v,c) end
    record.added=listen(c.DescendantAdded,function(p)
        if p:IsA('BasePart') then
            for _,v in ipairs(vehicles) do
                if not v.dead then protectAvatar(v,c) end
            end
        end
    end)
    refreshGroundFilters()
end
local function untrackCharacter(c)
    local record=trackedCharacters[c]
    if record and record.added then record.added:Disconnect() end
    trackedCharacters[c]=nil
    for _,v in ipairs(vehicles) do
        for p,entry in pairs(v.avatarContacts or {}) do
            if entry.character==c then entry.constraint:Destroy(); v.avatarContacts[p]=nil end
        end
    end
    refreshGroundFilters()
end
local function watchPlayer(p)
    listen(p.CharacterAdded,trackCharacter)
    listen(p.CharacterRemoving,untrackCharacter)
    if p.Character then trackCharacter(p.Character) end
end
for _,p in ipairs(Players:GetPlayers()) do watchPlayer(p) end
listen(Players.PlayerAdded,watchPlayer)
listen(Players.PlayerRemoving,function(p) if p.Character then untrackCharacter(p.Character) end end)

local cameraBinding='VehicleGarageCamera_'..tostring(player.UserId or 0)
Run:BindToRenderStep(cameraBinding,Enum.RenderPriority.Camera.Value-1,function(dt)
    local v=active
    if not v or not v.driver or not v.driver.cameraAnchor or v.dead then return end
    local driver=v.driver
    local desired=(v.seat.CFrame*CFrame.new(0,v.seat.Size.Y/2+3,0)).Position
    local velocity=v.hull:GetVelocityAtPosition(desired)
    local alpha=1-math.exp(-22*math.min(dt,.1))
    driver.cameraPosition=driver.cameraPosition:Lerp(desired+velocity*.025,alpha)
    driver.cameraAnchor.CFrame=CFrame.new(driver.cameraPosition)
end)

local function beginRide(v,c,h,r)
    if active or v.dead or api.paused then return end
    if SC.autoWin and SC.autoWin.enabled then SC.setAutoWin(false) end
    SC.stopConflictingMovement()
    SC.gravity.enabled=false; SC.stopGravity()
    -- The disabled Seat is only a contact trigger. It must never create a
    -- SeatWeld, which merges the character with the client-only vehicle.
    v.seat.Disabled=true
    local stale=v.seat:FindFirstChild('SeatWeld')
    if stale then stale:Destroy() end
    active=v
    v.driver={char=c,hum=h,root=r,auto=h.AutoRotate,assemblyRoot=r.AssemblyRootPart}
    h.AutoRotate=false
    h.Sit=true
    protectAvatar(v,c)
    local attachment=make('Attachment',r,{Name='GarageDriverAttachment'})
    local target=v.seat.CFrame*CFrame.new(0,v.seat.Size.Y/2+1.5,0)
    local mass=math.max(r.AssemblyMass,1)
    -- OneAttachment mode uses a WORLD target, not an attachment on the car.
    -- Neither this constraint nor the orientation constraint connects the
    -- driver's physics mechanism to any client-created vehicle part.
    local follow=make('AlignPosition',r,{
        Name='GarageDriverFollow',Attachment0=attachment,
        Mode=Enum.PositionAlignmentMode.OneAttachment,Position=target.Position,
        ApplyAtCenterOfMass=true,ReactionForceEnabled=false,RigidityEnabled=false,
        ForceLimitMode=Enum.ForceLimitMode.Magnitude,MaxForce=mass*4000,
        MaxVelocity=500,Responsiveness=60})
    local facing=make('AlignOrientation',r,{
        Name='GarageDriverFacing',Attachment0=attachment,
        Mode=Enum.OrientationAlignmentMode.OneAttachment,AlignType=Enum.AlignType.AllAxes,
        CFrame=target.Rotation,ReactionTorqueEnabled=false,RigidityEnabled=false,
        MaxTorque=mass*40000,MaxAngularVelocity=16,Responsiveness=50})
    v.driver.follow=follow; v.driver.facing=facing
    v.driver.objects={follow,facing,attachment}
    local camera=workspace.CurrentCamera
    if camera then
        local anchor=make('Part',folder,{Name='SmoothVehicleCamera',Size=Vector3.new(.1,.1,.1),
            CFrame=CFrame.new(target.Position+UP*1.5),Anchored=true,Transparency=1,
            CanCollide=false,CanTouch=false,CanQuery=false})
        v.driver.camera=camera; v.driver.previousSubject=camera.CameraSubject
        v.driver.cameraAnchor=anchor; v.driver.cameraPosition=anchor.Position
        table.insert(v.driver.objects,anchor)
        camera.CameraSubject=anchor
    end
    resetHeld()
    report('Driving '..v.kind..'. Jump exits. Character moves independently.')
end
exitRide=function()
    local v=active; if not v then return end
    active=nil; resetHeld(); v.lastExit=os.clock()
    local driver=v.driver; v.driver=nil
    if driver then
        if driver.camera and driver.camera.CameraSubject==driver.cameraAnchor then
            driver.camera.CameraSubject=(driver.previousSubject and driver.previousSubject.Parent) and driver.previousSubject or driver.hum
        end
        for _,obj in ipairs(driver.objects or {}) do obj:Destroy() end
    end
    local sw=v.seat:FindFirstChild('SeatWeld'); if sw then sw:Destroy() end
    v.seat.Disabled=true
    if driver and driver.hum.Parent then
        driver.hum.AutoRotate=driver.auto; driver.hum.Sit=false
        driver.hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end
    local constraints=v.driverConstraints; v.driverConstraints={}
    task.delay(.8,function()
        for _,n in ipairs(constraints) do n:Destroy() end
        -- Keep the contact seat disabled: no native SeatWeld should be created.
    end)
    report('Exited. Walk onto any vehicle seat to drive.')
end
listen(UIS.JumpRequest,exitRide)
listen(UIS.InputBegan,function(input,processed)
    if not processed and input.KeyCode==Enum.KeyCode.Space then exitRide() end
end)
listen(player.CharacterRemoving,exitRide)
local function bounds(entries,ref)
    local lo=Vector3.new(math.huge,math.huge,math.huge)
    local hi=Vector3.new(-math.huge,-math.huge,-math.huge)
    for _,p in ipairs(entries) do
        for _,x in ipairs({-1,1}) do for _,y in ipairs({-1,1}) do for _,z in ipairs({-1,1}) do
            local q=ref:PointToObjectSpace(p.CFrame:PointToWorldSpace(p.Size*Vector3.new(x,y,z)/2))
            lo=Vector3.new(math.min(lo.X,q.X),math.min(lo.Y,q.Y),math.min(lo.Z,q.Z))
            hi=Vector3.new(math.max(hi.X,q.X),math.max(hi.Y,q.Y),math.max(hi.Z,q.Z))
        end end end
    end
    return lo,hi
end
local function nearbySpawn(c,r,extent,averageRadius,lo,hi,origin,yawLook)
-- Try only the nearest front/right/left/rear slots. Never grow
-- a serial grid that pushes later spawns away from the character.
local right=Vector3.new(-yawLook.Z,0,yawLook.X)
local ahead=math.max(5,extent.Z/2+3)
local beside=math.max(4,extent.X/2+3)
local rp=RaycastParams.new(); rp.FilterType=Enum.RaycastFilterType.Exclude
local exclusions={folder}
for tracked in pairs(trackedCharacters) do table.insert(exclusions,tracked) end
rp.FilterDescendantsInstances=exclusions; rp.RespectCanCollide=true
local overlap=OverlapParams.new(); overlap.FilterType=Enum.RaycastFilterType.Exclude
local ignored={c}
for tracked in pairs(trackedCharacters) do table.insert(ignored,tracked) end
overlap.FilterDescendantsInstances=ignored; overlap.RespectCanCollide=true
local spawnCF
for _,offset in ipairs({yawLook*ahead,right*beside,-right*beside,-yawLook*ahead}) do
    local candidate=r.Position+offset
    local floor=workspace:Raycast(candidate+UP*6,-UP*16,rp)
    if floor and floor.Normal.Y>.4 then
        candidate=Vector3.new(candidate.X,floor.Position.Y+averageRadius*1.5+.25,candidate.Z)
        local cf=CFrame.lookAt(candidate,candidate+yawLook)
        local geometryOffset=(lo+hi)/2-origin
        local box=cf*CFrame.new(geometryOffset+UP*.2)
        local clear=true
        for _,part in ipairs(workspace:GetPartBoundsInBox(box,Vector3.new(extent.X+.3,math.max(.5,extent.Y-.4),extent.Z+.3),overlap)) do
            if part.CanCollide then clear=false; break end
        end
        if clear then spawnCF=cf; break end
    end
end
assert(spawnCF,'No clear space beside you. Move a few steps and try again.')
return spawnCF,rp
end
local function newVehicle(kind)
    if busy then return end
    local c,h,r=character(); if not c then report('Spawn your character first.'); return end
    busy=true; report('Loading '..kind..'…')
    task.spawn(function()
        local model
        local success,err=pcall(function()
            local objects=game:GetObjects('rbxassetid://'..CONFIG[kind])
            model=objects and objects[1]
            if closed then if model then model:Destroy() end; return end
            assert(model,'Asset loader returned no model.')
            assert(player.Character==c and h.Parent and h.Health>0,'Your character changed while loading. Spawn the vehicle again.')
            if not model:IsA('Model') then
                local wrapper=Instance.new('Model'); model.Parent=wrapper; model=wrapper
            end
            local sourceSeat=model:FindFirstChildWhichIsA('VehicleSeat',true) or model:FindFirstChildWhichIsA('Seat',true)
            assert(sourceSeat,'Model has no seat; cannot determine its forward direction.')
            local ref=sourceSeat.CFrame
            local originalParts,visibleParts,wheelParts={},{},{}
            for _,p in ipairs(model:GetDescendants()) do
                if p:IsA('BasePart') then
                    p.Anchored=true; table.insert(originalParts,p)
                    if p.Transparency<.95 then table.insert(visibleParts,p) end
                    local ancestor=p; local wheel=false
                    while ancestor and ancestor~=model do
                        local name=string.lower(ancestor.Name)
                        if string.find(name,'wheel',1,true) or string.find(name,'tire',1,true) or string.find(name,'tyre',1,true) or (name=='rim' or string.match(name,'^rim[%s_%-%.%d]')) then wheel=true end
                        ancestor=ancestor.Parent
                    end
                    if wheel and p.Transparency<.95 then table.insert(wheelParts,p) end
                end
            end
            assert(#visibleParts>0,'No visible geometry in this model.')
            for _,p in ipairs(model:GetDescendants()) do
                if p:IsA('LuaSourceContainer') or p:IsA('JointInstance') or p:IsA('Constraint') or p:IsA('BodyMover') then p:Destroy() end
            end
            local lo,hi=bounds(visibleParts,ref); local extent=hi-lo
            -- Preserve the downloaded geometry; classify only likely road wheels.
            local groups=kind=='Bike' and {{},{}} or {{},{},{},{}}
            local midZ=(lo.Z+hi.Z)/2
            local wheelSet={}
            for _,p in ipairs(wheelParts) do
                local localPos=ref:PointToObjectSpace(p.Position)
                if localPos.Y<lo.Y+extent.Y*.55 then
                    local index=localPos.Z<midZ and 1 or 2
                    if kind=='Car' then index=(localPos.X<0 and 1 or 2)+(localPos.Z>midZ and 2 or 0) end
                    table.insert(groups[index],p); wheelSet[p]=true
                end
            end
            local wheelInfo={}; local averageY=0; local averageRadius=0
            for i,g in ipairs(groups) do
                local center,radius
                if #g>0 then
                    local a,b=bounds(g,ref); center=(a+b)/2
                    radius=math.clamp(math.max(b.Y-a.Y,b.Z-a.Z)/2,.65,2.3)
                else
                    radius=math.clamp(extent.Y*.18,.85,1.7)
                    local front=kind=='Bike' and i==1 or kind=='Car' and i<=2
                    center=Vector3.new(kind=='Bike' and (lo.X+hi.X)/2 or (i%2==1 and lo.X+radius*.35 or hi.X-radius*.35),lo.Y+radius,midZ+(front and -1 or 1)*extent.Z*.32)
                end
                wheelInfo[i]={position=center,radius=radius,parts=g}
                averageY=averageY+center.Y/#groups; averageRadius=averageRadius+radius/#groups
            end
            local origin=Vector3.new((lo.X+hi.X)/2,averageY+averageRadius*.5,midZ)
            local chassisRef=ref*CFrame.new(origin)
            local yawLook=r.CFrame.LookVector; yawLook=Vector3.new(yawLook.X,0,yawLook.Z)
            yawLook=yawLook.Magnitude>.01 and yawLook.Unit or Vector3.new(0,0,-1)
            local spawnCF,rp=nearbySpawn(c,r,extent,averageRadius,lo,hi,origin,yawLook)
            local hull=make('Part',model,{Name='StableChassis',Size=Vector3.new(math.max(kind=='Bike' and 1.2 or 2.5,extent.X*.70),.8,math.max(3,extent.Z*.70)),
                CFrame=spawnCF,Transparency=1,Anchored=true,CanCollide=true,CanTouch=false,RootPriority=-127,
                CustomPhysicalProperties=PhysicalProperties.new(2,.15,0,100,100)})
            local v={model=model,hull=hull,kind=kind,wheels={},links={},driverConstraints={},lastExit=-10,
                heading=math.atan2(-yawLook.X,-yawLook.Z),steer=0,dead=false,ray=rp,normal=UP}
            model.PrimaryPart=hull; model.Name='Local'..kind
            -- Replace VehicleSeat with a passive Seat so the native mobile vehicle
            -- controller never injects a competing throttle or steering signal.
            local seatCF=chassisRef:ToObjectSpace(sourceSeat.CFrame); local seatSize=sourceSeat.Size
            sourceSeat.Transparency=1; sourceSeat.CanTouch=false
            local seat=make('Seat',model,{Name='DriverSeat',Size=seatSize,CFrame=spawnCF*seatCF,
                Transparency=1,Anchored=true,CanCollide=false,CanTouch=true,Massless=true,Disabled=true})
            v.seat=seat; weld(hull,seat)
            for _,p in ipairs(originalParts) do
                local localCF=chassisRef:ToObjectSpace(p.CFrame)
                p.CFrame=spawnCF*localCF; p.CanCollide=false; p.CanTouch=false; p.CanQuery=false; p.Massless=true; p.RootPriority=-127
                if p:IsA('Seat') or p:IsA('VehicleSeat') then p.Disabled=true end
                if not wheelSet[p] then weld(hull,p) end
            end
            for i,w in ipairs(wheelInfo) do
                local pos=w.position-origin
                local mount=make('Attachment',hull,{Position=pos+UP*1.2})
                local force=make('VectorForce',hull,{Attachment0=mount,RelativeTo=Enum.ActuatorRelativeTo.World,Force=ZERO,ApplyAtCenterOfMass=false})
                local wheel={mount=mount,force=force,position=pos,radius=w.radius,rest=1.2,travel=2.7,angle=0,joints={},height=0,front=kind=='Bike' and i==1 or kind=='Car' and i<=2}
                for _,p in ipairs(w.parts) do
                    local original=spawnCF:ToObjectSpace(p.CFrame)
                    local joint=make('Motor6D',hull,{Name='VisualWheel',Part0=hull,Part1=p,C0=CFrame.new(pos),C1=original:Inverse()*CFrame.new(pos)})
                    table.insert(wheel.joints,joint)
                end
                table.insert(v.wheels,wheel)
            end
            local att=make('Attachment',hull)
            v.drive=make('VectorForce',hull,{Attachment0=att,RelativeTo=Enum.ActuatorRelativeTo.World,ApplyAtCenterOfMass=true,Force=ZERO})
            v.balance=make('AlignOrientation',hull,{Attachment0=att,Mode=Enum.OrientationAlignmentMode.OneAttachment,
                AlignType=Enum.AlignType.AllAxes,Responsiveness=20,MaxAngularVelocity=12,MaxTorque=100000,RigidityEnabled=false,CFrame=spawnCF.Rotation})
            model.Parent=folder
            for _,p in ipairs(model:GetDescendants()) do if p:IsA('BasePart') then p.Anchored=false end end
            table.insert(vehicles,v)
            for c in pairs(trackedCharacters) do protectAvatar(v,c) end
            refreshGroundFilters()
            local function on(signal,fn) local connection=signal:Connect(fn); table.insert(v.links,connection) end
            on(seat.Touched,function(hit)
                local cc,hh,rr=character()
                if not cc or active or v.dead or os.clock()-v.lastExit<1 or not hit:IsDescendantOf(cc) then return end
                if (rr.Position-seat.Position).Magnitude>6 then return end
                beginRide(v,cc,hh,rr)
            end)
            report(kind..' spawned. '..#vehicles..' total. Walk onto its seat.')
        end)
        if not success then if model then model:Destroy() end; report('Load failed: '..string.sub(tostring(err),1,150)) end
        busy=false
    end)
end
deleteVehicle=function(v)
    if not v or v.dead then return end
    if active==v then exitRide() end
    v.dead=true
    for _,c in ipairs(v.links) do c:Disconnect() end
    v.model:Destroy()
    for i,item in ipairs(vehicles) do if item==v then table.remove(vehicles,i); break end end
end
local function longitudinalAcceleration(speed,gas,brake,driven)
    local target,rate=0,CONFIG.Coast
    if driven then
        if brake then
            -- Holding BRAKE crosses smoothly through zero into reverse.
            target=-CONFIG.Reverse
            rate=speed>.15 and CONFIG.Brake or CONFIG.ReverseAcceleration
            if gas then target=0; rate=CONFIG.Brake end
        elseif gas then
            target=CONFIG.Speed
            rate=speed<-.15 and CONFIG.Brake or CONFIG.Acceleration
        end
    else rate=CONFIG.Brake end
    -- Acceleration is applied to actual measured speed immediately.
    -- No target-speed ramp followed by a second slow response filter.
    local driveAcceleration=math.clamp((target-speed)*14,-rate,rate)
    return driveAcceleration
end
local function inputs()
    local gas,brake=isHeld('Gas'),isHeld('Brake')
    local turn=(isHeld('Right') and 1 or 0)-(isHeld('Left') and 1 or 0)
    if not UIS:GetFocusedTextBox() then
        gas=gas or UIS:IsKeyDown(Enum.KeyCode.W) or UIS:IsKeyDown(Enum.KeyCode.Up)
        brake=brake or UIS:IsKeyDown(Enum.KeyCode.S) or UIS:IsKeyDown(Enum.KeyCode.Down)
        if UIS:IsKeyDown(Enum.KeyCode.A) or UIS:IsKeyDown(Enum.KeyCode.Left) then turn=turn-1 end
        if UIS:IsKeyDown(Enum.KeyCode.D) or UIS:IsKeyDown(Enum.KeyCode.Right) then turn=turn+1 end
    end
    if api.paused then return false,false,0 end
    return gas,brake,math.clamp(turn,-1,1)
end
local function sampleGround(v,wheel,origin)
    local probeRadius=wheel.radius*.8
    local extra=wheel.radius-probeRadius
    local hit=workspace:Spherecast(origin,probeRadius,-UP*(wheel.travel+extra),v.ray)
    if hit and hit.Normal.Y>.35 then return hit,hit.Distance-extra end
    -- Spherecasts miss surfaces overlapping the starting sphere. A raised ray
    -- keeps suspension support when a wheel is briefly compressed into a step.
    local raise=wheel.radius*1.25
    hit=workspace:Raycast(origin+UP*raise,-UP*(wheel.travel+raise+wheel.radius),v.ray)
    if hit and hit.Normal.Y>.35 then
        return hit,hit.Distance-raise-wheel.radius
    end
    return nil,wheel.travel
end
local lastError=0
listen(Run.PreSimulation,function(dt)
    dt=math.min(dt,.05)
    local cc,hh=character()
    if active and (api.paused or not hh or active.driver.hum~=hh or (SC.autoWin and SC.autoWin.enabled)) then exitRide() end
    if active and hh then
        -- Ignore the mobile walking stick while driving. Touch buttons supply
        -- independent inputs, so native walking controls cannot fight the seat.
        hh:Move(ZERO,false)
        local v=active
        local driver=v.driver
        local target=v.seat.CFrame*CFrame.new(0,v.seat.Size.Y/2+1.5,0)
        driver.follow.Position=target.Position+v.hull:GetVelocityAtPosition(target.Position)*math.min(dt,.025)*.5
        driver.follow.MaxVelocity=math.max(500,CONFIG.Speed*2)
        driver.facing.CFrame=target.Rotation
    end
    local gas,brake,turn=inputs()
    for _,v in ipairs(vehicles) do
        if not v.dead and v.model.Parent then
            local success,err=pcall(function()
                local hull=v.hull; local cf=hull.CFrame
                local mass=hull.AssemblyMass
                if mass==math.huge or mass<=0 then return end
                local forward=cf.LookVector; local lateral=cf.RightVector
                local velocity=hull.AssemblyLinearVelocity
                local speed=velocity:Dot(forward)
                local driven=active==v
                local driveAcceleration=longitudinalAcceleration(speed,gas,brake,driven)
                v.steer=v.steer+((driven and turn or 0)-v.steer)*(1-math.exp(-24*dt))
                local support=0; local normalSum=ZERO
                for _,wheel in ipairs(v.wheels) do
                    local origin=wheel.mount.WorldPosition
                    local hit,distance=sampleGround(v,wheel,origin)
                    if hit then
                        local quarterMass=mass/#v.wheels
                        local stiffness=quarterMass*workspace.Gravity/1.1
                        local damping=2*math.sqrt(stiffness*quarterMass)*.9
                        local pointVelocity=hull:GetVelocityAtPosition(origin):Dot(UP)
                        local load=quarterMass*workspace.Gravity+(wheel.rest-distance)*stiffness-pointVelocity*damping
                        wheel.force.Force=UP*math.clamp(load,0,quarterMass*workspace.Gravity*3.5)
                        support=support+1; normalSum=normalSum+hit.Normal
                    else wheel.force.Force=ZERO end
                    wheel.height=wheel.height+(math.clamp(wheel.rest-distance,-1.2,1.2)-wheel.height)*(1-math.exp(-14*dt))
                    wheel.angle=(wheel.angle+speed/wheel.radius*dt)%(math.pi*2)
                    -- The wheel hub has the vehicle's axes, so rotation is applied
                    -- about its actual axle, independent of each mesh's orientation.
                    local steerAngle=wheel.front and -v.steer*math.rad(math.clamp(18+CONFIG.Turning*8,18,58))/(1+math.abs(speed)/140) or 0
                    for _,joint in ipairs(wheel.joints) do
                        joint.Transform=CFrame.new(0,wheel.height,0)*CFrame.Angles(0,steerAngle,0)*CFrame.Angles(wheel.angle,0,0)
                    end
                end
                if support>0 then
                    local raw=normalSum.Unit
                    local slope=Vector3.new(raw.X*.65,math.max(.75,raw.Y),raw.Z*.65).Unit
                    v.normal=v.normal:Lerp(slope,1-math.exp(-5*dt)).Unit
                    local yawRate=-v.steer*math.clamp(speed/7,-1,1)*2*CONFIG.Turning/(1+math.abs(speed)/140)
                    v.heading=v.heading+yawRate*dt
                    local gripLimit=100+CONFIG.Turning*70
                    local grip=math.clamp(-velocity:Dot(lateral)*(10+CONFIG.Turning*2),-gripLimit,gripLimit)
                    local traction=(forward*driveAcceleration+lateral*grip)*mass
                    v.drive.Force=traction*math.min(1,support/2)
                else
                    v.drive.Force=ZERO
                    v.normal=v.normal:Lerp(UP,1-math.exp(-2*dt)).Unit
                end
                local facing=Vector3.new(-math.sin(v.heading),0,-math.cos(v.heading))
                local tangent=facing-v.normal*facing:Dot(v.normal)
                if tangent.Magnitude>.01 then v.balance.CFrame=CFrame.lookAt(ZERO,tangent.Unit,v.normal) end
                v.balance.MaxTorque=mass*workspace.Gravity*math.max(5,hull.Size.Z)*2
            end)
            if not success and os.clock()-lastError>3 then
                lastError=os.clock(); report('Vehicle error: '..string.sub(tostring(err),1,130)); warn(err)
            end
        end
    end
end)
function api.cleanup()
    if closed then return end
    while #vehicles>0 do deleteVehicle(vehicles[#vehicles]) end
    api.unmount()
    closed=true
    Run:UnbindFromRenderStep(cameraBinding)
    for _,c in ipairs(connections) do c:Disconnect() end
    folder:Destroy(); gui:Destroy(); _G.VehicleGarageCleanup=nil
end


function api.unmount()
    if sliderDrag then saveSettings() end
    sliderDrag=nil; sliderViews={}
    for _,c in ipairs(menuLinks) do c:Disconnect() end
    table.clear(menuLinks)
    body=nil; status=nil
end
function api.setPaused(value)
    api.paused=value==true
    if api.paused then exitRide() end
    resetHeld()
    for name in pairs(controls) do refreshControl(name) end
end
function api.draw(container)
    api.unmount()
    body=make('ScrollingFrame',container,{Name='VehicleSettings',Size=UDim2.fromScale(1,1),
        BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,
        CanvasSize=UDim2.fromOffset(0,802),ScrollingDirection=Enum.ScrollingDirection.Y,Active=true})
    make('TextLabel',body,{Size=UDim2.new(1,0,0,30),BackgroundTransparency=1,Text='Vehicles',
        TextColor3=Color3.new(1,1,1),Font=Enum.Font.Code,TextSize=20,TextXAlignment=Enum.TextXAlignment.Left})
    menuButton('Spawn Car',0,40,222,function() newVehicle('Car') end)
    menuButton('Spawn Motorcycle',0,82,222,function() newVehicle('Bike') end)
    menuButton('Delete One',0,124,108,function()
        deleteVehicle(active or vehicles[#vehicles]); report(#vehicles..' vehicles remaining.')
    end)
    menuButton('Delete All',114,124,108,function()
        while #vehicles>0 do deleteVehicle(vehicles[#vehicles]) end
        report('All spawned vehicles deleted.')
    end)
    menuButton('Exit Vehicle',0,166,222,exitRide)
local toggle
local function toggleText() toggle.Text=buttonsVisible and 'Controls: ON' or 'Controls: OFF' end
toggle=menuButton('Controls',0,210,222,function()
    buttonsVisible=not buttonsVisible; resetHeld()
    for name in pairs(controls) do refreshControl(name) end
    toggleText(); saveSettings()
    report(buttonsVisible and 'Driving buttons shown.' or 'Driving buttons hidden. Keyboard controls still work.')
end)
toggleText()
for index,spec in ipairs(settingSpecs) do
    local y=258+(index-1)*82
    make('TextLabel',body,{Position=UDim2.fromOffset(0,y),Size=UDim2.new(1,-78,0,20),BackgroundTransparency=1,
        Text=spec.label,TextXAlignment=Enum.TextXAlignment.Left,TextColor3=Color3.new(1,1,1),TextSize=11,Font=Enum.Font.Code,ZIndex=7})
    local entry=make('TextBox',body,{Name=spec.key..'Value',Position=UDim2.new(1,-70,0,y-2),Size=UDim2.fromOffset(58,24),
        BackgroundColor3=Color3.new(0,0,0),TextColor3=Color3.new(1,1,1),TextSize=12,Font=Enum.Font.Code,
        ClearTextOnFocus=false,Text='',ZIndex=8})
    round(entry)
    -- A 34px touch target surrounds the thinner visible slider.
    local track=make('TextButton',body,{Name=spec.key..'Slider',Position=UDim2.fromOffset(4,y+24),Size=UDim2.new(1,-20,0,34),
        Text='',BackgroundTransparency=1,AutoButtonColor=false,Active=true,ZIndex=8})
    local rail=make('Frame',track,{Position=UDim2.fromScale(0,.4),Size=UDim2.fromScale(1,.2),BackgroundColor3=Color3.new(0,0,0),BorderSizePixel=0,ZIndex=8})
    round(rail)
    local fill=make('Frame',rail,{Size=UDim2.fromScale(0,1),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,ZIndex=8})
    round(fill)
    local knob=make('Frame',track,{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(0,.5),Size=UDim2.fromOffset(18,24),
        BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,ZIndex=9})
    round(knob)
    if spec.key=='Turning' then
        make('TextLabel',body,{Position=UDim2.fromOffset(4,y+58),Size=UDim2.new(1,-20,0,17),BackgroundTransparency=1,
            Text='WIDE     →     MEDIUM     →     VERY TIGHT',TextSize=9,Font=Enum.Font.Code,TextColor3=Color3.new(1,1,1),ZIndex=7})
    end
    sliderViews[spec.key]={spec=spec,track=track,fill=fill,knob=knob,entry=entry}
    refreshSlider(spec)
    menuListen(track.InputBegan,function(input)
        if input.UserInputType~=Enum.UserInputType.Touch and input.UserInputType~=Enum.UserInputType.MouseButton1 then return end
        sliderDrag={input=input,key=spec.key}; body.ScrollingEnabled=false; sliderAt(input)
    end)
    menuListen(entry.FocusLost,function()
        local value=tonumber((entry.Text:gsub('[xX]','')))
        if value and value==value then CONFIG[spec.key]=math.clamp(value,spec.min,spec.max) end
        refreshSlider(spec); saveSettings()
    end)
end

    status=make('TextLabel',body,{Name='VehicleStatus',Position=UDim2.fromOffset(0,754),Size=UDim2.new(1,-8,0,42),
        BackgroundTransparency=1,Text=lastStatus,TextWrapped=true,TextSize=12,
        Font=Enum.Font.Code,TextColor3=Color3.new(1,1,1),TextXAlignment=Enum.TextXAlignment.Left})
end
api.spawn=newVehicle
api.exit=exitRide
api.deleteAll=function() while #vehicles>0 do deleteVehicle(vehicles[#vehicles]) end end
api.settings=CONFIG
_G.VehicleGarageCleanup=api.cleanup
SC.vehicles=api
return api

end)(SC)
end
-- INTEGRATED_VEHICLES_END
-- INTEGRATED_AUTOWIN_BEGIN
(function(SC,ctx)
local Players,Run,player=ctx.Players,ctx.Run,ctx.player
local aw=SC.autoWin
aw.skipped={}; aw.killFirst={}; aw.objects=setmetatable({},{__mode="kv"}); aw.arguments=setmetatable({},{__mode="k"})
aw.modules={}; aw.equipRefresh=setmetatable({},{__mode="k"})
aw.hooks={}; aw.watches={}; aw.generation=0; aw.nextShot=0; aw.nextEquip=0; aw.status="OFF"
local function report(text)
    if aw.status==text then return end
    aw.status=text
    if aw.update then aw.update() end
end
function SC.recordWeapon(object,args)
    if type(object)~="table" then return end
    local tool=rawget(object,"instance")
    if typeof(tool)~="Instance" or not tool:IsA("Tool") or tool.Name~="M1911" then return end
    local valid,fire=pcall(function()return object.fire end)
    if not valid or type(fire)~="function" then return end
    aw.objects[tool]=object
    if args then aw.arguments[tool]=args end
end
function SC.removeWeaponCaptureHooks()
    for i=#aw.hooks,1,-1 do
        local hook=aw.hooks[i]
        if hook.module[hook.name]==hook.wrapper then hook.module[hook.name]=hook.original end
    end
    table.clear(aw.hooks)
end
local function captureWeaponMethods()
    if #aw.hooks>0 then return true end
    local definitions=game:GetService("ReplicatedStorage"):FindFirstChild("Weapon")
    if not definitions then return false end
    local modules={definitions}
    local pistol=definitions:FindFirstChild("M1911")
    if pistol then table.insert(modules,pistol) end
    local loaded={}
    for _,script in ipairs(modules) do
        local ok,module=pcall(require,script)
        if ok and type(module)=="table" and not loaded[module] then
            loaded[module]=true
            aw.modules[module]=true
            -- Observe methods the equipped weapon already calls. Preserve their
            -- original arguments/return values, including constructor results.
            for _,name in ipairs({"new","equip","equipped","on_equipped","update_ammo_gui","play_animation","fire"}) do
                local original=rawget(module,name)
                if type(original)=="function" then
                    local wrapper=function(self,...)
                        SC.recordWeapon(self,name=="fire" and table.pack(...) or nil)
                        local results=table.pack(original(self,...))
                        for i=1,results.n do SC.recordWeapon(results[i]) end
                        return table.unpack(results,1,results.n)
                    end
                    module[name]=wrapper
                    table.insert(aw.hooks,{module=module,name=name,original=original,wrapper=wrapper})
                end
            end
        end
    end
    return next(loaded)~=nil
end
local function findWeaponObject(tool,now)
    local object=aw.objects[tool]
    if object and object.instance==tool then return object end
    if now<(aw.nextObjectScan or 0) then return end
    aw.nextObjectScan=now+.5
    local seen={}; local nodes,functions=0,0
    local inspect
    local function accept(candidate)
        if type(candidate)~="table" or rawget(candidate,"instance")~=tool then return end
        local ok,fire=pcall(function()return candidate.fire end)
        if ok and type(fire)=="function" then SC.recordWeapon(candidate); return candidate end
    end
    local debugLibrary=type(debug)=="table" and debug or {}
    local many=debugLibrary.getupvalues or getupvalues
    local single=debugLibrary.getupvalue or getupvalue
    inspect=function(value,depth)
        local kind=type(value)
        if (kind~="table" and kind~="function") or seen[value] or nodes>=4096 then return end
        if value==SC or value==aw or value==ctx or value==_G then return end
        seen[value]=true; nodes=nodes+1
        local found=accept(value)
        if found or depth<=0 then return found end
        if kind=="table" then
            local count=0
            for key,item in next,value do
                count=count+1; if count>256 then break end
                found=inspect(item,depth-1) or inspect(key,depth-1)
                if found then return found end
            end
        elseif functions<160 then
            functions=functions+1
            if type(many)=="function" then
                local ok,values=pcall(many,value)
                if ok and type(values)=="table" then
                    for _,item in next,values do found=inspect(item,depth-1); if found then return found end end
                    return
                end
            end
            if type(single)=="function" then
                for index=1,64 do
                    local ok,first,second=pcall(single,value,index)
                    if not ok or (first==nil and second==nil) then break end
                    -- Executor implementations return either the value alone,
                    -- or Lua's (name, value) pair.
                    local item=second~=nil and second or first
                    found=inspect(item,depth-1); if found then return found end
                end
            end
        end
    end
    local function signalController(signal)
        if not signal or type(getconnections)~="function" then return end
        local ok,links=pcall(getconnections,signal)
        if not ok or type(links)~="table" then return end
        for _,link in ipairs(links) do
            local valid,callback=pcall(function()return link.Function end)
            if valid and type(callback)=="function" then
                local found=inspect(callback,6); if found then return found end
            end
        end
    end
    -- The controller may predate the menu and cache its equip/UI methods.
    -- Read the existing input handlers instead of waiting for a first shot to
    -- pass through the fire hook. Never fire signals or invoke these callbacks.
    local gui=player:FindFirstChildOfClass("PlayerGui")
    local mouseGui=gui and gui:FindFirstChild("Mouse")
    local mobile=mouseGui and mouseGui:FindFirstChild("Mobile Frame")
    local fireButton=mobile and mobile:FindFirstChild("Mobile Fire")
    for _,source in ipairs({fireButton or false,tool}) do
        if source then
            for _,name in ipairs({"Activated","MouseButton1Down","MouseButton1Click","InputBegan"}) do
                local ok,signal=pcall(function()return source[name]end)
                local found=ok and signalController(signal)
                if found then return found end
            end
        end
    end
    if type(player.GetMouse)=="function" then
        local ok,mouse=pcall(player.GetMouse,player)
        if ok and mouse then
            local found=signalController(mouse.Button1Down)
            if found then return found end
        end
    end
    local input=game:GetService("UserInputService")
    local found=signalController(input.InputBegan)
    if found then return found end
    for module in pairs(aw.modules) do found=inspect(module,4); if found then return found end end
    if type(getgc)=="function" then
        local ok,objects=pcall(getgc,true)
        if not ok or type(objects)~="table" then ok,objects=pcall(getgc,false) end
        if ok and type(objects)=="table" then
            -- Direct table results are checked before traversing function-only
            -- results, which some mobile executors return even with true.
            for _,candidate in ipairs(objects) do found=accept(candidate); if found then return found end end
            seen={}; nodes=0; functions=0
            for _,candidate in ipairs(objects) do
                found=inspect(candidate,5); if found then return found end
                if nodes>=4096 then break end
            end
        end
    end
end
local function living(target,container)
    local c=target and target.Character
    local h=c and c:FindFirstChildOfClass("Humanoid")
    local r=c and c:FindFirstChild("HumanoidRootPart")
    if c and c.Parent==container and h and h.Health>0 and r then return c,h,r end
end
local function releaseFlight()
    local flight=aw.flight
    aw.flight=nil
    if not flight then return end
    if flight.root.Parent then
        flight.root.Anchored=flight.anchored
        flight.root.AssemblyLinearVelocity=Vector3.zero
    end
    if flight.hum.Parent then flight.hum.AutoRotate=flight.autoRotate end
    for part,value in pairs(flight.collisions) do if part.Parent then part.CanCollide=value end end
end
local function stopOwnedKill()
    if aw.ownsKill then SC.stopJuggernautAutoKill(); aw.ownsKill=false end
end
local function resetRole()
    aw.generation=aw.generation+1
    aw.role=nil; aw.target=nil
    aw.priorityQueue=nil
    aw.nextObjectScan=0
    releaseFlight(); stopOwnedKill()
end
local function followTarget(c,h,r,targetRoot)
    local flight=aw.flight
    if flight and flight.root~=r then releaseFlight(); flight=nil end
    if not flight then
        flight={root=r,hum=h,anchored=r.Anchored,autoRotate=h.AutoRotate,collisions={}}
        aw.flight=flight
    end
    for _,part in ipairs(c:GetDescendants()) do
        if part:IsA("BasePart") then
            if flight.collisions[part]==nil then flight.collisions[part]=part.CanCollide end
            part.CanCollide=false
        end
    end
    h.AutoRotate=false; r.Anchored=true; r.AssemblyLinearVelocity=Vector3.zero
    SC.followJugPosition(c,targetRoot)
end
function SC.setAutoWin(value)
    value=value==true and SC.ownerFeatures and SC.isOwnerAccount(player) and not SC.paused and not SC.closing
    if value==aw.enabled then return value end
    aw.session=(aw.session or 0)+1
    aw.enabled=value; resetRole()
    if value then
        aw.resume={fly=SC.cFlyEnabled,followJug=SC.cFlyFollowJug}
        ctx.stopMovement()
        if SC.vehicles then SC.vehicles.exit() end
        SC.gravity.enabled=false; SC.stopGravity()
        aw.nextEquip=0; aw.nextObjectScan=0; aw.nextShot=0; aw.initialized=false
        table.clear(aw.equipRefresh)
        report("Preparing M1911...")
        local session=aw.session
        task.spawn(function()
            local ok,reason=pcall(function()
                assert(ctx.ensureFire(),"Weapon controller unavailable")
                if not aw.enabled or aw.session~=session then return end
                assert(captureWeaponMethods(),"Weapon controller unavailable")
                assert(ctx.ensureRecoil(),"No Recoil hook unavailable")
                assert(ctx.ensureSpread(),"No Spread hook unavailable")
            end)
            if not aw.enabled or aw.session~=session then
                if not aw.enabled then SC.removeWeaponCaptureHooks() end
                return
            end
            aw.initialized=ok
            if ok then SC.stepAutoWin(true) else report("AutoWin could not start: "..tostring(reason)) end
        end)
    else
        SC.removeWeaponCaptureHooks()
        report("OFF")
        local resume=aw.resume; aw.resume=nil
        if resume and resume.fly and not SC.paused and not SC.closing and player.Character then
            if ctx.startFly() then SC.cFlyFollowJug=resume.followJug end
        end
    end
    if aw.update then aw.update() end
    return value
end
local function equipPistol(c,h,now)
    local tool=c:FindFirstChild("M1911")
    local backpack=player:FindFirstChildOfClass("Backpack")
    if not tool then tool=backpack and backpack:FindFirstChild("M1911") end
    if not tool or not tool:IsA("Tool") then report("Waiting for M1911 in inventory"); return end
    if aw.weaponCharacter~=c or aw.equippingTool~=tool then
        if aw.weaponCharacter~=c then aw.objects[tool]=nil;aw.arguments[tool]=nil end
        aw.weaponCharacter=c;aw.equippingTool=tool
        aw.nextEquip=0;aw.nextObjectScan=0
    end
    if tool.Parent~=c and now>=aw.nextEquip then
        aw.nextEquip=now+.5
        h:EquipTool(tool)
    elseif tool.Parent==c and not aw.objects[tool] and not aw.equipRefresh[tool] and now>=aw.nextEquip then
        -- Hooks installed after an existing equip need one fresh equip event.
        aw.nextEquip=now+2
        aw.equipRefresh[tool]=true
        if backpack then h:UnequipTools(); h:EquipTool(tool) end
    end
    if tool.Parent~=c then return end
    return tool
end
function aw.chooseFirst(eligible,current)
    if not aw.enabled or aw.role~="juggernaut" then return end
    if current and aw.killFirst[current.UserId] and eligible(current) then return current end
    if not aw.priorityQueue then
        aw.priorityQueue={}
        for _,p in ipairs(Players:GetPlayers()) do
            if p~=player and aw.killFirst[p.UserId] then table.insert(aw.priorityQueue,p) end
        end
        for i=#aw.priorityQueue,2,-1 do
            local other=math.random(i)
            aw.priorityQueue[i],aw.priorityQueue[other]=aw.priorityQueue[other],aw.priorityQueue[i]
        end
    end
    for _,p in ipairs(aw.priorityQueue) do
        if p.Parent==Players and aw.killFirst[p.UserId] and eligible(p) then return p end
    end
end
function SC.stepAutoWin(refresh)
    if not aw.enabled or not aw.initialized then return end
    if SC.paused or SC.closing or not SC.ownerFeatures or not SC.isOwnerAccount(player) then SC.setAutoWin(false); return end
    if refresh then ctx.updateJuggernaut() end
    local killers=workspace:FindFirstChild("Killers")
    local survivors=workspace:FindFirstChild("Characters to kill")
    local target=ctx.getJuggernaut()
    local mine,h,r=living(player,player.Character and player.Character.Parent)
    if not mine or (mine.Parent~=killers and mine.Parent~=survivors) or SC.tripKind or (SC.fling and SC.fling.active) then
        if aw.role then resetRole() end
        report("Waiting for round..."); return
    end
    -- Resolve the already-created weapon while waiting for the round as well,
    -- so the first detected Juggernaut does not need a manual trigger press.
    local now=os.clock()
    local tool,object
    if mine.Parent==survivors then
        tool=equipPistol(mine,h,now)
        if tool then object=findWeaponObject(tool,now) end
    end
    if target==player and mine.Parent==killers then
        if aw.role~="juggernaut" then resetRole(); aw.role="juggernaut" end
        if not SC.juggernautAutoKill.enabled and os.clock()>=(aw.nextKillStart or 0) then
            aw.nextKillStart=os.clock()+.15
            aw.ownsKill=SC.startJuggernautAutoKill()==true
        end
        report("Juggernaut: Auto Kill ON"); return
    end
    local model,_,targetRoot=living(target,killers)
    if not model or target==player or mine.Parent~=survivors or aw.skipped[target.UserId] then
        if aw.role then resetRole() end
        report(model and aw.skipped[target.UserId] and ("Skipping "..target.Name) or "Waiting for Juggernaut...")
        return
    end
    if aw.role~="survivor" or aw.target~=target then
        resetRole(); aw.role="survivor"; aw.target=target; aw.nextShot=0
    end
    if SC.cFlyEnabled then ctx.stopFly() end
    SC.trackEnabled=false; SC.followEnabled=false; SC.speedEnabled=false
    if SC.juggernautAutoKill.enabled then SC.stopJuggernautAutoKill() end
    followTarget(mine,h,r,targetRoot)
    if not tool then return end
    object=object or aw.objects[tool]
    if not object then report("Waiting for equipped M1911 controller..."); return end
    if aw.firing or now<aw.nextShot then return end
    local generation=aw.generation
    aw.nextShot=now+.003; aw.firing=true
    task.spawn(function()
        local ok,reason=pcall(function()
            if not aw.enabled or aw.generation~=generation or tool.Parent~=player.Character or aw.skipped[target.UserId] then return end
            local args=aw.arguments[tool] or table.pack()
            assert(type(object.fire)=="function","M1911 firing method unavailable")
            local head=model:FindFirstChild("Head") or targetRoot
            local camera=workspace.CurrentCamera
            if camera and (head.Position-camera.CFrame.Position).Magnitude>.05 then
                camera.CFrame=CFrame.lookAt(camera.CFrame.Position,head.Position)
            end
            object:fire(table.unpack(args,1,args.n))
        end)
        aw.firing=false
        if not aw.enabled or aw.generation~=generation then return end
        if ok then report("Following "..target.Name.." | 1000%")
        else aw.nextShot=os.clock()+1; report("M1911: "..string.sub(tostring(reason),1,110)) end
    end)
end
local function changed()
    if aw.enabled then task.defer(function()if aw.enabled and not SC.closing then SC.stepAutoWin(true) end end) end
end
local function watchPlayer(p)
    aw.priorityQueue=nil
    local record={links={}}; aw.watches[p]=record
    local function watchCharacter(c)
        for _,link in ipairs(record.characterLinks or {}) do link:Disconnect() end
        record.characterLinks={}
        local function on(signal,callback)table.insert(record.characterLinks,signal:Connect(callback))end
        on(c:GetPropertyChangedSignal("Parent"),changed)
        on(c.ChildAdded,changed)
        local h=c:FindFirstChildOfClass("Humanoid")
        if h then on(h.Died,changed) end
        changed()
    end
    table.insert(record.links,p.CharacterAdded:Connect(watchCharacter))
    table.insert(record.links,p.CharacterRemoving:Connect(function()
        if p==player then resetRole() end
        changed()
    end))
    if p.Character then watchCharacter(p.Character) end
end
local function unwatchPlayer(p)
    aw.priorityQueue=nil
    local record=aw.watches[p]
    if record then
        for _,links in ipairs({record.links,record.characterLinks or {}}) do for _,link in ipairs(links) do link:Disconnect() end end
        aw.watches[p]=nil
    end
    if aw.target==p then resetRole() end
    if aw.refreshPlayers then task.defer(aw.refreshPlayers) end
end
for _,p in ipairs(Players:GetPlayers()) do watchPlayer(p) end
ctx.connect(Players.PlayerAdded,function(p)watchPlayer(p); if aw.refreshPlayers then aw.refreshPlayers() end end)
ctx.connect(Players.PlayerRemoving,unwatchPlayer)
ctx.connect(Run.Heartbeat,function()SC.stepAutoWin(false)end)
Run:BindToRenderStep("HeadLockMenuAutoWinFollow",Enum.RenderPriority.Character.Value+3,function()
    if aw.enabled and aw.role=="survivor" and not SC.paused then SC.stepAutoWin(false) end
end)
Run:BindToRenderStep("HeadLockMenuAutoWinAim",Enum.RenderPriority.Camera.Value+2,function()
    if not SC.autoWinCombat() then return end
    local target=aw.target and aw.target.Character
    local head=target and (target:FindFirstChild("Head") or target:FindFirstChild("HumanoidRootPart"))
    local camera=workspace.CurrentCamera
    if head and camera and (head.Position-camera.CFrame.Position).Magnitude>.05 then
        camera.CFrame=CFrame.lookAt(camera.CFrame.Position,head.Position)
    end
end)
function aw.cleanup()
    SC.setAutoWin(false)
    SC.removeWeaponCaptureHooks()
    for p in pairs(aw.watches) do unwatchPlayer(p) end
    Run:UnbindFromRenderStep("HeadLockMenuAutoWinFollow")
    Run:UnbindFromRenderStep("HeadLockMenuAutoWinAim")
end
function aw.draw(panel)
    local make,button=ctx.make,ctx.button
    panel=make("ScrollingFrame",{Name="AutoWinSettings",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,
        BorderSizePixel=0,ScrollBarThickness=3,CanvasSize=UDim2.fromOffset(0,286),ScrollingDirection=Enum.ScrollingDirection.Y},panel)
    make("TextLabel",{Size=UDim2.new(1,0,0,30),BackgroundTransparency=1,Text="AutoWin",TextColor3=ctx.white,
        Font=Enum.Font.Code,TextSize=20,TextXAlignment=Enum.TextXAlignment.Left},panel)
    local toggle=button("OFF",panel); toggle.Name="AutoWinToggle"; toggle.Position=UDim2.fromOffset(0,38); toggle.Size=UDim2.fromOffset(105,38)
    local status=make("TextLabel",{Name="AutoWinStatus",Position=UDim2.fromOffset(0,82),Size=UDim2.new(1,0,0,40),
        BackgroundTransparency=1,Text=aw.status,TextWrapped=true,TextColor3=ctx.white,Font=Enum.Font.Code,TextSize=12,
        TextXAlignment=Enum.TextXAlignment.Left},panel)
    make("TextLabel",{Position=UDim2.fromOffset(0,126),Size=UDim2.new(1,0,0,24),BackgroundTransparency=1,
        Text="Skip auto kill on players:",TextColor3=ctx.white,Font=Enum.Font.Code,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left},panel)
    local names=button("Players",panel); names.Name="AutoWinPlayers"; names.Position=UDim2.fromOffset(0,154); names.Size=UDim2.new(1,-5,0,36)
    local list=make("ScrollingFrame",{Name="AutoWinPlayerList",Position=UDim2.fromOffset(0,198),Size=UDim2.new(1,0,0,140),
        BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,CanvasSize=UDim2.fromOffset(0,0),Visible=aw.listOpen==true},panel)
    make("UIListLayout",{Padding=UDim.new(0,4),SortOrder=Enum.SortOrder.LayoutOrder},list)
    local priorityLabel=make("TextLabel",{Size=UDim2.new(1,0,0,24),BackgroundTransparency=1,
        Text="Kill first when I'm Juggernaut:",TextColor3=ctx.white,Font=Enum.Font.Code,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left},panel)
    local priorityNames=button("Players",panel); priorityNames.Name="AutoWinKillFirstPlayers"; priorityNames.Size=UDim2.new(1,-5,0,36)
    local priorityList=make("ScrollingFrame",{Name="AutoWinKillFirstList",Size=UDim2.new(1,0,0,140),
        BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,CanvasSize=UDim2.fromOffset(0,0),Visible=aw.killListOpen==true},panel)
    make("UIListLayout",{Padding=UDim.new(0,4),SortOrder=Enum.SortOrder.LayoutOrder},priorityList)
    aw.update=function()
        if not toggle.Parent then return end
        toggle.Text=aw.enabled and "ON" or "OFF"
        toggle.BackgroundColor3=aw.enabled and ctx.white or ctx.black
        toggle.TextColor3=aw.enabled and ctx.black or ctx.white
        status.Text=aw.status
        list.Visible=aw.listOpen==true
        local count,priorities=0,0
        for _,p in ipairs(Players:GetPlayers()) do if p~=player then
            if aw.skipped[p.UserId] then count=count+1 end
            if aw.killFirst[p.UserId] then priorities=priorities+1 end
        end end
        names.Text="Players ("..count.." selected)"
        priorityNames.Text="Players ("..priorities.." selected)"
        local y=aw.listOpen and 354 or 206
        priorityLabel.Position=UDim2.fromOffset(0,y)
        priorityNames.Position=UDim2.fromOffset(0,y+28)
        priorityList.Position=UDim2.fromOffset(0,y+72)
        priorityList.Visible=aw.killListOpen==true
        panel.CanvasSize=UDim2.fromOffset(0,y+80+(aw.killListOpen and 146 or 0))
    end
    aw.refreshPlayers=function()
        if not list.Parent then return end
        for _,child in ipairs(list:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
        for _,child in ipairs(priorityList:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
        local players=Players:GetPlayers(); table.sort(players,function(a,b)return a.Name:lower()<b.Name:lower()end)
        local count=0
        for _,p in ipairs(players) do if p~=player then
            count=count+1
            local selected=aw.skipped[p.UserId]
            local row=button((selected and "[x] " or "[ ] ")..p.Name,list)
            row.Name="Skip_"..p.UserId; row.LayoutOrder=count; row.Size=UDim2.new(1,-6,0,34)
            row.TextSize=13; row.TextXAlignment=Enum.TextXAlignment.Left; row.TextTruncate=Enum.TextTruncate.AtEnd
            row.BackgroundColor3=selected and ctx.white or ctx.black; row.TextColor3=selected and ctx.black or ctx.white
            row.Activated:Connect(function()
                aw.skipped[p.UserId]=not aw.skipped[p.UserId] or nil
                SC.stepAutoWin(true); aw.refreshPlayers(); aw.update()
            end)
            local first=aw.killFirst[p.UserId]
            local priorityRow=button((first and "[x] " or "[ ] ")..p.Name,priorityList)
            priorityRow.Name="KillFirst_"..p.UserId; priorityRow.LayoutOrder=count; priorityRow.Size=UDim2.new(1,-6,0,34)
            priorityRow.TextSize=13; priorityRow.TextXAlignment=Enum.TextXAlignment.Left; priorityRow.TextTruncate=Enum.TextTruncate.AtEnd
            priorityRow.BackgroundColor3=first and ctx.white or ctx.black; priorityRow.TextColor3=first and ctx.black or ctx.white
            priorityRow.Activated:Connect(function()
                aw.killFirst[p.UserId]=not aw.killFirst[p.UserId] or nil
                aw.priorityQueue=nil
                SC.stepAutoWin(true); aw.refreshPlayers(); aw.update()
            end)
        end end
        list.CanvasSize=UDim2.fromOffset(0,count*38+4)
        priorityList.CanvasSize=UDim2.fromOffset(0,count*38+4)
        aw.update()
    end
    toggle.Activated:Connect(function()SC.setAutoWin(not aw.enabled)end)
    names.Activated:Connect(function()aw.listOpen=not aw.listOpen; aw.update()end)
    priorityNames.Activated:Connect(function()aw.killListOpen=not aw.killListOpen; aw.update()end)
    aw.refreshPlayers(); aw.update()
end
return aw
end)(SC,{Players=Players,Run=RS,player=player,connect=connect,make=make,button=textButton,black=BLACK,white=WHITE,
 stopMovement=SC.stopConflictingMovement,stopFly=stopCFly,startFly=startCFly,
 ensureFire=ensureFireHook,ensureRecoil=ensureNoRecoilHook,ensureSpread=ensureNoSpreadHook,
 updateJuggernaut=updateJuggernaut,getJuggernaut=function()return juggernautPlayer end})
-- INTEGRATED_AUTOWIN_END
addCategory("Vehicles",function(panel)
 local ok,reason=pcall(function()
  if not SC.vehicles then SC.installVehicles()end
  SC.vehicles.draw(panel)
 end)
 if not ok then make("TextLabel",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text="Vehicles could not start:\n"..tostring(reason),TextWrapped=true,TextColor3=WHITE,Font=Enum.Font.Code,TextSize=14},panel)end
end)
addCategory("AutoWin",SC.autoWin.draw)
function SC.refreshOwnerCategories()
 for _,entry in ipairs(categoryEntries)do
  entry.button.Visible=entry.section==SC.activeGame and(entry.name~="AutoWin"or(SC.ownerFeatures and SC.isOwnerAccount(player)))
 end
 if SC.selectedCategory=="AutoWin"and not SC.ownerFeatures then SC.selectCredits()end
end
SC.refreshOwnerCategories()
_G.HeadLockMenuVersion="2026-11-26-autowin-first-shot-priority"

SC.watchOwnerEmotes()

end
local __ok,__error=xpcall(__run,function(message)return tostring(message)end)
if __ok then
_G.HeadLockMenuExecutionReady=true
if __boot.gui then __boot.gui:Destroy()end
else
local message="HeadLockMenu could not start:\n"..tostring(__error)
_G.HeadLockMenuExecutionError=message
warn(message)
if __boot.message then __boot.message.Text=message end
end
