

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
 if not aw.enabled or aw.role~="survivor" or not SC.canSelectPlayer(aw.target) or SC.paused or SC.closing then return false end
 local c=aw.target.Character local h=c and c:FindFirstChildOfClass("Humanoid")
 return aw.target.Parent==Players and not aw.skipped[aw.target.UserId] and c and c.Parent==workspace:FindFirstChild("Killers") and h and h.Health>0
end
function SC.canBuild()return(SC.ownerFeatures and SC.isOwnerAccount(player))or SC.temporaryAccess==true end
function SC.rapidFireMax()return SC.canBuild()and 1000 or 200 end
function SC.setOwnerFeatures(value)
 SC.ownerFeatures=value==true and SC.isOwnerAccount(player)
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
if SC.autoWinNeedsFirstShot and SC.autoWinNeedsFirstShot(self)then return originalWeaponFire(self,...)end
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
button.Text="  "..name button.Visible=section==SC.activeGame table.insert(categoryButtons,button)table.insert(categoryEntries,{button=button,section=section,name=name})local function selectCategory()
if(name=="Building"and not SC.canBuild())or(name=="Owner Panel"and not(SC.ownerFeatures and SC.isOwnerAccount(player)))then return end
SC.selectedCategory=name
SC.updateRapidFire=nil;SC.updateRapidSlider=nil
if SC.building then SC.building.update=nil;SC.building.ownerUpdate=nil end
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
if not SC.canSelectPlayer(target)then return end local active=workspace:FindFirstChild("Characters to kill")local model=target and target.Character local h=model and model:FindFirstChildOfClass("Humanoid")
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
table.insert(categoryConnections,UIS.InputEnded:Connect(function(input)if input==activeInput then activeInput=nil end end))if not isReload then SC.updateRapidSlider=update end;update()end make("TextLabel",{Position=UDim2.fromOffset(0,33),
Size=UDim2.new(1,0,0,24),BackgroundTransparency=1,Text="Rapid Fire",TextColor3=WHITE,TextSize=16,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,},panel)
local toggle=textButton("OFF",panel)toggle.Position=UDim2.fromOffset(0,60)toggle.Size=UDim2.fromOffset(105,36)local function update()toggle.Text=SC.rapidFireEnabled and"ON"or"OFF"
toggle.BackgroundColor3=SC.rapidFireEnabled and WHITE or BLACK toggle.TextColor3=SC.rapidFireEnabled and BLACK or WHITE end toggle.Activated:Connect(function()if SC.rapidFireEnabled then SC.rapidFireEnabled=false
else SC.rapidFireEnabled=ensureFireHook()end update()end)SC.updateRapidFire=function()if panel.Parent then update();if SC.updateRapidSlider then SC.updateRapidSlider()end end end;update()addSlider(117,function()return SC.rapidFirePower end,function(power)SC.rapidFirePower=math.clamp(power,0,SC.rapidFireMax())end,false,SC.rapidFireMax)make("TextLabel",{
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
camera.CFrame=CFrame.lookAt(position,targetPart.Position)end end)function SC.pauseSession()if SC.paused then return end SC.paused=true if SC.setBuilding then SC.setBuilding(false)end SC.setAutoWin(false)if SC.vehicles then SC.vehicles.setPaused(true)end SC.stopExtraFeatures(false) SC.stopJuggernautAutoKill()SC.stopFling()
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
_G.HeadLockMenuCleanup=function()SC.closing=true if SC.ownerSync then SC.ownerSync.close()end if SC.building then SC.building.cleanup()end if SC.autoWin.cleanup then SC.autoWin.cleanup()end if SC.vehicles then SC.vehicles.cleanup()end SC.stopExtraFeatures(true)SC.stopJuggernautAutoKill()SC.setAntiFling(false)if checksScript and checksScript.Parent then checksScript.Enabled=originalChecksEnabled end SC.gravity.enabled=false SC.stopGravity()RS:UnbindFromRenderStep(RENDER_NAME)RS:UnbindFromRenderStep(TRACK_RENDER_NAME)
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


function SC.installVehicleSync(ctx)
return (function(ctx)
local Http=ctx.Http
local net={enabled=true,connected=false,vehicles={},records={},queue={},closed=false,pending=false,nextClaim=0}
if type(ctx.endpoint)~='string' or not ctx.endpoint:match('^https://') then
    net.enabled=false;net.error='Shared unavailable';return net
end
local send=type(request)=='function' and request or type(http_request)=='function' and http_request
    or type(syn)=='table' and syn.request or type(http)=='table' and http.request
if type(send)~='function' then net.enabled=false;net.error='Shared unavailable';return net end
local function guid()return (Http:GenerateGUID(false):gsub('[{}%-]',''))end
net.session=guid();local secret=guid()
local room=tostring(game.PlaceId)..':'..tostring(game.JobId)
if type(game.JobId)~='string' or #game.JobId<8 then net.enabled=false;net.error='Shared needs a live server';return net end
local endpoint=ctx.endpoint
local function rpc(op,fields)
    local body={room=room,session=net.session,secret=secret,user=ctx.player.UserId,op=op}
    for key,value in pairs(fields or {}) do body[key]=value end
    local response=send({Url=endpoint,Method='POST',Headers={['Content-Type']='application/json'},Body=Http:JSONEncode(body),Timeout=8})
    assert(type(response)=='table' and (response.StatusCode or response.Status)==200,'Shared connection unavailable')
    local data=Http:JSONDecode(response.Body)
    assert(type(data)=='table' and type(data.cars)=='table','Shared response unavailable')
    return data
end
local function enqueue(op,v,fields)
    table.insert(net.queue,{op=op,v=v,fields=fields or {id=v and v.netId}})
end
function net:isDriver(v)
    return self.enabled and self.connected and not self.closed and v and v.networked and v.leaseUntil
        and os.clock()<v.leaseUntil and v.netDriver==self.session and v.epoch~=nil
end
function net:attach(v,record)
    self.vehicles[record.id]=v;v.netId=record.id;v.networked=true;v.published=true
    v.netOwner=record.owner;v.netDriver=record.driver;v.epoch=record.epoch;v.netRecord=record
end
function net:register(v)
    if not self.enabled or self.closed then return false end
    v.netId=guid();v.networked=true;v.netOwner=self.session;v.published=false
    self.vehicles[v.netId]=v
    enqueue('spawn',v,{id=v.netId,kind=v.kind,pose=ctx.pose(v)})
    return true
end
function net:claim(v)
    if not self.enabled or self.closed or not self.connected or not v.published or self.pending
        or ctx.current() or os.clock()<self.nextClaim then return end
    self.nextClaim=os.clock()+.7
    if v.netDriver and v.netDriver~=self.session then ctx.report('Occupied');return end
    self.pending=true;enqueue('claim',v)
end
function net:release(v)
    if not v or not v.networked then return end
    local epoch=v.epoch
    v.leaseUntil=0
    if not self.closed then enqueue('release',v,{id=v.netId,epoch=epoch,pose=ctx.pose(v)}) end
end
function net:delete(v)
    if not v or not v.networked then return false end
    if v.netOwner~=self.session then ctx.report('Not your vehicle');return true end
    if v.netDriver and v.netDriver~=self.session then ctx.report('Occupied');return true end
    if not v.deleting then v.deleting=true;enqueue('delete',v)end
    return true
end
function net:close()
    if self.closed then return end
    self.closed=true;self.connected=false
    task.spawn(function()pcall(rpc,'leave')end)
end
local function receive(data)
    local records={}
    for _,record in ipairs(data.cars) do
        if type(record)=='table' and type(record.id)=='string' and (record.kind=='Car' or record.kind=='Bike')
            and type(record.cf)=='table' and #record.cf==12 then records[record.id]=record end
    end
    net.records=records
    for id,v in pairs(net.vehicles) do
        local record=records[id]
        if record then
            v.netOwner=record.owner;v.netDriver=record.driver;v.netRecord=record
            if not ctx.current() or ctx.current()~=v then v.epoch=record.epoch end
        elseif v.published then
            net.vehicles[id]=nil;ctx.remove(v)
        end
    end
    ctx.reconcile(records,net)
end
local function lease(record,data,started)
 if record and type(record['until'])=='number'and type(data.now)=='number'then
  local duration=math.clamp((record['until']-data.now)/1000,0,15)
  return started+math.max(0,duration-.5),math.min(8,duration*.55)
 end
 return started+2,1.4
end
local function tick()
    local active=ctx.current()
    local item
    local renew=net:isDriver(active) and active.leaseUntil-os.clock()<(active.renewMargin or 1.4)
    if net.connected and not renew then item=table.remove(net.queue,1) end
    local fields=item and item.fields or {}
    local op=not net.connected and 'join' or item and item.op or 'sync'
    local moving
    if op=='sync' and net:isDriver(active) then
        active.netSeq=(active.netSeq or 0)+1
        moving={id=active.netId,epoch=active.epoch,seq=active.netSeq,pose=ctx.pose(active)}
        fields={move=moving}
    end
    local started=os.clock()
    local ok,data=pcall(rpc,op,fields)
    if net.closed then return end
    if not ok then
        net.error=tostring(data)
        if item then
            if item.op=='claim' then net.pending=false end
            if item.op=='delete' and item.v then item.v.deleting=false end
            if item.op=='spawn' then table.insert(net.queue,item)end
        end
        ctx.report('Shared reconnecting')
        net.connected=false
        return
    end
    if op=='join' then net.connected=data.ok==true end
    if data.error=='authorization' then net.connected=false end
    if moving and active and data.ok and data.epoch==moving.epoch
        and active.netId==moving.id and ctx.current()==active then
        local record;for _,item in ipairs(data.cars)do if item.id==moving.id then record=item;break end end
        active.leaseUntil,active.renewMargin=lease(record,data,started)
    end
    receive(data)
    if item then
        local v=item.v
        if item.op=='spawn' then
            if data.ok and net.records[v.netId] then v.published=true;ctx.report('Shared vehicle spawned')
            else ctx.remove(v);net.vehicles[v.netId]=nil;ctx.report('Shared spawn failed')end
        elseif item.op=='claim' then
            net.pending=false
            local record=v and net.records[v.netId]
            local deadline,margin=lease(record,data,started)
            if data.ok and record and record.driver==net.session and os.clock()<deadline
                and not v.dead and not ctx.current() then
                v.epoch=data.epoch;v.netSeq=0;v.leaseUntil=deadline;v.renewMargin=margin;v.netDriver=net.session
                if not ctx.enter(v)then net:release(v)end
            elseif data.ok and record and record.driver==net.session then net:release(v)
            else ctx.report(data.error=='occupied' and 'Occupied' or 'Seat unavailable')end
        elseif item.op=='delete' and v then
            v.deleting=false
            if not data.ok then ctx.report(data.error=='occupied' and 'Occupied' or 'Delete unavailable')end
        end
    end
end
net.tick=tick
if not ctx.manual then
    task.spawn(function()
        while not net.closed do
            local ok,why=pcall(tick)
            if not ok then net.connected=false;net.error=tostring(why);ctx.report('Shared reconnecting')end
            task.wait(net.connected and (ctx.current() and .12 or next(net.records) and .3 or 1.5) or 2)
        end
    end)
end
return net
end)(ctx)
end
SC.vehicleRelayURL="https://headlock-vehicle-sync.vercel.app/v1"
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
local exitRide,deleteVehicle,net
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
    if v.networked and (not net or not net:isDriver(v)) then
        if net then net:claim(v)end
        return
    end
    if (r.Position-v.seat.Position).Magnitude>7 then return end
    v.hull.Anchored=false;v.balance.Enabled=true
    local look=v.hull.CFrame.LookVector
    v.heading=math.atan2(-look.X,-look.Z)
    if SC.autoWin and SC.autoWin.enabled then SC.setAutoWin(false) end
    SC.stopConflictingMovement()
    SC.gravity.enabled=false; SC.stopGravity()


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
    return true
end
exitRide=function()
    local v=active; if not v then return end
    if v.networked and net then net:release(v)end
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
local function newVehicle(kind,record)
    if busy then return false end
    local c,h,r=character(); if not c then report('Spawn your character first.'); return end
    busy=true;if not record then report('Loading '..kind..'…')end
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
            local spawnCF,rp
            if record then
                assert(net and net.records[record.id],'Vehicle removed')
                record=net.records[record.id]
                spawnCF=CFrame.new(table.unpack(record.cf));yawLook=spawnCF.LookVector
                rp=RaycastParams.new();rp.FilterType=Enum.RaycastFilterType.Exclude;rp.RespectCanCollide=true
            else spawnCF,rp=nearbySpawn(c,r,extent,averageRadius,lo,hi,origin,yawLook)end
            local hull=make('Part',model,{Name='StableChassis',Size=Vector3.new(math.max(kind=='Bike' and 1.2 or 2.5,extent.X*.70),.8,math.max(3,extent.Z*.70)),
                CFrame=spawnCF,Transparency=1,Anchored=true,CanCollide=true,CanTouch=false,RootPriority=-127,
                CustomPhysicalProperties=PhysicalProperties.new(2,.15,0,100,100)})
            local v={model=model,hull=hull,kind=kind,wheels={},links={},driverConstraints={},lastExit=-10,
                heading=math.atan2(-yawLook.X,-yawLook.Z),steer=0,dead=false,ray=rp,normal=UP}
            model.PrimaryPart=hull; model.Name='Local'..kind


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
            if net and net.enabled then
                if record then net:attach(v,record)else net:register(v)end
                hull.Anchored=true;v.balance.Enabled=false
            end
            for c in pairs(trackedCharacters) do protectAvatar(v,c) end
            refreshGroundFilters()
            local function on(signal,fn) local connection=signal:Connect(fn); table.insert(v.links,connection) end
            on(seat.Touched,function(hit)
                local cc,hh,rr=character()
                if not cc or active or v.dead or os.clock()-v.lastExit<1 or not hit:IsDescendantOf(cc) then return end
                if (rr.Position-seat.Position).Magnitude>6 then return end
                beginRide(v,cc,hh,rr)
            end)
            if not record then report(v.networked and 'Sharing vehicle' or kind..' spawned. Local only.')end
        end)
        if not success then if model then model:Destroy() end; report('Load failed: '..string.sub(tostring(err),1,150)) end
        busy=false
    end)
    return true
end
deleteVehicle=function(v,localOnly)
    if not v or v.dead then return end
    if v.networked and net and not localOnly then
        if active==v then exitRide()end
        net:delete(v);return
    end
    if active==v then exitRide() end
    v.dead=true
    for _,c in ipairs(v.links) do c:Disconnect() end
    v.model:Destroy()
    for i,item in ipairs(vehicles) do if item==v then table.remove(vehicles,i); break end end
end
local function vehiclePose(v)
    local vel,av=v.hull.AssemblyLinearVelocity,v.hull.AssemblyAngularVelocity
    return {cf={v.hull.CFrame:GetComponents()},vel={vel.X,vel.Y,vel.Z},av={av.X,av.Y,av.Z},
        steer=v.steer,spin=v.wheels[1] and v.wheels[1].angle or 0}
end
local function reconcile(records,sync)
    if closed then return end
    if active and active.networked then
        local state=records[active.netId]
        if not state or state.driver~=sync.session or state.epoch~=active.epoch or not sync:isDriver(active) then exitRide()end
    end
    for id,state in pairs(records)do
        local v=sync.vehicles[id]
        if v then
            if active~=v then
                v.remoteCF=CFrame.new(table.unpack(state.cf));v.receivedAt=os.clock()
                v.remoteVelocity=state.driver and Vector3.new(table.unpack(state.vel)) or ZERO
                v.remoteSpin=state.spin or 0;v.remoteSteer=state.steer or 0
            end
        elseif not busy then newVehicle(state.kind,state)end
    end
end
if SC.installVehicleSync then
    net=SC.installVehicleSync({Http=Http,Run=Run,player=player,endpoint=SC.vehicleRelayURL,
        current=function()return active end,pose=vehiclePose,report=report,reconcile=reconcile,
        remove=function(v)deleteVehicle(v,true)end,
        enter=function(v)
            local c,h,r=character()
            if not c or api.paused or closed or v.dead then return false end
            return beginRide(v,c,h,r)
        end})
end
local function deleteOwned()
    local copy={}
    for _,v in ipairs(vehicles)do table.insert(copy,v)end
    for _,v in ipairs(copy)do
        if not v.networked or not net or v.netOwner==net.session then deleteVehicle(v)end
    end
end
local function longitudinalAcceleration(speed,gas,brake,driven)
    local target,rate=0,CONFIG.Coast
    if driven then
        if brake then

            target=-CONFIG.Reverse
            rate=speed>.15 and CONFIG.Brake or CONFIG.ReverseAcceleration
            if gas then target=0; rate=CONFIG.Brake end
        elseif gas then
            target=CONFIG.Speed
            rate=speed<-.15 and CONFIG.Brake or CONFIG.Acceleration
        end
    else rate=CONFIG.Brake end


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
    if active and (api.paused or not hh or active.driver.hum~=hh or (SC.autoWin and SC.autoWin.enabled)
        or active.networked and not net:isDriver(active)) then exitRide() end
    if active and hh then


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
        if not v.dead and v.model.Parent and v.networked and active~=v then
            v.hull.Anchored=true;v.balance.Enabled=false;v.drive.Force=ZERO
            for _,wheel in ipairs(v.wheels)do wheel.force.Force=ZERO end
            if v.remoteCF then
                local target=v.remoteCF+(v.remoteVelocity or ZERO)*math.min(os.clock()-(v.receivedAt or os.clock()),.2)
                local current=v.hull.CFrame
                local nextCF=(current.Position-target.Position).Magnitude>25 and target or current:Lerp(target,1-math.exp(-18*dt))
                v.model:PivotTo(nextCF)
                for _,wheel in ipairs(v.wheels)do
                    local steer=wheel.front and -(v.remoteSteer or 0)*math.rad(32)or 0
                    for _,joint in ipairs(wheel.joints)do joint.Transform=CFrame.Angles(0,steer,0)*CFrame.Angles(v.remoteSpin or 0,0,0)end
                end
            end
        elseif not v.dead and v.model.Parent then
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
    exitRide()
    if net and net.close then net:close()end
    while #vehicles>0 do deleteVehicle(vehicles[#vehicles],true) end
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
        deleteOwned()
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
        BackgroundTransparency=1,Text=lastStatus..(net and not net.enabled and ' | '..net.error or ''),TextWrapped=true,TextSize=12,
        Font=Enum.Font.Code,TextColor3=Color3.new(1,1,1),TextXAlignment=Enum.TextXAlignment.Left})
end
api.spawn=newVehicle
api.exit=exitRide
api.deleteAll=deleteOwned
api.settings=CONFIG
api.sync=net
_G.VehicleGarageCleanup=api.cleanup
SC.vehicles=api
return api

end)(SC)
end
(function(SC,ctx)
local Players,Run,player=ctx.Players,ctx.Run,ctx.player
local aw=SC.autoWin
aw.skipped={}; aw.killFirst={}; aw.objects=setmetatable({},{__mode="kv"}); aw.arguments=setmetatable({},{__mode="k"})
aw.modules={}; aw.equipRefresh=setmetatable({},{__mode="k"})
aw.hooks={}; aw.watches={}; aw.generation=0; aw.nextShot=0; aw.nextEquip=0; aw.status="OFF"
aw.ready=setmetatable({},{__mode="k"});aw.replaying=setmetatable({},{__mode="k"})
aw.busy=setmetatable({},{__mode="k"});aw.shots=setmetatable({},{__mode="k"})
aw.observed=setmetatable({},{__mode="k"});aw.shotLinks={};aw.nextPrime=0
local function report(text)
    if aw.status==text then return end
    aw.status=text
    if aw.update then aw.update() end
end
local function firingReady(tool,object)
    local ready=tool and aw.ready[tool]
    return ready~=nil and ready.object==object and ready.character==player.Character
        and tool.Parent==player.Character
end
local function localPistol(object)
    local tool=type(object)=="table" and rawget(object,"instance")
    if typeof(tool)=="Instance" and tool:IsA("Tool") and tool.Name=="M1911"
        and tool.Parent==player.Character then return tool end
end
function SC.autoWinNeedsFirstShot(object)
    local tool=localPistol(object)
    return aw.enabled and SC.autoWinCombat() and tool and not firingReady(tool,object)
end
local function observeTool(tool)
    if aw.observed[tool] then return end
    local handle=tool:FindFirstChild("Handle")
    local sound=handle and handle:FindFirstChild("Fire")
    if sound and sound:IsA("Sound") then
        aw.observed[tool]=true
        table.insert(aw.shotLinks,sound.Played:Connect(function()
            aw.shots[tool]=(aw.shots[tool] or 0)+1
        end))
    end
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


            for _,name in ipairs({"new","equip","equipped","on_equipped","update_ammo_gui","play_animation","fire"}) do
                local original=rawget(module,name)
                if type(original)=="function" then
                    local wrapper=function(self,...)
                        SC.recordWeapon(self)
                        local tool=name=="fire" and localPistol(self)
                        if not tool or not aw.enabled then
                            local results=table.pack(original(self,...))
                            for i=1,results.n do SC.recordWeapon(results[i]) end
                            return table.unpack(results,1,results.n)
                        end
                        observeTool(tool)
                        local args=table.pack(...)
                        local normalInput=not aw.replaying[self]
                        local before=aw.shots[tool] or 0
                        local ammoBefore=self.ammo
                        local generation=aw.generation
                        aw.busy[self]=(aw.busy[self] or 0)+1
                        local results=table.pack(pcall(original,self,...))
                        local ammoAfter=self.ammo
                        aw.busy[self]=math.max(0,(aw.busy[self] or 1)-1)
                        local observed=(aw.shots[tool] or 0)>before or(type(ammoBefore)=="number"
                            and type(ammoAfter)=="number" and ammoAfter<ammoBefore)
                        if results[1] and normalInput and observed and aw.enabled
                            and aw.generation==generation and localPistol(self)==tool then
                            aw.ready[tool]={object=self,character=player.Character}
                            SC.recordWeapon(self,args)
                        end
                        if not results[1] then error(results[2],0) end
                        for i=2,results.n do SC.recordWeapon(results[i]) end
                        return table.unpack(results,2,results.n)
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
local function releaseInput(primer)
    local release=primer and primer.release
    if release then primer.release=nil;pcall(release) end
end
local function cancelPrime()
    local primer=aw.primer
    aw.primer=nil
    releaseInput(primer)
end
local function sendSignal(signal,...)
    local sent=false
    if type(getconnections)=="function" then
        local ok,links=pcall(getconnections,signal)
        if ok and type(links)=="table" then for _,link in ipairs(links) do
            local valid,callback=pcall(function()return link.Function end)
            if valid and type(callback)=="function" then
                local worked=pcall(callback,...);sent=worked or sent
            else
                local worked=pcall(function(...)link:Fire(...)end,...);sent=worked or sent
            end
        end end
    end
    if not sent and type(firesignal)=="function" then sent=pcall(firesignal,signal,...) end
    return sent
end
local function primeWeapon(tool,now)
    if aw.primer or now<aw.nextPrime then return end
    local object=aw.objects[tool]
    if object and (aw.busy[object] or 0)>0 then return end
    aw.nextPrime=now+4
    local primer={tool=tool,generation=aw.generation}
    aw.primer=primer
    local function current()
        return aw.primer==primer and aw.enabled and not SC.paused and not SC.closing
            and aw.generation==primer.generation and SC.autoWinCombat()
            and not aw.skipped[aw.target.UserId] and tool.Parent==player.Character
    end
    local function waitForReady()
        local deadline=os.clock()+.25
        repeat
            if not current() or firingReady(tool,aw.objects[tool]) then return end
            task.wait(.02)
        until os.clock()>=deadline
    end
    task.spawn(function()
        if not current() then
            if aw.primer==primer then aw.primer=nil end
            return
        end
        local input=game:GetService("UserInputService")
        local gui=player:FindFirstChildOfClass("PlayerGui")
        local mouseGui=gui and gui:FindFirstChild("Mouse")
        local mobile=mouseGui and mouseGui:FindFirstChild("Mobile Frame")
        local button=mobile and mobile:FindFirstChild("Mobile Fire")
        local camera=workspace.CurrentCamera
        local view=camera and camera.ViewportSize or Vector2.new(800,600)
        local point=Vector2.new(view.X*.5,view.Y*.5)
        if button and button.Visible and button.AbsoluteSize.X>0 and button.AbsoluteSize.Y>0 then
            point=button.AbsolutePosition+button.AbsoluteSize/2
        end
        local methods={}
        local function click(name,down,up)
            table.insert(methods,{name=name,run=function()
                primer.release=up
                local ok,why=pcall(down)
                if ok then waitForReady() else primer.error=tostring(why) end
                releaseInput(primer)
            end})
        end
        local created,virtual=pcall(function()return input:CreateVirtualInput()end)
        if created and virtual then
            click("virtual input",function()virtual:SendMouseButton(point,Enum.UserInputType.MouseButton1,true,0)end,
                function()virtual:SendMouseButton(point,Enum.UserInputType.MouseButton1,false,0)end)
        end
        local managerOk,manager=pcall(game.GetService,game,"VirtualInputManager")
        if managerOk and manager then
            click("mouse input",function()manager:SendMouseButtonEvent(point.X,point.Y,0,true,game,0)end,
                function()manager:SendMouseButtonEvent(point.X,point.Y,0,false,game,0)end)
        end
        if button then
            click("fire button",function()sendSignal(button.MouseButton1Down,point.X,point.Y)end,
                function()sendSignal(button.MouseButton1Up,point.X,point.Y)end)
            table.insert(methods,{name="fire click",run=function()sendSignal(button.MouseButton1Click)end})
            if aw.lastInput then
                table.insert(methods,{name="fire activation",run=function()sendSignal(button.Activated,aw.lastInput,1)end})
                click("fire touch",function()sendSignal(button.InputBegan,aw.lastInput)end,
                    function()sendSignal(button.InputEnded,aw.lastInput)end)
                local icon=button:FindFirstChild("Icon")
                if icon then
                    click("fire icon touch",function()sendSignal(icon.InputBegan,aw.lastInput)end,
                        function()sendSignal(icon.InputEnded,aw.lastInput)end)
                end
            end
        end
        local mouseOk,mouse=pcall(function()return player:GetMouse()end)
        if mouseOk and mouse then
            click("player mouse",function()sendSignal(mouse.Button1Down)end,function()sendSignal(mouse.Button1Up)end)
        end
        for _,method in ipairs(methods) do
            if not current() or firingReady(tool,aw.objects[tool]) then break end
            report("Starting first trigger: "..method.name)
            local ok,why=pcall(method.run)
            releaseInput(primer)
            if not ok then primer.error=tostring(why) end
            waitForReady()
        end
        releaseInput(primer)
        if aw.primer==primer then
            local stillCurrent=current()
            aw.primer=nil
            if stillCurrent and not firingReady(tool,aw.objects[tool]) then
                report("Automatic trigger unavailable. No first shot detected.")
            end
        end
    end)
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
    cancelPrime();aw.nextPrime=0
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
    value=value==true and not SC.paused and not SC.closing
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
    if SC.paused or SC.closing then SC.setAutoWin(false); return end
    if refresh then ctx.updateJuggernaut() end
    local killers=workspace:FindFirstChild("Killers")
    local survivors=workspace:FindFirstChild("Characters to kill")
    local target=ctx.getJuggernaut()
    local mine,h,r=living(player,player.Character and player.Character.Parent)
    if not mine or (mine.Parent~=killers and mine.Parent~=survivors) or SC.tripKind or (SC.fling and SC.fling.active) then
        if aw.role then resetRole() end
        report("Waiting for round..."); return
    end


    local now=os.clock()
    local tool,object
    if mine.Parent==survivors then
        tool=equipPistol(mine,h,now)
        if tool then observeTool(tool);object=findWeaponObject(tool,now) end
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
    if not model or not SC.canSelectPlayer(target) or mine.Parent~=survivors or aw.skipped[target.UserId] then
        if aw.role then resetRole() end
        report(model and SC.isOwnerAccount(target) and ("Skipping owner "..target.Name)
            or model and aw.skipped[target.UserId] and ("Skipping "..target.Name) or "Waiting for Juggernaut...")
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
    if not firingReady(tool,object) then
        primeWeapon(tool,now)
        object=aw.objects[tool]
        if not firingReady(tool,object) then return end
    end
    if aw.primer or (aw.busy[object] or 0)>0 then return end
    if aw.firing or now<aw.nextShot then return end
    local generation=aw.generation
    aw.nextShot=now+.003; aw.firing=true
    task.spawn(function()
        local ok,reason=pcall(function()
            if not aw.enabled or aw.generation~=generation or tool.Parent~=player.Character
                or not SC.canSelectPlayer(target) or not SC.autoWinCombat() or aw.skipped[target.UserId] then return end
            local args=aw.arguments[tool] or table.pack()
            assert(type(object.fire)=="function","M1911 firing method unavailable")
            local head=model:FindFirstChild("Head") or targetRoot
            local camera=workspace.CurrentCamera
            if camera and (head.Position-camera.CFrame.Position).Magnitude>.05 then
                camera.CFrame=CFrame.lookAt(camera.CFrame.Position,head.Position)
            end
            aw.replaying[object]=true
            local results=table.pack(pcall(object.fire,object,table.unpack(args,1,args.n)))
            aw.replaying[object]=nil
            if not results[1] then
                aw.ready[tool]=nil;aw.arguments[tool]=nil;aw.nextPrime=0
                error(results[2],0)
            end
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
    cancelPrime()
    for _,link in ipairs(aw.shotLinks) do link:Disconnect() end
    table.clear(aw.shotLinks)
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
    toggle.Activated:Connect(function(input)
        if input then aw.lastInput=input end
        SC.setAutoWin(not aw.enabled)
    end)
    names.Activated:Connect(function()aw.listOpen=not aw.listOpen; aw.update()end)
    priorityNames.Activated:Connect(function()aw.killListOpen=not aw.killListOpen; aw.update()end)
    aw.refreshPlayers(); aw.update()
end
return aw
end)(SC,{Players=Players,Run=RS,player=player,connect=connect,make=make,button=textButton,black=BLACK,white=WHITE,
 stopMovement=SC.stopConflictingMovement,stopFly=stopCFly,startFly=startCFly,
 ensureFire=ensureFireHook,ensureRecoil=ensureNoRecoilHook,ensureSpread=ensureNoSpreadHook,
 updateJuggernaut=updateJuggernaut,getJuggernaut=function()return juggernautPlayer end})

addCategory("Vehicles",function(panel)
 local ok,reason=pcall(function()
  if not SC.vehicles then SC.installVehicles()end
  SC.vehicles.draw(panel)
 end)
 if not ok then make("TextLabel",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text="Vehicles could not start:\n"..tostring(reason),TextWrapped=true,TextColor3=WHITE,Font=Enum.Font.Code,TextSize=14},panel)end
end)
addCategory("AutoWin",SC.autoWin.draw)
function SC.installBuilding()
return (function(SC,ctx)
local state={enabled=false,saves={},selected=nil,status='',saveBusy=false,listBusy=false}
SC.building=state
local function ownerAllowed()return SC.isOwnerAccount(ctx.player)and SC.ownerFeatures and not SC.closing and not SC.paused end
local function allowed()return SC.canBuild()and not SC.closing and not SC.paused end
local function update()if state.update then state.update()end;if state.ownerUpdate then state.ownerUpdate()end end
local function report(text)state.status=text or'';update()end
local function api()
 if not state.api then
  assert(SC.canBuild(),'Building access required')
  state.api=ctx.createBuilder({enabled=false,hideShortcut=true})
 end
 return state.api
end
local function localSaves()
 local data=_G.HeadLockNamedBuilds
 if type(data)~='table'and type(readfile)=='function'then local ok,value=pcall(function()return ctx.Http:JSONDecode(readfile('HeadLockNamedBuilds_v1.json'))end);if ok then data=value end end
 if type(data)~='table'then data={}end
 _G.HeadLockNamedBuilds=data;return data
end
local function cacheSave(saved,doc)
 local all=localSaves();local key=tostring(ctx.player.UserId)..':'..tostring(game.PlaceId)
 all[key]=all[key]or{};all[key][saved.id]={id=saved.id,name=saved.name,updatedAt=saved.updatedAt,parts=#doc.parts,doc=doc}
 if type(writefile)=='function'then pcall(writefile,'HeadLockNamedBuilds_v1.json',ctx.Http:JSONEncode(all))end
end
function SC.setBuilding(value)
 value=value==true and allowed()
 if not value then if state.enabled and SC.ownerSync then SC.ownerSync.pendingBuild=true end;state.enabled=false;if state.api then state.api.setEnabled(false)end;if state.prompt then state.prompt:Destroy();state.prompt=nil end;update();return false end
 local ok,why=pcall(function()
  local builder=api();local net=SC.ownerSync;local principal=net and net.buildOwner or ctx.player.UserId;local shared=net and net.docs[tostring(principal)]
  if shared and(net.editingOwner~=principal or #builder.document().parts==0)then builder.sync(shared,true)
  elseif SC.temporaryAccess and(not net or net.editingOwner~=principal)then builder.sync({format='HeadLockTrack',version=1,placeId=game.PlaceId,name='Build',parts={}},true)end
  if net then net.attach()end
  builder.setEnabled(true);builder.openMenu();state.enabled=true
 end)
 if not ok then report(tostring(why));return false end
 update();return true
end
function SC.setTemporaryAccess(value,principal)
 value=value==true and not SC.isOwnerAccount(ctx.player)
 local before=SC.temporaryAccess==true
 if before==value and state.accessPrincipal==principal then return end
 if before and(not value or state.accessPrincipal~=principal)then
  SC.setBuilding(false)
  if state.api then state.api.sync({format='HeadLockTrack',version=1,placeId=game.PlaceId,name='Build',parts={}},true)end
  if SC.ownerSync then SC.ownerSync.detach()end
  SC.rapidFirePower=100;SC.rapidFireEnabled=false
  if SC.setAutoWin then SC.setAutoWin(false)end
 end
 SC.temporaryAccess=value;state.accessPrincipal=principal
 if SC.refreshOwnerCategories then SC.refreshOwnerCategories()end
 if SC.updateRapidFire then SC.updateRapidFire()end
 update()
end
function state.save(name,saveId)
 if not ownerAllowed()or state.saveBusy then return end
 name=tostring(name or''):match('^%s*(.-)%s*$'):gsub('%c',''):sub(1,80)
 if name==''then report('Enter a name');return end
 local net=SC.ownerSync;if not net or not net.owner then report('Private owner access required');return end
 local ok,doc=pcall(function()return api().document()end);if not ok then report(tostring(doc));return end
 doc.name=name;saveId=saveId or ctx.Http:GenerateGUID(false):gsub('[{}%-]','')
 state.saveBusy=true;report('Saving')
 net.enqueue('save',{saveId=saveId,name=name,doc=doc},function(success,data)
  state.saveBusy=false
  if success then cacheSave(data.saved,doc);state.selected=data.saved;report('Saved '..name);if state.prompt then state.prompt:Destroy();state.prompt=nil end;state.list()
  else report('Save failed: '..tostring(data))end
 end)
end
function state.list()
 if not ownerAllowed()or state.listBusy then return end
 local net=SC.ownerSync;if not net or not net.owner then report('Private owner access required');return end
 state.listBusy=true
 net.enqueue('list',{},function(success,data)
  state.listBusy=false
  if success then state.saves=data.saves or{};state.status=''else state.status='Saves unavailable: '..tostring(data)end
  update()
 end)
end
function state.load()
 if not ownerAllowed()or not state.selected or state.saveBusy then return end
 local chosen=state.selected;local net=SC.ownerSync
 if not net or not net.owner then report('Private owner access required');return end
 state.saveBusy=true;report('Loading')
 net.enqueue('load',{saveId=chosen.id},function(success,data)
  state.saveBusy=false
  if not success then report('Load failed: '..tostring(data));return end
  local ok,why=pcall(function()api().import(data.doc)end)
  if ok then net.pendingBuild=true;report('Loaded '..chosen.name)else report('Load failed: '..tostring(why))end
 end)
end
function state.namePrompt()
 if not ownerAllowed()then return end
 if state.prompt then state.prompt:Destroy()end
 local make,button=ctx.make,ctx.button
 local frame=make('Frame',{Name='BuildNamePrompt',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(300,156),BackgroundColor3=ctx.black,ZIndex=25,Active=true},ctx.gui);state.prompt=frame
 make('UIStroke',{Color=ctx.white,Thickness=1},frame)
 make('TextLabel',{Text='Build name',Position=UDim2.fromOffset(12,8),Size=UDim2.new(1,-24,0,26),BackgroundTransparency=1,TextColor3=ctx.white,TextSize=16,Font=Enum.Font.Code,ZIndex=26},frame)
 local name=make('TextBox',{Name='BuildSaveName',Text='',PlaceholderText='Name',ClearTextOnFocus=false,Position=UDim2.fromOffset(12,44),Size=UDim2.new(1,-24,0,34),BackgroundColor3=ctx.black,TextColor3=ctx.white,TextSize=15,Font=Enum.Font.Code,ZIndex=26},frame);make('UIStroke',{Color=ctx.white,Thickness=1},name)
 local save=button('Save',frame);save.Position=UDim2.fromOffset(12,100);save.Size=UDim2.fromOffset(130,34);save.ZIndex=26
 local cancel=button('Cancel',frame);cancel.Position=UDim2.fromOffset(158,100);cancel.Size=UDim2.fromOffset(130,34);cancel.ZIndex=26
 local existing
 name:GetPropertyChangedSignal('Text'):Connect(function()existing=nil;save.Text='Save'end)
 save.Activated:Connect(function()
  local text=name.Text:match('^%s*(.-)%s*$');local match
  for _,item in ipairs(state.saves)do if item.name:lower()==text:lower()then match=item;break end end
  if match and existing~=match.id then existing=match.id;save.Text='Overwrite';return end
  state.save(text,match and match.id or nil)
 end)
 cancel.Activated:Connect(function()frame:Destroy();if state.prompt==frame then state.prompt=nil end end)
 name:CaptureFocus()
end
function SC.drawBuilding(container)
 if not allowed()then return end
 local make,button=ctx.make,ctx.button
 local panel=make('ScrollingFrame',{Name='BuildingSettings',Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,CanvasSize=UDim2.fromOffset(0,500)},container)
 make('TextLabel',{Text='Building',Size=UDim2.new(1,0,0,30),BackgroundTransparency=1,TextColor3=ctx.white,TextSize=20,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left},panel)
 local toggle=button('OFF',panel);toggle.Name='BuildingToggle';toggle.Position=UDim2.fromOffset(0,38);toggle.Size=UDim2.fromOffset(105,36)
 local save=button('Save Build',panel);save.Name='SaveBuild';save.Position=UDim2.fromOffset(0,90);save.Size=UDim2.new(.5,-3,0,34)
 local saves=button('Saves',panel);saves.Position=UDim2.new(.5,3,0,90);saves.Size=UDim2.new(.5,-3,0,34)
 local list=make('ScrollingFrame',{Name='BuildSaves',Position=UDim2.fromOffset(0,134),Size=UDim2.new(1,-3,0,232),CanvasSize=UDim2.new(),BorderSizePixel=0,ScrollBarThickness=3,BackgroundTransparency=1,Visible=false},panel)
 local load=button('Load Build',panel);load.Name='LoadBuild';load.Position=UDim2.fromOffset(0,376);load.Size=UDim2.new(1,0,0,34)
 local status=make('TextLabel',{Name='BuildingStatus',Position=UDim2.fromOffset(0,420),Size=UDim2.new(1,0,0,64),BackgroundTransparency=1,TextWrapped=true,TextColor3=ctx.white,TextSize=13,Font=Enum.Font.Code},panel)
 local cloud=ownerAllowed();save.Visible=cloud;saves.Visible=cloud;load.Visible=cloud
 local rows={};local last=''
 state.update=function()
  if not panel.Parent then state.update=nil;return end
  toggle.Text=state.enabled and'ON'or'OFF';toggle.BackgroundColor3=state.enabled and ctx.white or ctx.black;toggle.TextColor3=state.enabled and ctx.black or ctx.white
  status.Text=state.status~=''and state.status or(SC.ownerSync and SC.ownerSync.error or'')
  local key=ctx.Http:JSONEncode(state.saves)..':'..tostring(state.selected and state.selected.id)
  if key~=last then
   last=key;for _,row in ipairs(rows)do row:Destroy()end;rows={}
   for i,item in ipairs(state.saves)do
    local row=button(item.name,list);row.Name='BuildSave_'..item.id;row.Position=UDim2.fromOffset(0,(i-1)*38);row.Size=UDim2.new(1,-6,0,34);row.TextXAlignment=Enum.TextXAlignment.Left;row.TextTruncate=Enum.TextTruncate.AtEnd
    local selected=state.selected and state.selected.id==item.id;row.BackgroundColor3=selected and ctx.white or ctx.black;row.TextColor3=selected and ctx.black or ctx.white
    row.Activated:Connect(function()state.selected=item;update()end);table.insert(rows,row)
   end
   list.CanvasSize=UDim2.fromOffset(0,#state.saves*38)
  end
 end
 toggle.Activated:Connect(function()SC.setBuilding(not state.enabled)end)
 save.Activated:Connect(function()state.namePrompt()end)
 saves.Activated:Connect(function()list.Visible=not list.Visible;if list.Visible then state.list()end end)
 load.Activated:Connect(state.load)
 state.update();if state.enabled and state.api then state.api.openMenu()end
end
function SC.drawOwnerPanel(container)
 if not ownerAllowed()then return end
 local make,button=ctx.make,ctx.button
 local panel=make('Frame',{Size=UDim2.fromScale(1,1),BackgroundTransparency=1},container)
 make('TextLabel',{Text='Owner Panel',Size=UDim2.new(1,0,0,30),BackgroundTransparency=1,TextColor3=ctx.white,TextSize=20,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left},panel)
 local status=make('TextLabel',{Name='OwnerStatus',Position=UDim2.fromOffset(0,34),Size=UDim2.new(1,0,0,38),TextWrapped=true,BackgroundTransparency=1,TextColor3=ctx.white,TextSize=12,Font=Enum.Font.Code},panel)
 local list=make('ScrollingFrame',{Name='OwnerUsers',Position=UDim2.fromOffset(0,80),Size=UDim2.new(1,0,1,-80),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,CanvasSize=UDim2.new()},panel)
 local last='';local rows={}
 state.ownerUpdate=function()
  if not panel.Parent then state.ownerUpdate=nil;return end
  local net=SC.ownerSync;status.Text=net and net.error or'Connecting'
  local users=net and net.roster or{};local visible={}
  for _,user in ipairs(users)do table.insert(visible,{user.session,user.username,user.owner,user.actual.paused,user.actual.soundsPaused,user.pending,user.access})end
  local fingerprint=ctx.Http:JSONEncode(visible)
  if fingerprint==last then return end;last=fingerprint
  for _,row in ipairs(rows)do row:Destroy()end;rows={}
  local count=0
  for _,user in ipairs(users)do if not user.owner then
   local frame=make('Frame',{Name='OwnerUser_'..user.session,Position=UDim2.fromOffset(0,count*128),Size=UDim2.new(1,-6,0,122),BackgroundTransparency=1},list);table.insert(rows,frame);count+=1
   make('TextLabel',{Text=user.username,Position=UDim2.fromOffset(0,0),Size=UDim2.new(.62,0,0,28),TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,BackgroundTransparency=1,TextColor3=ctx.white,TextSize=14,Font=Enum.Font.Code},frame)
   local flags=(user.actual.paused and'Paused'or'Active')..(user.actual.soundsPaused and' / Muted'or'')..(user.pending and' …'or'')
   make('TextLabel',{Text=flags,Position=UDim2.new(.62,0,0,0),Size=UDim2.new(.38,0,0,28),BackgroundTransparency=1,TextColor3=ctx.white,TextSize=10,Font=Enum.Font.Code},frame)
   for i,item in ipairs({{'Pause','pause'},{'Resume','resume'},{'Mute','mute'},{'Unmute','unmute'},{'Kick','kick'}})do
    local b=button(item[1],frame);b.Name='Owner_'..item[2];b.Position=UDim2.new((i-1)/5,0,0,36);b.Size=UDim2.new(.2,-3,0,34);b.TextSize=11
    b.Activated:Connect(function()if ownerAllowed()and net then net.command(user.session,item[2])end end)
   end
   local access=button(user.access and'Revoke Access'or'Give Access',frame);access.Name='Owner_access';access.Position=UDim2.fromOffset(0,76);access.Size=UDim2.new(1,-3,0,32);access.TextSize=12
   access.Activated:Connect(function()if ownerAllowed()and net then net.command(user.session,user.access and'revoke'or'grant')end end)
   if user.room~=net.room and not user.access then access.Text='Different server';access.Active=false end
  end end
  list.CanvasSize=UDim2.fromOffset(0,count*128)
 end
 state.ownerUpdate()
end
function state.cleanup()
 state.update=nil;state.ownerUpdate=nil
 if state.prompt then state.prompt:Destroy();state.prompt=nil end
 if state.api then state.api.cleanup();state.api=nil end
end
return state
end)(SC,{player=player,Run=RS,Http=game:GetService('HttpService'),gui=gui,make=make,button=textButton,black=BLACK,white=WHITE,
 createBuilder=function(options)return (function(options)
options=options or{}
local Players=game:GetService('Players')
local UIS=game:GetService('UserInputService')
local Run=game:GetService('RunService')
local Http=game:GetService('HttpService')
local GuiService=game:GetService('GuiService')
local player=Players.LocalPlayer
local pg=player:WaitForChild('PlayerGui')
if type(_G.HeadLockTrackBuilderCleanup)=='function' then pcall(_G.HeadLockTrackBuilderCleanup)end
local api={version=6}
local ui={boxEnabled=true,trowelMode='Move',blocked={},currentTool='Move',brush={material='Concrete',color=Color3.fromRGB(110,110,110),transparency=0},tools={},toolListeners={}}
ui.settings=type(_G.HeadLockTrackBuilderSettings)=='table'and _G.HeadLockTrackBuilderSettings or{}
_G.HeadLockTrackBuilderSettings=ui.settings
local LIMIT=1500
local MIN,MAX=.05,2048
local PREFIX='HEADLOCK_TRACK_V1\n'
local backupFile='HeadLockTrack_Draft_v1.json'
local connections={}
local objects={}
local history,redo={},{}
local selected,drag,panelDrag
local selection={}
local multiSelect=true
local selectionBoxes={}
local circle={count=24,radius=20,sweep=360,axis='Y'}
local circleCenter,circleManual
local circleFields={}
local circleCenterButton,groupSizeLabel,circleAxisButton
local mode,shape,tab='Idle','Block','Build'
local moveStep,angleStep=1,15
local localAxes=ui.settings.localAxes~=false
local closed,minimized=false,false
local changed=false
local nextId=0
local blockWorldUntil=0
local lastTouch,lastTouchAt
local trackName='My track'
local white=Color3.new(1,1,1)
local black=Color3.new(0,0,0)
local gray=Color3.fromRGB(170,170,170)
local folder=workspace:FindFirstChild('HeadLockTrackDraft')
if not folder or not folder:IsA('Folder')then folder=Instance.new('Folder');folder.Name='HeadLockTrackDraft';folder.Parent=workspace end
local function connect(signal,fn)local c=signal:Connect(fn);table.insert(connections,c);return c end
local cameraLocks,cameraRecords={},{}
local frozenFrame,frozenFocus
local cameraBinding='HeadLockTrackBuilderCamera_'..tostring(player.UserId)
local function freezeCamera()
 local camera=workspace.CurrentCamera
 if not camera then return end
 if not cameraRecords[camera]then cameraRecords[camera]={kind=camera.CameraType}end
 if not frozenFrame then frozenFrame=camera.CFrame;frozenFocus=camera.Focus end
 camera.CameraType=Enum.CameraType.Scriptable
 camera.CFrame=frozenFrame;camera.Focus=frozenFocus
end
local function lockCamera(key)
 if closed then return end
 cameraLocks[key]=true;freezeCamera()
end
local function restoreCamera()
 for camera,saved in pairs(cameraRecords)do
  pcall(function()if camera.CameraType==Enum.CameraType.Scriptable then camera.CameraType=saved.kind end end)
 end
 table.clear(cameraRecords);frozenFrame=nil;frozenFocus=nil
end
local function unlockCamera(key)
 cameraLocks[key]=nil
 if not next(cameraLocks)then restoreCamera()end
end
local function unlockAllCamera()
 table.clear(cameraLocks);restoreCamera()
end
Run:BindToRenderStep(cameraBinding,Enum.RenderPriority.Camera.Value+1,function()
 if not closed and next(cameraLocks)then freezeCamera()end
end)
local function make(class,parent,props)
 local o=Instance.new(class)
 if o:IsA('GuiObject')then o.BorderSizePixel=0 end
 if class=='TextButton'or class=='TextLabel'or class=='TextBox'then o.Font=Enum.Font.Sarpanch;o.TextColor3=white;o.TextSize=13 end
 for k,v in pairs(props or {})do o[k]=v end
 o.Parent=parent;return o
end
local function stroke(o)make('UIStroke',o,{Color=white,Thickness=1,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})end
local function finite(n)return type(n)=='number'and n==n and math.abs(n)<1e8 end
local function number(text)local n=tonumber(text);if finite(n)then return n end end
local function snap(n,step)if step<=0 then return n end;return math.floor(n/step+.5)*step end
local function list(v)return {v.X,v.Y,v.Z}end
local function enumName(v)return v.Name end
local function vector(a)return Vector3.new(a[1],a[2],a[3])end
local function member(enum,name)local ok,v=pcall(function()return enum[name]end);if ok then return v end end
local classes={Part=true,WedgePart=true,CornerWedgePart=true}
local shapes={Block=true,Ball=true,Cylinder=true}
local surfaces={'TopSurface','BottomSurface','LeftSurface','RightSurface','FrontSurface','BackSurface'}
local function record(p)
 local data={id=p:GetAttribute('TrackPieceId'),class=p.ClassName,name=p.Name,size=list(p.Size),cf={p.CFrame:GetComponents()},
  color={p.Color.R,p.Color.G,p.Color.B},material=enumName(p.Material),materialVariant=p.MaterialVariant,
  transparency=p.Transparency,reflectance=p.Reflectance,canCollide=p.CanCollide,canTouch=p.CanTouch,canQuery=p.CanQuery,
  castShadow=p.CastShadow,anchored=true,surfaces={}}
 if p:IsA('Part')then data.shape=enumName(p.Shape)end
 for _,key in ipairs(surfaces)do data.surfaces[key]=enumName(p[key])end
 local phys=p.CustomPhysicalProperties
 if phys then data.physics={phys.Density,phys.Friction,phys.Elasticity,phys.FrictionWeight,phys.ElasticityWeight}end
 return data
end
local function count()local n=0;for _,p in pairs(objects)do if p.Parent==folder then n+=1 end end;return n end
local function exists(p)return p and p.Parent==folder and objects[p:GetAttribute('TrackPieceId')]==p end
local function selectionParts()
 local list={}
 for id in pairs(selection)do
  local part=objects[id]
  if exists(part)then selection[id]=part;table.insert(list,part)else selection[id]=nil end
 end
 table.sort(list,function(a,b)return a:GetAttribute('TrackPieceId')<b:GetAttribute('TrackPieceId')end)
 if not exists(selected)or not selection[selected:GetAttribute('TrackPieceId')]then selected=list[#list]end
 return list
end
local function groupBounds(parts,basis)
 parts=parts or selectionParts()
 if #parts==0 then return nil end
 if #parts==1 and not basis then return parts[1].CFrame,parts[1].Size end
 local ref=basis or(exists(selected)and selected or parts[#parts]).CFrame.Rotation
 local lo=Vector3.new(math.huge,math.huge,math.huge);local hi=-lo
 for _,part in ipairs(parts)do
  for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
   local corner=part.CFrame:PointToWorldSpace(Vector3.new(part.Size.X*x,part.Size.Y*y,part.Size.Z*z)/2)
   local v=ref:PointToObjectSpace(corner)
   lo=Vector3.new(math.min(lo.X,v.X),math.min(lo.Y,v.Y),math.min(lo.Z,v.Z));hi=Vector3.new(math.max(hi.X,v.X),math.max(hi.Y,v.Y),math.max(hi.Z,v.Z))
  end end end
 end
 return ref*CFrame.new((lo+hi)/2),hi-lo
end
local function snapshot(parts)
 local out={};for _,part in ipairs(parts)do out[part:GetAttribute('TrackPieceId')]=record(part)end;return out
end
local function newId()nextId+=1;return 'p_'..Http:GenerateGUID(false):gsub('[{}%-]','')..'_'..nextId end
local function normalize(doc)
 assert(type(doc)=='table'and doc.format=='HeadLockTrack'and doc.version==1,'Not a Track Builder export')
 assert(type(doc.parts)=='table'and #doc.parts<=LIMIT,'Track is too large')
 assert(doc.placeId==game.PlaceId,'This track belongs to a different map/place')
 local seen,out={},{}
 local function array(v,n,lo,hi)
  assert(type(v)=='table'and #v==n,'Invalid number array')
  local a={};for i=1,n do assert(finite(v[i])and v[i]>=lo and v[i]<=hi,'Value outside supported range');a[i]=v[i]end;return a
 end
 for _,raw in ipairs(doc.parts)do
  assert(type(raw)=='table'and classes[raw.class],'Unsupported part class')
  assert(type(raw.id)=='string'and #raw.id>0 and #raw.id<=100 and not seen[raw.id],'Duplicate or invalid piece ID');seen[raw.id]=true
  local cf=array(raw.cf,12,-1e7,1e7)
  for i=4,12 do assert(math.abs(cf[i])<=1.001,'Invalid rotation')end
  local r1=Vector3.new(cf[4],cf[5],cf[6]);local r2=Vector3.new(cf[7],cf[8],cf[9]);local r3=Vector3.new(cf[10],cf[11],cf[12])
  assert(math.abs(r1.Magnitude-1)<.002 and math.abs(r2.Magnitude-1)<.002 and math.abs(r3.Magnitude-1)<.002,'Invalid rotation')
  assert(math.abs(r1:Dot(r2))<.002 and math.abs(r1:Dot(r3))<.002 and math.abs(r2:Dot(r3))<.002 and r1:Cross(r2):Dot(r3)>.998,'Invalid rotation')
  local transparency=raw.transparency or 0;local reflectance=raw.reflectance or 0
  assert(finite(transparency)and transparency>=0 and transparency<=1 and finite(reflectance)and reflectance>=0 and reflectance<=1,'Invalid appearance')
  assert(type(raw.material)=='string'and member(Enum.Material,raw.material),'Unsupported material')
  if raw.class=='Part'then assert(shapes[raw.shape or 'Block'],'Unsupported shape')end
  local surf={};for _,key in ipairs(surfaces)do local s=raw.surfaces and raw.surfaces[key]or 'Smooth';assert(type(s)=='string'and member(Enum.SurfaceType,s),'Invalid surface');surf[key]=s end
  local phys=raw.physics and array(raw.physics,5,0,100)or nil
  if phys then assert(phys[1]>=.01 and phys[1]<=100 and phys[2]<=2 and phys[3]<=1,'Invalid physical properties')end
  table.insert(out,{id=raw.id,class=raw.class,name=tostring(raw.name or 'Track piece'):sub(1,80),size=array(raw.size,3,MIN,MAX),cf=cf,color=array(raw.color,3,0,1),
   shape=raw.shape or 'Block',material=raw.material,materialVariant=type(raw.materialVariant)=='string'and raw.materialVariant:sub(1,100)or '',
   transparency=transparency,reflectance=reflectance,canCollide=raw.canCollide~=false,canTouch=raw.canTouch==true,canQuery=raw.canQuery~=false,
   castShadow=raw.castShadow~=false,anchored=true,surfaces=surf,physics=phys})
 end
 return {format='HeadLockTrack',version=1,placeId=game.PlaceId,name=tostring(doc.name or 'My track'):sub(1,80),parts=out}
end
local function apply(id,data)
 local p=objects[id]
 if data==false then if p then p:Destroy();objects[id]=nil end;return end
 if p and p.ClassName~=data.class then p:Destroy();p=nil end
 if not p then p=Instance.new(data.class);objects[id]=p;p:SetAttribute('TrackPieceId',id)end
 p.Name=data.name;p.Anchored=true;p.Size=vector(data.size);p.CFrame=CFrame.new(table.unpack(data.cf));p.Color=Color3.new(table.unpack(data.color))
 p.Material=Enum.Material[data.material];p.MaterialVariant=data.materialVariant or '';p.Transparency=data.transparency;p.Reflectance=data.reflectance
 p.CanCollide=data.canCollide;p.CanTouch=data.canTouch;p.CanQuery=data.canQuery;p.CastShadow=data.castShadow
 if p:IsA('Part')then p.Shape=Enum.PartType[data.shape or 'Block']end
 for _,key in ipairs(surfaces)do p[key]=Enum.SurfaceType[data.surfaces and data.surfaces[key]or 'Smooth']end
 p.CustomPhysicalProperties=data.physics and PhysicalProperties.new(table.unpack(data.physics))or nil
 p.Parent=folder;return p
end
for _,p in ipairs(folder:GetChildren())do
 if p:IsA('BasePart')and classes[p.ClassName]then
  local id=p:GetAttribute('TrackPieceId')
  if type(id)~='string'or objects[id]then id=newId();p:SetAttribute('TrackPieceId',id)end
  p.Anchored=true;p.CanQuery=true;objects[id]=p
 end
end
local gui=make('ScreenGui',pg,{Name='HeadLockTrackBuilder',ResetOnSpawn=false,IgnoreGuiInset=false,DisplayOrder=10010,ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
local panel=make('Frame',gui,{Name='BuilderPanel',Position=UDim2.fromOffset(24,100),Size=UDim2.fromOffset(330,440),BackgroundColor3=black,Active=true});stroke(panel)
local scale=make('UIScale',panel,{Scale=1})
local title=make('TextButton',panel,{Text='TRACK BUILDER',TextXAlignment=Enum.TextXAlignment.Left,Position=UDim2.fromOffset(12,0),Size=UDim2.new(1,-90,0,36),BackgroundTransparency=1,AutoButtonColor=false})
local minimize=make('TextButton',panel,{Text='−',Position=UDim2.new(1,-74,0,0),Size=UDim2.fromOffset(36,36),BackgroundTransparency=1})
local close=make('TextButton',panel,{Text='×',Position=UDim2.new(1,-38,0,0),Size=UDim2.fromOffset(36,36),BackgroundTransparency=1})
local content=make('Frame',panel,{Position=UDim2.fromOffset(0,36),Size=UDim2.new(1,0,1,-36),BackgroundTransparency=1})
local toolbar=make('Frame',content,{Position=UDim2.fromOffset(10,0),Size=UDim2.new(1,-20,0,32),BackgroundTransparency=1})
local pages={};local tabs={}
local status=make('TextLabel',content,{Name='Status',Position=UDim2.new(0,12,1,-42),Size=UDim2.new(1,-24,0,34),BackgroundTransparency=1,Text='',TextColor3=gray,TextSize=11,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left})
local selectionText=make('TextLabel',content,{Position=UDim2.fromOffset(12,36),Size=UDim2.new(1,-24,0,28),BackgroundTransparency=1,Text='0 PIECES',TextXAlignment=Enum.TextXAlignment.Left,TextSize=12})
for i,name in ipairs({'Build','Edit','Style','Circle','Save'})do
 local b=make('TextButton',toolbar,{Text=string.upper(name),Position=UDim2.new((i-1)/5,0,0,0),Size=UDim2.new(.2,-3,1,0),TextSize=11,BackgroundColor3=black});stroke(b);tabs[name]=b
 local page=make('ScrollingFrame',content,{Name=name..'Page',Position=UDim2.fromOffset(10,106),Size=UDim2.new(1,-20,1,-154),CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=3,BackgroundTransparency=1,Visible=name=='Build',BorderSizePixel=0});pages[name]=page
end
local function tell(text)if not closed then status.Text=text end end
local refresh,selectPart,finishDrag,setTab
local function safe(fn)return function(...)local ok,err=pcall(fn,...);if not ok then tell(tostring(err):gsub('^.-:%d+: ',''):sub(1,140))end end end
local function button(parent,text,x,y,w,fn)
 local b=make('TextButton',parent,{Text=text,Position=UDim2.new(x,2,0,y),Size=UDim2.new(w,-4,0,32),BackgroundColor3=black,AutoButtonColor=true});stroke(b)
 if fn then connect(b.Activated,safe(fn))end;return b
end
local function label(parent,text,y)
 return make('TextLabel',parent,{Text=text,Position=UDim2.fromOffset(3,y),Size=UDim2.new(1,-6,0,22),BackgroundTransparency=1,TextColor3=gray,TextXAlignment=Enum.TextXAlignment.Left,TextSize=11})
end
local function field(parent,name,x,y,w,text,fn)
 local b=make('TextBox',parent,{Name=name,Text=text or '',PlaceholderText=name,ClearTextOnFocus=false,Position=UDim2.new(x,2,0,y),Size=UDim2.new(w,-4,0,31),BackgroundColor3=black,TextSize=13});stroke(b)
 if fn then connect(b.FocusLost,safe(function()fn(b.Text)end))end;return b
end
local box=make('SelectionBox',gui,{Color3=Color3.fromRGB(0,134,171),SurfaceColor3=Color3.fromRGB(0,134,171),SurfaceTransparency=.5,LineThickness=.04})
local handles,arcs
local gizmo=make('Part',workspace,{Name='TrackBuilderGizmo',Anchored=true,Transparency=1,CanCollide=false,CanTouch=false,CanQuery=false,Size=Vector3.new(1,1,1)})
pcall(function()
 handles=make('Handles',gui,{Color3=white,Faces=Faces.new(Enum.NormalId.Left,Enum.NormalId.Right,Enum.NormalId.Top,Enum.NormalId.Bottom,Enum.NormalId.Front,Enum.NormalId.Back),Visible=false,Style=Enum.HandlesStyle.Movement})
 arcs=make('ArcHandles',gui,{Color3=white,Axes=Axes.new(Enum.Axis.X,Enum.Axis.Y,Enum.Axis.Z),Visible=false})
end)
ui.moveHandles=handles;ui.rotateHandles=arcs
local function document()
 local parts={};for _,p in pairs(objects)do if exists(p)then table.insert(parts,record(p))end end
 table.sort(parts,function(a,b)return a.id<b.id end)
 return {format='HeadLockTrack',version=1,placeId=game.PlaceId,name=trackName,parts=parts}
end
local function draft()
 local data=document();_G.HeadLockTrackDraft=data
 if type(writefile)=='function'then pcall(writefile,backupFile,Http:JSONEncode(data))end
 changed=false
end
local function push(before,after)
 local equal=true;for id,data in pairs(before)do if Http:JSONEncode(data)~=Http:JSONEncode(after[id])then equal=false;break end end
 if equal then return end
 table.insert(history,{before=before,after=after});if #history>50 then table.remove(history,1)end
 table.clear(redo);changed=true
end
local function groupEdit(fn)
 local parts=selectionParts();assert(#parts>0,'Select a piece first')
 if finishDrag then finishDrag()end
 local before=snapshot(parts)
 local ok,err=pcall(fn,parts)
 if not ok then for id,data in pairs(before)do apply(id,data)end;error(err,0)end
 push(before,snapshot(parts));if refresh then refresh()end
end
local function edit(fn)groupEdit(function(parts)for _,part in ipairs(parts)do fn(part)end end)end
local function moveGroup(delta)
 groupEdit(function(parts)for _,part in ipairs(parts)do part.CFrame=part.CFrame+delta end end)
end
local function rotateGroup(turn,world)
 groupEdit(function(parts)
  local pivot=groupBounds(parts)
  local target=world and CFrame.new(pivot.Position)*turn*pivot.Rotation or pivot*turn
  for _,part in ipairs(parts)do part.CFrame=target*pivot:ToObjectSpace(part.CFrame)end
 end)
end
local function scaleLimits(parts)
 local lo,hi=0,math.huge
 for _,part in ipairs(parts)do
  lo=math.max(lo,MIN/math.min(part.Size.X,part.Size.Y,part.Size.Z));hi=math.min(hi,MAX/math.max(part.Size.X,part.Size.Y,part.Size.Z))
 end
 return lo,hi
end
local function scaleGroup(factor)
 groupEdit(function(parts)
  local low,high=scaleLimits(parts);assert(finite(factor)and factor>=low and factor<=high,'Group scale exceeds piece size limits')
  local pivot=groupBounds(parts)
  for _,part in ipairs(parts)do
   local offset=pivot:ToObjectSpace(part.CFrame)
   part.Size=part.Size*factor;part.CFrame=pivot*CFrame.new(offset.Position*factor)*offset.Rotation
  end
 end)
end
local function styleTemplate()
 if exists(selected)then local d=record(selected);return d end
 return {color={.42,.42,.42},material='Concrete',materialVariant='',transparency=0,reflectance=0,canCollide=true,canTouch=false,canQuery=true,castShadow=true,surfaces={}}
end
local function spawnAt(cf)
 assert(count()<LIMIT,'Piece limit reached')
 if finishDrag then finishDrag()end
 local d=styleTemplate();if ui.brushSet then d.material=ui.brush.material;d.color={ui.brush.color.R,ui.brush.color.G,ui.brush.color.B};d.transparency=ui.brush.transparency;d.materialVariant=''end;d.id=newId();d.class=shape=='Ramp'and 'WedgePart'or shape=='Corner'and 'CornerWedgePart'or 'Part';d.shape=shapes[shape]and shape or 'Block'
 d.name=shape;d.size={8,1,8};if shape=='Ramp'or shape=='Corner'then d.size={8,4,12}elseif shape=='Ball'then d.size={4,4,4}elseif shape=='Cylinder'then d.size={2,4,4}end
 if shape=='Block'and ui.brushSet then d.size={2,2,2}end
 d.cf={cf:GetComponents()};d.physics=nil
 local p=apply(d.id,d);push({[d.id]=false},{[d.id]=record(p)});selectPart(p);tell('Placed '..shape..'.');return p
end
local function characterRoot()local c=player.Character;return c and c:FindFirstChild('HumanoidRootPart'),c end
local function frontFrame()
 local root,c=characterRoot();local cam=workspace.CurrentCamera
 local cf=root and root.CFrame or cam.CFrame
 local point=cf.Position+cf.LookVector*12
 local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances=c and {c}or {}
 local hit=workspace:Raycast(point+Vector3.new(0,25,0),Vector3.new(0,-100,0),params)
 local h=(shape=='Ramp'or shape=='Corner')and 2 or (shape=='Ball'or shape=='Cylinder')and 2 or(ui.brushSet and 1 or .5)
 return CFrame.new(hit and hit.Position+Vector3.new(0,h,0)or point)
end
local function deleteSelected()
 local parts=selectionParts();assert(#parts>0,'Select a piece first');finishDrag()
 local before=snapshot(parts);local after={}
 for id in pairs(before)do after[id]=false;apply(id,false)end
 push(before,after);selectPart(nil);tell('Deleted '..#parts..' pieces.')
end
local function selectMany(parts)
 finishDrag();table.clear(selection);selected=nil
 for _,part in ipairs(parts)do if exists(part)then selection[part:GetAttribute('TrackPieceId')]=part;selected=part end end
 if mode=='Place'then mode='Move'end
 if refresh then refresh()end
end
local function duplicate()
 local parts=selectionParts();assert(#parts>0,'Select a piece first');finishDrag();assert(count()+#parts<=LIMIT,'Piece limit reached')
 local pivot,size=groupBounds(parts);local delta=pivot.RightVector*(size.X+moveStep)
 local before,after,copies={},{},{}
 for _,part in ipairs(parts)do
  local d=record(part);d.id=newId();d.cf={(part.CFrame+delta):GetComponents()}
  local copy=apply(d.id,d);before[d.id]=false;after[d.id]=record(copy);table.insert(copies,copy)
 end
 push(before,after);selectMany(copies);tell('Duplicated '..#copies..' pieces.')
end
function ui.copyItems(items,transform)
 assert(count()+#items<=LIMIT,'Piece limit reached')
 local copies,before={},{}
 local ok,err=pcall(function()
  for _,item in ipairs(items)do
   local d=record(item.part);d.id=newId();before[d.id]=false
   transform(d,item)
   table.insert(copies,apply(d.id,d))
  end
 end)
 if not ok then for id in pairs(before)do apply(id,false)end;error(err,0)end
 return copies,before
end
function ui.items(parts)
 local items={};for _,part in ipairs(parts)do table.insert(items,{part=part,cf=part.CFrame,size=part.Size})end;return items
end
function ui.cloneBy(delta)
 assert(typeof(delta)=='Vector3'and finite(delta.X)and finite(delta.Y)and finite(delta.Z),'Invalid clone offset')
 finishDrag();local parts=selectionParts();assert(#parts>0,'Select a piece first')
 if delta.Magnitude<1e-6 then return{}end
 local copies,before=ui.copyItems(ui.items(parts),function(d,item)d.cf={(item.cf+delta):GetComponents()}end)
 push(before,snapshot(copies));ui.assign(copies);return copies
end
function ui.mirrorCopies(parts,face)
 local pivot,size=groupBounds(parts,localAxes and(exists(selected)and selected or parts[#parts]).CFrame.Rotation or CFrame.new())
 local normal=pivot:VectorToWorldSpace(face)
 local extent=math.abs(face.X)*size.X+math.abs(face.Y)*size.Y+math.abs(face.Z)*size.Z
 local plane=pivot.Position+normal*(extent/2)
 local function reflect(v)return v-normal*(2*v:Dot(normal))end
 return ui.copyItems(ui.items(parts),function(d,item)
  local cf=item.cf;local position=plane+reflect(cf.Position-plane)
  local right,up,back=-reflect(cf.RightVector),reflect(cf.UpVector),reflect(-cf.LookVector)
  if d.class=='CornerWedgePart'then
   right=reflect(cf.LookVector);back=-reflect(cf.RightVector)
   d.size={item.size.Z,item.size.Y,item.size.X}
   local old=d.surfaces;d.surfaces={TopSurface=old.TopSurface,BottomSurface=old.BottomSurface,RightSurface=old.FrontSurface,LeftSurface=old.BackSurface,FrontSurface=old.RightSurface,BackSurface=old.LeftSurface}
  else
   d.surfaces.LeftSurface,d.surfaces.RightSurface=d.surfaces.RightSurface,d.surfaces.LeftSurface
  end
  d.cf={position.X,position.Y,position.Z,right.X,up.X,back.X,right.Y,up.Y,back.Y,right.Z,up.Z,back.Z}
 end)
end
function ui.mirrorBy(face)
 finishDrag();local parts=selectionParts();assert(#parts>0,'Select a piece first')
 assert(typeof(face)=='Vector3'and math.abs(face.Magnitude-1)<1e-6 and(math.abs(face.X)==1 or math.abs(face.Y)==1 or math.abs(face.Z)==1),'Choose a mirror axis')
 local copies,before=ui.mirrorCopies(parts,face)
 push(before,snapshot(copies));ui.assign(copies);return copies
end
local circleAxes={X=Vector3.new(1,0,0),Y=Vector3.new(0,1,0),Z=Vector3.new(0,0,1)}
local function circleOrigin(pivot,axis,radius)
 if circleManual and circleCenter then return circleCenter end
 return pivot.Position-(axis=='X'and Vector3.new(0,0,1)or Vector3.new(1,0,0))*radius
end
local function createCircle(options)
 finishDrag();local parts=selectionParts();assert(#parts>0,'Select the pieces to repeat first')
 options=options or {};assert(type(options)=='table','Invalid circle settings')
 local stations=options.count or circle.count;local radius=options.radius or circle.radius;local sweep=options.sweep or circle.sweep;local axis=options.axis or circle.axis
 assert(finite(stations)and stations%1==0 and stations>=2 and stations<=360,'Copies must be a whole number from 2–360')
 assert(finite(radius)and radius>=MIN and radius<=100000,'Radius must be 0.05–100000')
 assert(finite(sweep)and math.abs(sweep)>=.1 and math.abs(sweep)<=360,'Arc must be between 0.1 and 360 degrees')
 assert(circleAxes[axis],'Choose X, Y or Z axis')
 assert(count()+(stations-1)*#parts<=LIMIT,'Too many copies. Maximum 1500 pieces')
 local pivot=groupBounds(parts);local center=options.center or circleOrigin(pivot,axis,radius)
 assert(typeof(center)=='Vector3'and finite(center.X)and finite(center.Y)and finite(center.Z)and math.max(math.abs(center.X),math.abs(center.Y),math.abs(center.Z))<=1e7,'Invalid circle center')
 local normal=circleAxes[axis];local radial=pivot.Position-center;radial=radial-normal*radial:Dot(normal)
 radial=radial.Magnitude>1e-6 and radial.Unit or(axis=='X'and Vector3.new(0,0,1)or Vector3.new(1,0,0))
 local step=math.rad(sweep)/(math.abs(sweep)==360 and stations or stations-1)
 local templates={};for _,part in ipairs(parts)do table.insert(templates,{data=record(part),offset=pivot:ToObjectSpace(part.CFrame)})end
 local before=snapshot(parts);local after={};local ids={}
 for station=0,stations-1 do
  local target=CFrame.new(center)*CFrame.fromAxisAngle(normal,step*station)*CFrame.new(radial*radius)*pivot.Rotation
  for _,item in ipairs(templates)do
   local d=table.clone(item.data);if station>0 then d.id=newId();before[d.id]=false end
   local cf=target*item.offset;local pos=cf.Position
   assert(finite(pos.X)and finite(pos.Y)and finite(pos.Z)and math.max(math.abs(pos.X),math.abs(pos.Y),math.abs(pos.Z))<=1e7,'Circle extends beyond position limits')
   d.cf={cf:GetComponents()};after[d.id]=d;table.insert(ids,d.id)
  end
 end
 local ok,err=pcall(function()for id,data in pairs(after)do apply(id,data)end end)
 if not ok then for id,data in pairs(before)do apply(id,data)end;error(err,0)end
 push(before,after);local copies={};for _,id in ipairs(ids)do table.insert(copies,objects[id])end;selectMany(copies)
 tell('Created '..stations..' stations / '..#copies..' selected pieces.');return copies
end
local function historyStep(from,to,key)
 finishDrag();local entry=table.remove(from);if not entry then tell('Nothing to '..key..'.');return end
 local changes=key=='undo'and entry.before or entry.after
 for id,data in pairs(changes)do apply(id,data)end
 table.insert(to,entry);changed=true;selectionParts();refresh();tell(string.upper(key)..'.')
end
local function clear()
 finishDrag();local before,after={},{}
 for id,p in pairs(objects)do before[id]=record(p);after[id]=false end
 for id in pairs(before)do apply(id,false)end
 push(before,after);selectPart(nil);tell('Draft cleared.')
end
local function import(data)
 finishDrag()
 if type(data)=='string'then assert(#data<4000000,'Import too large');if data:sub(1,#PREFIX)==PREFIX then data=data:sub(#PREFIX+1)end;data=Http:JSONDecode(data)end
 data=normalize(data)
 local before,after={},{}
 for id,p in pairs(objects)do before[id]=record(p);after[id]=false end
 for _,d in ipairs(data.parts)do if before[d.id]==nil then before[d.id]=false end;after[d.id]=d end
 local oldName=trackName
 local ok,err=pcall(function()for id,d in pairs(after)do apply(id,d)end end)
 if not ok then for id,d in pairs(before)do apply(id,d)end;trackName=oldName;error(err,0)end
 trackName=data.name;push(before,after);selectPart(nil);draft();tell('Loaded '..#data.parts..' pieces.');return #data.parts
end
local function sync(data,resetHistory)
 assert(not drag,'Finish the current edit first')
 data=normalize(data)
 local function signature(d)
  local surf={};for _,key in ipairs(surfaces)do table.insert(surf,d.surfaces and d.surfaces[key]or'Smooth')end
  return Http:JSONEncode({d.class,d.name,d.shape or'Block',d.size,d.cf,d.color,d.material,d.materialVariant or'',d.transparency or 0,d.reflectance or 0,d.canCollide~=false,d.canTouch==true,d.canQuery~=false,d.castShadow~=false,surf,d.physics or{}})
 end
 local incoming={};for _,part in ipairs(data.parts)do incoming[part.id]=part end
 local affected={}
 for id,p in pairs(objects)do
  if not incoming[id]then affected[id]=true;apply(id,false)
  elseif signature(record(p))~=signature(incoming[id])then affected[id]=true;apply(id,incoming[id])end
 end
 for id,part in pairs(incoming)do if not objects[id]then affected[id]=true;apply(id,part)end end
 local function prune(stack)
  for i=#stack,1,-1 do
   local entry=stack[i]
   for id in pairs(affected)do entry.before[id]=nil;entry.after[id]=nil end
   if next(entry.before)==nil then table.remove(stack,i)end
  end
 end
 if resetHistory then table.clear(history);table.clear(redo);selectPart(nil)else prune(history);prune(redo);selectionParts()end
 trackName=data.name;changed=true;refresh();return #data.parts
end
local exportBox,exportWindow
local function exportText()return PREFIX..Http:JSONEncode(document())end
local function showTransfer(text)
 if exportWindow then exportWindow:Destroy()end
 exportWindow=make('Frame',gui,{Name='TransferWindow',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.new(.85,0,.78,0),BackgroundColor3=black,Active=true,ZIndex=20});stroke(exportWindow)
 make('TextLabel',exportWindow,{Text='TRACK DATA',Position=UDim2.fromOffset(12,6),Size=UDim2.new(1,-58,0,28),BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=21})
 local closeTransfer=make('TextButton',exportWindow,{Text='×',Position=UDim2.new(1,-38,0,2),Size=UDim2.fromOffset(34,34),BackgroundTransparency=1,ZIndex=21})
 connect(closeTransfer.Activated,function()exportWindow:Destroy();exportWindow=nil;exportBox=nil end)
 exportBox=make('TextBox',exportWindow,{Name='TrackData',Text=text or '',PlaceholderText='Paste a HEADLOCK_TRACK_V1 export here',ClearTextOnFocus=false,MultiLine=true,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,TextSize=11,
  Position=UDim2.fromOffset(12,42),Size=UDim2.new(1,-24,1,-94),BackgroundColor3=black,ZIndex=21});stroke(exportBox)
 local load=button(exportWindow,'LOAD DATA',0,0,.5,function()import(exportBox.Text);exportWindow:Destroy();exportWindow=nil;exportBox=nil end)
 load.Position=UDim2.new(0,12,1,-40);load.Size=UDim2.new(.5,-18,0,30);load.ZIndex=21
 local selectAll=button(exportWindow,'SELECT ALL',.5,0,.5,function()exportBox:CaptureFocus();exportBox.CursorPosition=#exportBox.Text+1;exportBox.SelectionStart=1 end)
 selectAll.Position=UDim2.new(.5,6,1,-40);selectAll.Size=UDim2.new(.5,-18,0,30);selectAll.ZIndex=21
end
local function save()
 finishDrag();draft();local text=exportText()
 local copy=type(setclipboard)=='function'and setclipboard or type(toclipboard)=='function'and toclipboard or type(syn)=='table'and syn.write_clipboard
 local ok=type(copy)=='function'and pcall(copy,text)
 if ok then tell('COPIED '..count()..' pieces.')else showTransfer(text);tell('Clipboard unavailable. Use SELECT ALL and copy.')end
 return text
end
local function updateGizmos()
 local parts=selectionParts();local p=selected
 local accent=ui.colors and(ui.colors[mode]or ui.colors.Move)or Color3.fromRGB(0,134,171)
 box.Color3=accent;box.SurfaceColor3=accent;box.Adornee=mode~='Idle'and p or nil
 for id,outline in pairs(selectionBoxes)do
  if mode=='Idle'or not selection[id]or selection[id]==p then outline:Destroy();selectionBoxes[id]=nil end
 end
 for _,part in ipairs(parts)do
  local id=part:GetAttribute('TrackPieceId')
  if mode~='Idle'and part~=p then
   if not selectionBoxes[id]then selectionBoxes[id]=make('SelectionBox',gui,{Color3=accent,SurfaceColor3=accent,SurfaceTransparency=.5,LineThickness=.04})end
   selectionBoxes[id].Adornee=part;selectionBoxes[id].Color3=accent;selectionBoxes[id].SurfaceColor3=accent
  end
 end
 if ui.groupOutline then ui.groupOutline.Color3=accent;ui.groupOutline.Adornee=mode~='Idle'and #parts>1 and gizmo or nil end
 local pivot,size=groupBounds(parts)
 if mode=='Mirror'and pivot then pivot,size=groupBounds(parts,localAxes and p.CFrame.Rotation or CFrame.new())end
 if pivot then
  gizmo.Size=Vector3.new(math.clamp(size.X,MIN,MAX),math.clamp(size.Y,MIN,MAX),math.clamp(size.Z,MIN,MAX))
  gizmo.CFrame=(localAxes or mode=='Scale'or mode=='Mirror')and pivot or CFrame.new(pivot.Position)
 end
 if handles then handles.Adornee=p and gizmo or nil;handles.Style=mode=='Scale'and Enum.HandlesStyle.Resize or Enum.HandlesStyle.Movement;handles.Color3=accent;handles.Visible=p~=nil and(mode=='Move'or mode=='Scale'or mode=='Clone') end
 if arcs then arcs.Adornee=p and gizmo or nil;arcs.Color3=accent;arcs.Visible=p~=nil and mode=='Rotate' end
 if ui.mirrorHandles then ui.mirrorHandles.Adornee=p and gizmo or nil;ui.mirrorHandles.Visible=p~=nil and mode=='Mirror'end
end
finishDrag=function()
 if ui.cancelBox then ui.cancelBox(false)end
 if not drag then unlockCamera('gizmo');return end
 local d=drag;drag=nil;unlockCamera('gizmo');blockWorldUntil=os.clock()+.15
 if d.clone and(not d.copies or math.abs(d.amount or 0)<1e-6)then
  for _,part in ipairs(d.copies or{})do apply(part:GetAttribute('TrackPieceId'),false)end
  if ui.assign then ui.assign(d.originals)end
  return
 end
 local after={};for id in pairs(d.before)do after[id]=exists(objects[id])and record(objects[id])or false end
 push(d.before,after)
 if refresh then refresh()end
end
local function beginDrag(face)
 if ui.cancelBox then ui.cancelBox(true)end
 finishDrag();local parts=selectionParts()
 if #parts>0 and(mode=='Move'or mode=='Scale'or mode=='Rotate'or mode=='Clone'or mode=='Mirror')then
  local pivot,size=groupBounds(parts);local items={}
  for _,part in ipairs(parts)do table.insert(items,{part=part,cf=part.CFrame,size=part.Size})end
  local low,high=scaleLimits(parts)
  drag={parts=parts,items=items,before=snapshot(parts),pivot=pivot,size=size,low=low,high=high,localAxes=localAxes,
   input=lastTouch and os.clock()-(lastTouchAt or 0)<.2 and lastTouch or nil,clone=mode=='Clone',originals=parts}
  if mode=='Mirror'then
   local copies,before=ui.mirrorCopies(parts,face)
   drag.before=before;drag.parts=copies;ui.assign(copies)
  end
  blockWorldUntil=math.huge;lockCamera('gizmo')
 end
end
local faces={[Enum.NormalId.Right]=Vector3.new(1,0,0),[Enum.NormalId.Left]=Vector3.new(-1,0,0),[Enum.NormalId.Top]=Vector3.new(0,1,0),[Enum.NormalId.Bottom]=Vector3.new(0,-1,0),[Enum.NormalId.Back]=Vector3.new(0,0,1),[Enum.NormalId.Front]=Vector3.new(0,0,-1)}
local axes={[Enum.Axis.X]=Vector3.new(1,0,0),[Enum.Axis.Y]=Vector3.new(0,1,0),[Enum.Axis.Z]=Vector3.new(0,0,1)}
if handles then
 connect(handles.MouseButton1Down,safe(beginDrag))
 connect(handles.MouseDrag,safe(function(face,distance)
  if not drag then return end
  local v=faces[face];if not v then return end
  local amount=snap(distance,moveStep)
  if mode=='Scale'then
   local absolute=Vector3.new(math.abs(v.X),math.abs(v.Y),math.abs(v.Z));local original=drag.size:Dot(absolute)
   if #drag.items==1 then
    local item=drag.items[1];amount=math.clamp(original+amount,MIN,MAX)-original
    item.part.Size=item.size+absolute*amount;item.part.CFrame=item.cf*CFrame.new(v*amount/2)
   else
    local factor=math.clamp((original+amount)/original,drag.low,drag.high);amount=original*(factor-1)
    local pivot=drag.pivot*CFrame.new(v*amount/2)
    for _,item in ipairs(drag.items)do
     local offset=drag.pivot:ToObjectSpace(item.cf)
     item.part.Size=item.size*factor;item.part.CFrame=pivot*CFrame.new(offset.Position*factor)*offset.Rotation
    end
   end
  elseif mode=='Move'or mode=='Clone'then
   local delta=drag.localAxes and drag.pivot:VectorToWorldSpace(v*amount)or v*amount
   if mode=='Clone'then
    drag.amount=amount
    if not drag.copies and math.abs(amount)>1e-6 then
     local copies,before=ui.copyItems(drag.items,function(d,item)d.cf={(item.cf+delta):GetComponents()}end)
     drag.copies=copies;drag.before=before;ui.assign(copies)
    end
    for i,part in ipairs(drag.copies or{})do part.CFrame=drag.items[i].cf+delta end
   else for _,item in ipairs(drag.items)do item.part.CFrame=item.cf+delta end end
  end
  refresh()
 end))
 connect(handles.MouseButton1Up,finishDrag)
end
if arcs then
 connect(arcs.MouseButton1Down,beginDrag)
 connect(arcs.MouseDrag,safe(function(axis,angle)
  if drag and axes[axis]then
   local turn=CFrame.fromAxisAngle(axes[axis],math.rad(snap(math.deg(angle),angleStep)))
   local pivot=drag.localAxes and drag.pivot*turn or CFrame.new(drag.pivot.Position)*turn*drag.pivot.Rotation
   for _,item in ipairs(drag.items)do item.part.CFrame=pivot*drag.pivot:ToObjectSpace(item.cf)end
   refresh()
  end
 end))
 connect(arcs.MouseButton1Up,finishDrag)
end
local modeButtons,shapeButtons={},{}
local fields={}
local function setMode(name)if ui.cancelBox then ui.cancelBox(true)end;finishDrag();mode=name;updateGizmos();refresh();tell('') end
local function nudge(axis,sign)
 local parts=selectionParts();assert(#parts>0,'Select a piece first')
 local v=Vector3.new(axis==1 and 1 or 0,axis==2 and 1 or 0,axis==3 and 1 or 0)
 if mode=='Scale'then
  if #parts>1 then local _,size=groupBounds(parts);scaleGroup((list(size)[axis]+moveStep*sign)/list(size)[axis])
  else edit(function(p)local s=list(p.Size);s[axis]=math.clamp(s[axis]+moveStep*sign,MIN,MAX);p.Size=vector(s)end)end
 elseif mode=='Clone'then local pivot=groupBounds(parts);ui.cloneBy(localAxes and pivot:VectorToWorldSpace(v*moveStep*sign)or v*moveStep*sign)
 elseif mode=='Mirror'then ui.mirrorBy(v*sign)
 elseif mode=='Rotate'then rotateGroup(CFrame.fromAxisAngle(v,math.rad(angleStep*sign)),not localAxes)
 else local pivot=groupBounds(parts);moveGroup(localAxes and pivot:VectorToWorldSpace(v*moveStep*sign)or v*moveStep*sign)end
end
button(content,'ALL',0,66,.5,function()local parts={};for _,part in pairs(objects)do if exists(part)then table.insert(parts,part)end end;selectMany(parts)end)
button(content,'NONE',.5,66,.5,function()selectMany({})end)
local build=pages.Build
label(build,'PIECE',0)
for i,name in ipairs({'Block','Ramp','Corner','Ball','Cylinder'})do
 local col=(i-1)%3;local row=math.floor((i-1)/3)
 shapeButtons[name]=button(build,string.upper(name),col/3,26+row*38,1/3,function()shape=name;refresh()end)
end
button(build,'PLACE AT TAP',0,108,.5,function()if ui.tools.Hammer then ui.equip('Hammer');ui.materialWindow.Visible=false else setMode('Place')end end)
button(build,'ADD IN FRONT',.5,108,.5,function()spawnAt(frontFrame());if ui.tools.Trowel then ui.equip('Move')else setMode('Move')end end)
button(build,'DUPLICATE',0,144,.5,duplicate)
button(build,'DELETE',.5,144,.5,deleteSelected)
button(build,'UNDO',0,184,.5,function()historyStep(history,redo,'undo')end)
button(build,'REDO',.5,184,.5,function()historyStep(redo,history,'redo')end)
local editPage=pages.Edit
for i,name in ipairs({'Move','Rotate','Clone','Mirror','Scale'})do modeButtons[name]=button(editPage,string.upper(name),(i-1)/5,0,1/5,function()if name=='Scale'then ui.equip('Scale')else ui.equip('Trowel');ui.setTrowelMode(name);ui.showMain('Edit')end end);modeButtons[name].TextSize=10 end
local spaceButton=button(editPage,'AXES: LOCAL',0,40,.5,function()ui.setAxes(not localAxes)end)
local snapMove=field(editPage,'Stud step',.5,40,.25,'1',function(t)local n=number(t);assert(n and n>=0 and n<=100,'Step must be 0–100');moveStep=n;refresh()end)
local snapAngle=field(editPage,'Angle step',.75,40,.25,'15',function(t)local n=number(t);assert(n and n>0 and n<=180,'Angle step must be 1–180');angleStep=n;refresh()end)
label(editPage,'POSITION  X / Y / Z',80)
for i=1,3 do
 fields['pos'..i]=field(editPage,'Position'..i,(i-1)/3,105,1/3,'',function(t)local n=number(t);assert(n and math.abs(n)<=1e7,'Invalid position');local pivot=groupBounds();assert(pivot,'Select a piece first');local a=list(pivot.Position);a[i]=n;moveGroup(vector(a)-pivot.Position)end)
end
groupSizeLabel=label(editPage,'SIZE  X / Y / Z',144)
for i=1,3 do fields['size'..i]=field(editPage,'Size'..i,(i-1)/3,169,1/3,'',function(t)local n=number(t);assert(n and n>=MIN and n<=MAX,'Size must be 0.05–2048');local parts=selectionParts();assert(#parts>0,'Select a piece first');if #parts>1 then local _,size=groupBounds(parts);scaleGroup(n/list(size)[i])else edit(function(p)local a=list(p.Size);a[i]=n;p.Size=vector(a)end)end end)end
label(editPage,'ROTATION  X / Y / Z',208)
for i=1,3 do fields['rot'..i]=field(editPage,'Rotation'..i,(i-1)/3,233,1/3,'',function(t)local n=number(t);assert(n and math.abs(n)<=36000,'Invalid angle');groupEdit(function(parts)local pivot=groupBounds(parts);local a={pivot:ToOrientation()};a[i]=math.rad(n);local target=CFrame.new(pivot.Position)*CFrame.fromOrientation(table.unpack(a));for _,p in ipairs(parts)do p.CFrame=target*pivot:ToObjectSpace(p.CFrame)end end)end)end
label(editPage,'X / Y / Z',272)
for i,name in ipairs({'X','Y','Z'})do
 button(editPage,name..' −',(i-1)/3,298,1/6,function()nudge(i,-1)end)
 button(editPage,name..' +',(i-1)/3+1/6,298,1/6,function()nudge(i,1)end)
end
button(editPage,'DUPLICATE',0,338,.5,duplicate);button(editPage,'DELETE',.5,338,.5,deleteSelected)
button(editPage,'UNDO',0,378,.5,function()historyStep(history,redo,'undo')end);button(editPage,'REDO',.5,378,.5,function()historyStep(redo,history,'redo')end)
local style=pages.Style
label(style,'RGB  0–255',0)
for i=1,3 do fields['rgb'..i]=field(style,'Color'..i,(i-1)/3,26,1/3,'',function(t)local n=number(t);assert(n and n>=0 and n<=255,'Color must be 0–255');edit(function(p)local a={p.Color.R,p.Color.G,p.Color.B};a[i]=n/255;p.Color=Color3.new(table.unpack(a))end)end)end
local palette={{'WHITE',255,255,255},{'GRAY',110,110,110},{'BLACK',20,20,20},{'RED',180,45,45},{'YELLOW',245,190,40},{'GREEN',55,140,80},{'BLUE',45,95,180},{'ORANGE',230,110,30}}
for i,item in ipairs(palette)do
 local col=(i-1)%4;local row=math.floor((i-1)/4)
 local b=button(style,item[1],col/4,68+row*38,1/4,function()edit(function(p)p.Color=Color3.fromRGB(item[2],item[3],item[4])end)end)
 b.TextSize=10
end
label(style,'MATERIAL',152)
fields.material=field(style,'Material',0,178,1,'Concrete',function(t)assert(member(Enum.Material,t),'Use an exact material name');edit(function(p)p.Material=Enum.Material[t]end)end)
local materials={'Concrete','Asphalt','Plastic','Metal','Neon','Glass'}
for i,name in ipairs(materials)do button(style,string.upper(name),(i-1)%3/3,222+math.floor((i-1)/3)*38,1/3,function()edit(function(p)p.Material=Enum.Material[name]end)end).TextSize=10 end
label(style,'TRANSPARENCY / REFLECTANCE (0–1)',308)
fields.transparency=field(style,'Transparency',0,334,.5,'0',function(t)local n=number(t);assert(n and n>=0 and n<=1,'Transparency must be 0–1');edit(function(p)p.Transparency=n end)end)
fields.reflectance=field(style,'Reflectance',.5,334,.5,'0',function(t)local n=number(t);assert(n and n>=0 and n<=1,'Reflectance must be 0–1');edit(function(p)p.Reflectance=n end)end)
local collideButton=button(style,'COLLISION: ON',0,380,.5,function()assert(exists(selected),'Select a piece first');local enabled=not selected.CanCollide;edit(function(p)p.CanCollide=enabled end)end)
local shadowButton=button(style,'SHADOW: ON',.5,380,.5,function()assert(exists(selected),'Select a piece first');local enabled=not selected.CastShadow;edit(function(p)p.CastShadow=enabled end)end)
local circlePage=pages.Circle
label(circlePage,'COPIES / RADIUS / ARC',0)
circleFields.count=field(circlePage,'CircleCopies',0,26,1/3,'24',function(t)local n=number(t);assert(n and n%1==0 and n>=2 and n<=360,'Stations must be 2–360');circle.count=n;refresh()end)
circleFields.radius=field(circlePage,'CircleRadius',1/3,26,1/3,'20',function(t)local n=number(t);assert(n and n>=MIN and n<=100000,'Radius must be 0.05–100000');circle.radius=n;refresh()end)
circleFields.sweep=field(circlePage,'CircleArc',2/3,26,1/3,'360',function(t)local n=number(t);assert(n and math.abs(n)>=.1 and math.abs(n)<=360,'Arc must be 0.1–360 degrees');circle.sweep=n;refresh()end)
circleAxisButton=button(circlePage,'AXIS: Y',0,70,1,function()circle.axis=circle.axis=='Y'and 'X'or circle.axis=='X'and 'Z'or 'Y';refresh()end)
label(circlePage,'CENTER  X / Y / Z',112)
for i=1,3 do circleFields['center'..i]=field(circlePage,'CircleCenter'..i,(i-1)/3,138,1/3,'',function(t)
 local n=number(t);assert(n and math.abs(n)<=1e7,'Invalid center');local pivot=groupBounds();assert(pivot,'Select a piece first')
 local coords=list(circleOrigin(pivot,circle.axis,circle.radius));coords[i]=n;circleCenter=vector(coords);circleManual=true;refresh()
end)end
circleCenterButton=button(circlePage,'CENTER: AUTO',0,180,.5,function()circleCenter=nil;circleManual=false;refresh()end)
button(circlePage,'USE SELECTION',.5,180,.5,function()local pivot=groupBounds();assert(pivot,'Select a piece first');circleCenter=pivot.Position;circleManual=true;refresh()end)
button(circlePage,'CREATE CIRCLE / ARC',0,226,1,function()createCircle()end)
button(circlePage,'UNDO',0,268,.5,function()historyStep(history,redo,'undo')end)
button(circlePage,'REDO',.5,268,.5,function()historyStep(redo,history,'redo')end)
local savePage=pages.Save
label(savePage,'TRACK NAME',0)
local nameBox=field(savePage,'Track name',0,26,1,trackName,function(t)trackName=t:sub(1,80);changed=true;refresh()end)
button(savePage,'SAVE + COPY',0,72,1,save)
button(savePage,'VIEW / IMPORT DATA',0,116,1,function()showTransfer(exportText())end)
button(savePage,'RESTORE LOCAL DRAFT',0,160,1,function()
 local data=_G.HeadLockTrackDraft
 if not data and type(readfile)=='function'and type(isfile)=='function'and isfile(backupFile)then data=readfile(backupFile)end
 assert(data,'No saved draft yet');import(data)
end)
local clearArmed=0
button(savePage,'CLEAR DRAFT',0,204,1,function()
 if os.clock()>clearArmed then clearArmed=os.clock()+3;tell('Press CLEAR DRAFT again to confirm.');return end
 clearArmed=0;clear()
end)
local function setText(box,text)if not box:IsFocused()then box.Text=text end end
refresh=function()
 local chosen=selectionParts();local p=selected;local pivot,extent=groupBounds(chosen)
 selectionText.Text=tostring(count())..' PIECES  /  '..#chosen..' SELECTED'
 groupSizeLabel.Text=#chosen>1 and 'GROUP SIZE'or 'SIZE  X / Y / Z'
 circleAxisButton.Text='AXIS: '..circle.axis
 circleCenterButton.Text=circleManual and 'RESET CENTER'or 'CENTER: AUTO'
 for _,key in ipairs({'count','radius','sweep'})do setText(circleFields[key],tostring(circle[key]))end
 local center=pivot and list(circleOrigin(pivot,circle.axis,circle.radius))or nil
 for i=1,3 do setText(circleFields['center'..i],center and string.format('%.3f',center[i])or '')end
 if p then
  local pos,size=list(pivot.Position),list(extent);local rot={pivot:ToOrientation()};local rgb={p.Color.R*255,p.Color.G*255,p.Color.B*255}
  for i=1,3 do setText(fields['pos'..i],string.format('%.3f',pos[i]));setText(fields['size'..i],string.format('%.3f',size[i]));setText(fields['rot'..i],string.format('%.2f',math.deg(rot[i])));setText(fields['rgb'..i],string.format('%.1f',rgb[i]))end
  setText(fields.material,p.Material.Name);setText(fields.transparency,string.format('%.2f',p.Transparency));setText(fields.reflectance,string.format('%.2f',p.Reflectance))
 else for _,b in pairs(fields)do setText(b,'')end end
 collideButton.Text='COLLISION: '..(p and not p.CanCollide and 'OFF'or 'ON');shadowButton.Text='SHADOW: '..(p and not p.CastShadow and 'OFF'or 'ON')
 spaceButton.Text='AXES: '..(localAxes and 'LOCAL'or 'WORLD')
 setText(nameBox,trackName);setText(snapMove,tostring(moveStep));setText(snapAngle,tostring(angleStep))
 for name,b in pairs(shapeButtons)do b.BackgroundColor3=name==shape and white or black;b.TextColor3=name==shape and black or white end
 for name,b in pairs(modeButtons)do b.BackgroundColor3=name==mode and white or black;b.TextColor3=name==mode and black or white end
 updateGizmos();if ui.refresh then ui.refresh()end
end
selectPart=function(p,additive)
 finishDrag()
 if additive and exists(p)then
  local id=p:GetAttribute('TrackPieceId')
  if selection[id]then selection[id]=nil else selection[id]=p;selected=p end
 else table.clear(selection);selected=exists(p)and p or nil;if selected then selection[selected:GetAttribute('TrackPieceId')]=selected end end
 selectionParts();if mode=='Place'then mode='Move'end;refresh()
end
setTab=function(name)
 finishDrag();tab=name
 for key,page in pairs(pages)do page.Visible=key==name;tabs[key].BackgroundColor3=key==name and white or black;tabs[key].TextColor3=key==name and black or white end
 refresh()
end
for name,b in pairs(tabs)do connect(b.Activated,function()setTab(name)end)end
local function clampPanel()
 local camera=workspace.CurrentCamera;if not camera then return end
 local inset,bottom=GuiService:GetGuiInset();local width,height=camera.ViewportSize.X,camera.ViewportSize.Y-inset.Y-bottom.Y
 local s=math.clamp(math.min(1,(width-20)/330,(height-16)/440),.6,1)
 scale.Scale=s
 local w,h=330*s,(minimized and 36 or 440)*s
 panel.Position=UDim2.fromOffset(math.clamp(panel.Position.X.Offset,0,math.max(0,width-w)),math.clamp(panel.Position.Y.Offset,0,math.max(0,height-h)))
 if ui.layout then ui.layout()end
end
ui.colors={Clone=Color3.fromRGB(0,134,171),Mirror=Color3.fromRGB(245,110,175),Move=Color3.fromRGB(0,134,171),Rotate=Color3.fromRGB(0,134,171),Scale=Color3.fromRGB(172,109,0),Paint=Color3.fromRGB(13,105,172),Delete=Color3.fromRGB(172,0,0),Select=Color3.fromRGB(2,136,0),Place=Color3.fromRGB(207,151,30)}
ui.groupOutline=make('SelectionBox',gui,{Color3=ui.colors.Move,LineThickness=.055,SurfaceTransparency=1})
ui.canvas=make('Frame',gui,{Name='SelectionCanvas',Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Active=false,ZIndex=6})
ui.rectangle=make('ImageLabel',ui.canvas,{Name='DragSelection',Image='rbxassetid://8008696978',ScaleType=Enum.ScaleType.Slice,SliceCenter=Rect.new(1,1,2,2),ImageColor3=Color3.fromRGB(30,151,207),BackgroundColor3=Color3.fromRGB(21,108,145),BackgroundTransparency=.75,Visible=false,ZIndex=7})
function ui.assign(parts)
 table.clear(selection);selected=nil
 for _,part in ipairs(parts)do if exists(part)then selection[part:GetAttribute('TrackPieceId')]=part;selected=part end end
 refresh()
end
function ui.project()
 local camera=workspace.CurrentCamera;local out={}
 if not camera then return out end
 for _,part in pairs(objects)do if exists(part)then
  local loX,loY,hiX,hiY=math.huge,math.huge,-math.huge,-math.huge;local front=false
  for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
   local corner=part.CFrame:PointToWorldSpace(Vector3.new(part.Size.X*x,part.Size.Y*y,part.Size.Z*z)/2)
   local point=camera:WorldToScreenPoint(corner)
   if point.Z>.01 and math.abs(point.X)<1e7 and math.abs(point.Y)<1e7 then
    front=true;loX=math.min(loX,point.X);loY=math.min(loY,point.Y);hiX=math.max(hiX,point.X);hiY=math.max(hiY,point.Y)
   end
  end end end
  if front then table.insert(out,{part=part,x1=loX,y1=loY,x2=hiX,y2=hiY})end
 end end
 return out
end
function ui.boxParts(a,b,projected,base)
 local x1,y1,x2,y2=math.min(a.X,b.X),math.min(a.Y,b.Y),math.max(a.X,b.X),math.max(a.Y,b.Y)
 local out,added={},{}
 for _,part in ipairs(base or{})do if exists(part)then added[part]=true;table.insert(out,part)end end
 for _,r in ipairs(projected or ui.project())do
  if exists(r.part)and not added[r.part]and r.x2>=x1 and r.x1<=x2 and r.y2>=y1 and r.y1<=y2 then added[r.part]=true;table.insert(out,r.part)end
 end
 return out
end
function ui.cancelBox(restore)
 local gesture=ui.boxGesture;if not gesture then return end
 ui.boxGesture=nil;ui.rectangle.Visible=false;unlockCamera('box')
 if restore and gesture.active then ui.assign(gesture.before)end
end
function ui.beginBox(input)
 if ui.boxGesture then return end
 local p=Vector2.new(input.Position.X,input.Position.Y)
 ui.boxGesture={input=input,start=p,point=p,before=selectionParts(),additive=multiSelect or UIS:IsKeyDown(Enum.KeyCode.LeftShift)or UIS:IsKeyDown(Enum.KeyCode.RightShift),active=false,last=-1}
 lockCamera('box')
end
function ui.changeBox(input,force)
 local g=ui.boxGesture;if not g then return end
 if input~=g.input and not(g.input.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseMovement)then return end
 g.point=Vector2.new(input.Position.X,input.Position.Y)
 if not g.active and(g.point-g.start).Magnitude<9 then return end
 if not g.active then g.active=true;g.projected=ui.project()end
 local origin=ui.canvas.AbsolutePosition
 ui.rectangle.Position=UDim2.fromOffset(math.min(g.start.X,g.point.X)-origin.X,math.min(g.start.Y,g.point.Y)-origin.Y)
 ui.rectangle.Size=UDim2.fromOffset(math.abs(g.point.X-g.start.X),math.abs(g.point.Y-g.start.Y));ui.rectangle.Visible=true
 if force or os.clock()-g.last>=.08 then g.last=os.clock();ui.assign(ui.boxParts(g.start,g.point,g.projected,g.additive and g.before or nil))end
end
function ui.endBox(input)
 local g=ui.boxGesture;if not g then return false end
 if g.input.UserInputType==Enum.UserInputType.MouseButton1 and g.active then ui.changeBox({UserInputType=Enum.UserInputType.MouseMovement,Position=g.point},true)else ui.changeBox(input,true)end;local active=g.active
 ui.boxGesture=nil;ui.rectangle.Visible=false;unlockCamera('box')
 if active then blockWorldUntil=os.clock()+.15;tell('Selected '..#selectionParts()..' pieces.')end
 return active
end
function ui.setTrowelMode(name)
 assert(name=='Move'or name=='Rotate'or name=='Clone'or name=='Mirror','Unknown trowel mode')
 ui.trowelMode=name
 if ui.equippedTool==ui.tools.Trowel then setMode(name)end
end
function ui.cycleTrowel()
 local modes={'Move','Rotate','Clone','Mirror'}
 local i=table.find(modes,ui.trowelMode)or 1;ui.setTrowelMode(modes[i%#modes+1])
end
function ui.showMain(page)
 panel.Visible=true;content.Visible=true;minimized=false;panel.Size=UDim2.fromOffset(330,440);minimize.Text='−';setTab(page or'Edit');clampPanel();refresh()
end
function ui.setTool(name)
 ui.cancelBox(true);ui.currentTool=name
 if name~='Paint'and name~='Properties'then panel.Visible=false end
 if ui.materialWindow then ui.materialWindow.Visible=false end
 if name=='Hammer'then setMode('Place');ui.materialWindow.Visible=true;ui.layout();tell('')
 elseif name=='Trowel'then setMode(ui.trowelMode)
 elseif name=='Move'then setMode('Move')
 elseif name=='Scale'then setMode('Scale')
 elseif name=='Rotate'then setMode('Rotate')
 elseif name=='Paint'then setMode('Paint');ui.showMain('Style')
 elseif name=='Delete'then setMode('Delete');tell('')
 elseif name=='Properties'then setMode('Select');ui.showMain('Style')end
 if ui.refresh then ui.refresh()end
end
function ui.setAxes(value)
 assert(type(value)=='boolean','Axes must be true for local or false for world')
 finishDrag();localAxes=value;ui.settings.localAxes=value;refresh()
 tell('')
end
function ui.getAxes()return localAxes and'Local'or'World'end
ui.materialButtons={}
ui.trowelSwitch=make('TextButton',gui,{Name='TrowelMode',Text='MOVE  ›',AnchorPoint=Vector2.new(0,.5),Position=UDim2.new(0,12,.46,0),Size=UDim2.fromOffset(104,38),BackgroundColor3=Color3.fromRGB(35,29,25),TextSize=13,Active=true,Visible=false,ZIndex=10});stroke(ui.trowelSwitch)
connect(ui.trowelSwitch.Activated,safe(ui.cycleTrowel))
ui.switchScale=make('UIScale',ui.trowelSwitch,{Scale=1})
ui.menuButton=make('TextButton',gui,{Name='BuilderMenu',Text='≡',Position=UDim2.new(1,-46,.32,0),Size=UDim2.fromOffset(32,32),BackgroundColor3=Color3.fromRGB(35,29,25),TextSize=23,Active=true,Visible=false,ZIndex=10});stroke(ui.menuButton)
connect(ui.menuButton.Activated,safe(function()if panel.Visible then finishDrag();panel.Visible=false else ui.showMain(tab)end end))
ui.mirrorHandles=make('Handles',gui,{Name='MirrorHandles',Color3=ui.colors.Mirror,Faces=Faces.new(Enum.NormalId.Left,Enum.NormalId.Right,Enum.NormalId.Top,Enum.NormalId.Bottom,Enum.NormalId.Front,Enum.NormalId.Back),Visible=false,Style=Enum.HandlesStyle.Resize})
connect(ui.mirrorHandles.MouseButton1Down,safe(function(face)
 if mode~='Mirror'or not faces[face]then return end
 local ok,err=pcall(beginDrag,faces[face])
 if not ok then finishDrag();error(err,0)end
end))
connect(ui.mirrorHandles.MouseButton1Up,finishDrag)
ui.materialWindow=make('Frame',gui,{Name='MaterialPicker',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(294,322),BackgroundColor3=Color3.fromRGB(35,29,25),Visible=false,Active=true,ZIndex=12});stroke(ui.materialWindow)
ui.materialScale=make('UIScale',ui.materialWindow,{Scale=1})
make('TextLabel',ui.materialWindow,{Text='BLOCKS',Position=UDim2.fromOffset(12,2),Size=UDim2.new(1,-50,0,32),TextXAlignment=Enum.TextXAlignment.Left,BackgroundTransparency=1,TextSize=16,ZIndex=13})
ui.materialClose=make('TextButton',ui.materialWindow,{Text='×',Position=UDim2.new(1,-36,0,0),Size=UDim2.fromOffset(34,34),BackgroundTransparency=1,ZIndex=13})
connect(ui.materialClose.Activated,function()ui.materialWindow.Visible=false end)
ui.materialList=make('ScrollingFrame',ui.materialWindow,{Name='Materials',Position=UDim2.fromOffset(8,38),Size=UDim2.new(1,-16,1,-46),AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(),ScrollBarThickness=3,BackgroundTransparency=1,ZIndex=13})
ui.materials={}
for _,entry in ipairs({{'Concrete','CONCRETE',125,125,125},{'WoodPlanks','WOOD',163,116,65},{'Wood','LOG',140,98,55},{'Brick','BRICK',155,73,54},{'Cobblestone','STONE',120,120,113},{'Slate','SLATE',90,99,109},{'Metal','METAL',155,163,170},{'DiamondPlate','PLATE',140,145,150},{'Asphalt','ASPHALT',42,43,46},{'Grass','GRASS',80,127,50},{'Sand','SAND',209,188,137},{'Ice','ICE',180,220,237},{'Glass','GLASS',190,222,235,.5},{'Plastic','PLASTIC',215,215,215},{'Neon','NEON',170,230,255}})do
 if member(Enum.Material,entry[1])then table.insert(ui.materials,entry)end
end
function ui.chooseMaterial(name)
 local chosen
 for _,entry in ipairs(ui.materials)do if entry[1]==name then chosen=entry;break end end
 assert(chosen,'Choose a listed block material')
 ui.brush={material=name,color=Color3.fromRGB(chosen[3],chosen[4],chosen[5]),transparency=chosen[6]or 0};ui.brushSet=true;shape='Block';ui.currentTool='Hammer'
 ui.materialWindow.Visible=false;setMode('Place');tell('')
end
for i,entry in ipairs(ui.materials)do
 local tile=make('TextButton',ui.materialList,{Name='Material'..entry[1],Text='',Position=UDim2.fromOffset(((i-1)%3)*92,math.floor((i-1)/3)*81),Size=UDim2.fromOffset(87,76),BackgroundColor3=Color3.fromRGB(66,55,44),ZIndex=14});stroke(tile)
 local viewport=make('ViewportFrame',tile,{Name='Preview',Position=UDim2.fromOffset(4,2),Size=UDim2.new(1,-8,1,-20),BackgroundTransparency=1,Ambient=Color3.fromRGB(190,190,190),LightColor=white,LightDirection=Vector3.new(-1,-1,-1),ZIndex=15,Active=false})
 local part=make('Part',viewport,{Name='Cube',Size=Vector3.new(2,2,2),Anchored=true,CanCollide=false,CanTouch=false,Material=Enum.Material[entry[1]],Color=Color3.fromRGB(entry[3],entry[4],entry[5]),Transparency=entry[6]or 0,CFrame=CFrame.new()})
 local camera=make('Camera',viewport,{CFrame=CFrame.lookAt(Vector3.new(3,2,4),Vector3.zero),FieldOfView=38});viewport.CurrentCamera=camera
 make('TextLabel',tile,{Text=entry[2],Position=UDim2.new(0,0,1,-18),Size=UDim2.new(1,0,0,18),BackgroundTransparency=1,TextSize=11,ZIndex=16})
 ui.materialButtons[entry[1]]=tile;connect(tile.Activated,safe(function()ui.chooseMaterial(entry[1])end))
end
function ui.refresh()
 ui.trowelSwitch.Visible=ui.equippedTool~=nil and ui.equippedTool==ui.tools.Trowel
 ui.trowelSwitch.Text=string.upper(ui.trowelMode)..'  ›'
 ui.trowelSwitch.BackgroundColor3=mode=='Mirror'and Color3.fromRGB(100,43,70)or Color3.fromRGB(35,29,25)
 ui.menuButton.Visible=not options.hideShortcut and ui.equippedTool~=nil
 for name,b in pairs(ui.materialButtons)do b.BackgroundColor3=name==ui.brush.material and Color3.fromRGB(143,107,53)or Color3.fromRGB(66,55,44)end
end
function ui.layout()
 local camera=workspace.CurrentCamera;if not camera then return end
 local v=camera.ViewportSize;local inset,bottom=GuiService:GetGuiInset();local height=v.Y-inset.Y-bottom.Y
 ui.switchScale.Scale=math.clamp(height/360,.85,1)
 ui.materialScale.Scale=math.clamp(math.min(1,(v.X-20)/294,(height-20)/322),.6,1)
 ui.materialWindow.Position=UDim2.new(.5,0,.5,0)
end
connect(UIS.InputChanged,safe(function(input)if ui.boxGesture then ui.changeBox(input,false)end end))
connect(Run.Heartbeat,function()local g=ui.boxGesture;if g and g.active then ui.changeBox(g.input.UserInputType==Enum.UserInputType.MouseButton1 and{UserInputType=Enum.UserInputType.MouseMovement,Position=g.point}or g.input,false)end end)

connect(title.InputBegan,function(input)
 if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
  finishDrag();panelDrag={input=input,start=Vector2.new(input.Position.X,input.Position.Y),position=Vector2.new(panel.Position.X.Offset,panel.Position.Y.Offset)}
  lockCamera('panel')
 end
end)
connect(UIS.InputChanged,function(input)
 if panelDrag and (input==panelDrag.input or panelDrag.input.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseMovement)then
  local delta=Vector2.new(input.Position.X,input.Position.Y)-panelDrag.start;panel.Position=UDim2.fromOffset(panelDrag.position.X+delta.X,panelDrag.position.Y+delta.Y);clampPanel()
 end
end)
connect(minimize.Activated,function()finishDrag();panel.Visible=false end)
local function overUI(pos)
 local inset=GuiService:GetGuiInset()
 local ok,list=pcall(function()return pg:GetGuiObjectsAtPosition(pos.X,pos.Y)end)
 if ok then for _,o in ipairs(list)do if o:IsDescendantOf(gui)and o~=ui.canvas and o~=ui.rectangle then return true end end end
 local function inside(frame)
  if not frame or not frame.Visible then return false end
  local p,s=frame.AbsolutePosition,frame.AbsoluteSize
  return pos.X>=p.X and pos.X<=p.X+s.X and pos.Y-inset.Y>=p.Y and pos.Y-inset.Y<=p.Y+s.Y
 end
 return inside(panel)or inside(exportWindow)or inside(ui.trowelSwitch)or inside(ui.menuButton)or inside(ui.materialWindow)
end
local pending={}
connect(UIS.InputBegan,function(input,processed)
 if input.UserInputType==Enum.UserInputType.Touch then
  lastTouch=input;lastTouchAt=os.clock()
  if drag and not drag.input then drag.input=input end
  if overUI(input.Position)then lockCamera(input)end
 end
 if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
  if mode=='Idle'then return end
  if ui.boxGesture then ui.blocked[input]=true;return end
  if not processed and not overUI(input.Position)and not drag and mode~='Place'then ui.beginBox(input)end
  if not processed and not overUI(input.Position)then pending[input]={pos=Vector2.new(input.Position.X,input.Position.Y),at=os.clock()}end
  return
 end
 if mode=='Idle'or processed or UIS:GetFocusedTextBox()then return end
 local ctrl=UIS:IsKeyDown(Enum.KeyCode.LeftControl)or UIS:IsKeyDown(Enum.KeyCode.RightControl)
 local k=input.KeyCode
 if ctrl and k==Enum.KeyCode.A then local parts={};for _,part in pairs(objects)do if exists(part)then table.insert(parts,part)end end;selectMany(parts)
 elseif ctrl and k==Enum.KeyCode.Z then safe(function()historyStep(history,redo,'undo')end)()
 elseif ctrl and k==Enum.KeyCode.Y then safe(function()historyStep(redo,history,'redo')end)()
 elseif ctrl and k==Enum.KeyCode.D then safe(duplicate)()
 elseif ctrl and k==Enum.KeyCode.S then safe(save)()
 elseif k==Enum.KeyCode.Delete then safe(deleteSelected)()
 elseif k==Enum.KeyCode.Escape then finishDrag();selectPart(nil)
 end
end)
local lastGizmo=0
if handles then connect(handles.MouseButton1Down,function()lastGizmo=os.clock()end)end
if arcs then connect(arcs.MouseButton1Down,function()lastGizmo=os.clock()end)end
connect(ui.mirrorHandles.MouseButton1Down,function()lastGizmo=os.clock()end)
connect(UIS.InputEnded,function(input)
 unlockCamera(input)
 if lastTouch==input then lastTouch=nil end
 if panelDrag and (input==panelDrag.input or input.UserInputType==Enum.UserInputType.MouseButton1 and panelDrag.input.UserInputType==Enum.UserInputType.MouseButton1)then panelDrag=nil;unlockCamera('panel')end
 if ui.blocked[input]then ui.blocked[input]=nil;pending[input]=nil;return end
 if ui.boxGesture and ui.boxGesture.input==input then local didSelect=ui.endBox(input);if didSelect then pending[input]=nil;return end end
 local touch=pending[input];pending[input]=nil
 local hadDrag=drag~=nil
 if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch and drag and (not drag.input or drag.input==input)then finishDrag()end
 if mode=='Idle'or not touch or hadDrag or os.clock()<blockWorldUntil or os.clock()-lastGizmo<.15 or os.clock()-touch.at>.8 or overUI(input.Position)then return end
 if (Vector2.new(input.Position.X,input.Position.Y)-touch.pos).Magnitude>10 then return end
 safe(function()
  local camera=workspace.CurrentCamera;if not camera then return end
  local ray=camera:ScreenPointToRay(input.Position.X,input.Position.Y)
  local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude
  local _,c=characterRoot();params.FilterDescendantsInstances=c and {c,gizmo}or {gizmo}
  local hit=workspace:Raycast(ray.Origin,ray.Direction*5000,params)
  if mode=='Place'then
   if hit then
    local size=(shape=='Ramp'or shape=='Corner')and Vector3.new(8,4,12)or shape=='Ball'and Vector3.new(4,4,4)or shape=='Cylinder'and Vector3.new(2,4,4)or(ui.brushSet and Vector3.new(2,2,2)or Vector3.new(8,1,8))
    local p=hit.Position;local n=hit.Normal
    local offset=(math.abs(n.X)*size.X+math.abs(n.Y)*size.Y+math.abs(n.Z)*size.Z)/2
    local at=p+n*offset;at=Vector3.new(snap(at.X,moveStep),snap(at.Y,moveStep),snap(at.Z,moveStep))
    spawnAt(CFrame.new(at));mode='Place';refresh()
   else tell('Tap a solid surface to place a piece.')end
  else local part=hit and objects[hit.Instance:GetAttribute('TrackPieceId')]or nil;if mode=='Delete'then if exists(part)then if not selection[part:GetAttribute('TrackPieceId')]then selectPart(part)end;deleteSelected()end;return end;local additive=multiSelect or UIS:IsKeyDown(Enum.KeyCode.LeftShift)or UIS:IsKeyDown(Enum.KeyCode.RightShift);if part or not additive then selectPart(part,additive)end end
 end)()
end)
local function cancelInteraction()
 if ui.cancelBox then ui.cancelBox(true)end;table.clear(ui.blocked)
 panelDrag=nil;lastTouch=nil;table.clear(pending);finishDrag();unlockAllCamera()
end
connect(UIS.WindowFocusReleased,cancelInteraction)
function ui.deactivate()
 cancelInteraction();ui.equippedTool=nil;mode='Idle';ui.materialWindow.Visible=false;panel.Visible=false
 refresh()
end
ui.toolSpecs={
 {'Hammer','846599039','Build blocks: equip to choose a material'},
 {'Trowel','7957079135','Move / Rotate / Clone / Mirror'},
 {'Scale','2783549943','Resize blocks with handles'},
 {'Paint','1198996683','Change selected block colors and materials'},
 {'Delete','846598820','Delete draft blocks; Undo restores them'},
 {'Properties','5107038616','Edit block settings, circles and saved drafts'}
}
function ui.installTools(backpack)
 if closed or ui.toolsEnabled==false then return end
 backpack=backpack or player:FindFirstChildOfClass('Backpack')
 if not backpack then return end
 for _,item in ipairs(ui.toolSpecs)do
  local name=item[1];local tool=ui.tools[name]
  local usable=tool and pcall(function()if tool.Parent~=player.Character and tool.Parent~=backpack then tool.Parent=backpack end end)
  if not usable then
   for _,c in ipairs(ui.toolListeners[name]or{})do c:Disconnect()end
   tool=make('Tool',nil,{Name=name,RequiresHandle=false,CanBeDropped=false,Enabled=true,ManualActivationOnly=false,TextureId='rbxassetid://'..item[2],ToolTip=item[3]})
   tool:SetAttribute('HeadLockTrackBuilderTool',true);ui.tools[name]=tool
   ui.toolListeners[name]={
    connect(tool.Equipped,safe(function()
     if closed or ui.tools[name]~=tool then return end
     cancelInteraction();ui.equippedTool=tool;ui.setTool(name)
    end)),
    connect(tool.Unequipped,function()if ui.equippedTool==tool then ui.deactivate()end end),
    connect(tool.AncestryChanged,function()
     if ui.equippedTool==tool and tool.Parent~=player.Character then ui.deactivate()end
    end)
   }
   tool.Parent=backpack
  end
 end
end
function ui.equip(name)
 if name=='Move'or name=='Rotate'or name=='Clone'or name=='Mirror'then ui.trowelMode=name;name='Trowel'end
 local tool=assert(ui.tools[name],'Unknown builder tool')
 local character=player.Character;local humanoid=character and character:FindFirstChildOfClass('Humanoid')
 assert(humanoid,'Wait for your character to spawn')
 if tool.Parent==character then ui.equippedTool=tool;ui.setTool(name)else humanoid:EquipTool(tool)end
 return tool
end
connect(player.CharacterRemoving,function()
 ui.deactivate()
 local backpack=player:FindFirstChildOfClass('Backpack')
 for _,tool in pairs(ui.tools)do if backpack then pcall(function()tool.Parent=backpack end)end end
end)
connect(player.CharacterAdded,function()
 ui.deactivate()
 task.defer(function()if not closed then ui.installTools()end end)
end)
connect(player.ChildAdded,function(child)
 if child:IsA('Backpack')then task.defer(function()if not closed then ui.installTools(child)end end)end
end)
ui.toolsEnabled=options.enabled~=false
ui.installTools(player:WaitForChild('Backpack'))
local elapsed=0
connect(Run.Heartbeat,function(dt)
 elapsed+=dt
 if elapsed>=5 then elapsed=0;if changed then pcall(draft)end;clampPanel()end
end)
function api.setEnabled(value)
 value=value==true
 if ui.toolsEnabled==value then return end
 ui.toolsEnabled=value
 if value then ui.installTools();ui.showMain('Edit')
 else
  ui.deactivate()
  if exportWindow then exportWindow:Destroy();exportWindow=nil;exportBox=nil end
  for _,listeners in pairs(ui.toolListeners)do for _,connection in ipairs(listeners)do connection:Disconnect()end end
  for _,tool in pairs(ui.tools)do pcall(function()tool:Destroy()end)end
  table.clear(ui.tools);table.clear(ui.toolListeners)
 end
end
api.openMenu=function()if ui.toolsEnabled then ui.showMain('Edit')end end
api.isEnabled=function()return ui.toolsEnabled==true end
api.isBusy=function()return drag~=nil end
api.sync=sync
function api.cleanup()
 if closed then return end
 cancelInteraction();pcall(draft);closed=true
 Run:UnbindFromRenderStep(cameraBinding)
 for _,c in ipairs(connections)do c:Disconnect()end
 for _,tool in pairs(ui.tools)do pcall(function()tool:Destroy()end)end
 table.clear(ui.tools);ui.equippedTool=nil
 gui:Destroy();gizmo:Destroy();_G.HeadLockTrackBuilderCleanup=nil
 if _G.HeadLockTrackBuilder==api then _G.HeadLockTrackBuilder=nil end
end
api.add=function(kind,cf)assert(kind=='Ramp'or kind=='Corner'or shapes[kind],'Unsupported shape');shape=kind;return spawnAt(cf or frontFrame())end
api.select=selectPart;api.selectMany=selectMany;api.selection=selectionParts;api.bounds=groupBounds;api.duplicate=duplicate;api.delete=deleteSelected;api.scale=scaleGroup;api.rotate=rotateGroup;api.edit=edit;api.undo=function()historyStep(history,redo,'undo')end;api.redo=function()historyStep(redo,history,'redo')end
api.clone=ui.cloneBy;api.mirror=function(face)return ui.mirrorBy(typeof(face)=='Vector3'and face or assert(faces[face],'Choose a mirror face'))end;api.tools=ui.tools;api.equip=ui.equip;api.setAxes=ui.setAxes;api.getAxes=ui.getAxes;api.ui=ui;api.circle=createCircle;api.save=save;api.export=exportText;api.import=import;api.normalize=normalize;api.document=document;api.clear=clear;api.parts=objects;api.gui=gui;api.mode=setMode;api.nudge=nudge
_G.HeadLockTrackBuilder=api;_G.HeadLockTrackBuilderCleanup=api.cleanup
connect(close.Activated,function()finishDrag();panel.Visible=false end)
local restored=false
if count()==0 and type(_G.HeadLockTrackDraft)=='table'then restored=pcall(import,_G.HeadLockTrackDraft)end
mode='Idle';setTab('Build');panel.Visible=false;content.Visible=false;minimized=true;panel.Size=UDim2.fromOffset(330,36);minimize.Text='+';clampPanel();ui.layout();refresh()
tell('')

return api
end)(options)end})
end
SC.installBuilding()
SC.ownerSync=(function(SC,ctx)
local Http=game:GetService('HttpService')
local state={enabled=false,connected=false,owner=false,canBuild=false,temporary=false,closed=false,busy=false,queue={},versions={},docs={},roster={},published={},lastDesired=0,replicas={},nextTick=0,elapsed=0,error='Connecting',buildOwner=ctx.player.UserId}
local send=type(request)=='function'and request or type(http_request)=='function'and http_request or type(syn)=='table'and syn.request or type(http)=='table'and http.request
state.close=function()state.closed=true end
local function report(text)state.error=text;if ctx.update then ctx.update()end end
if type(send)~='function'then report('Shared connection unavailable');return state end
if type(game.JobId)~='string'or #game.JobId<8 then report('Shared needs a live server');return state end
local function guid()return(Http:GenerateGUID(false):gsub('[{}%-]',''))end
state.enabled=true;state.session=guid();local secret=guid();local room=tostring(game.PlaceId)..':'..game.JobId;state.room=room
local access=_G.HeadLockOwnerAccess
if SC.isOwnerAccount(ctx.player)and(type(access)~='table'or type(access.key)~='string')and type(readfile)=='function'then
 local ok,value=pcall(function()return Http:JSONDecode(readfile('HeadLockOwnerAccess_v1.json'))end)
 if ok and type(value)=='table'and type(value.key)=='string'then access=value;_G.HeadLockOwnerAccess=value end
end
local function rpc(op,fields)
 local body={room=room,session=state.session,secret=secret,user=ctx.player.UserId,username=ctx.player.Name,op=op,versions=state.versions,actual={paused=SC.paused==true,soundsPaused=SC.soundsPaused==true},ack=state.lastDesired}
 if op=='join'and SC.isOwnerAccount(ctx.player)and type(access)=='table'then body.ownerKey=access.key end
 for key,value in pairs(fields or{})do body[key]=value end
 local response=send({Url=ctx.endpoint,Method='POST',Headers={['Content-Type']='application/json'},Body=Http:JSONEncode(body),Timeout=6})
 assert(type(response)=='table','Shared connection unavailable')
 local ok,data=pcall(function()return Http:JSONDecode(response.Body)end)
 assert(ok and type(data)=='table','Shared response unavailable')
 assert((response.StatusCode or response.Status)==200 and data.ok,data.error or'Shared connection unavailable')
 return data
end
local shared=Instance.new('Folder');shared.Name='HeadLockSharedBuilds';shared.Parent=workspace
local function fingerprint(p)
 local surface={};for _,name in ipairs({'TopSurface','BottomSurface','LeftSurface','RightSurface','FrontSurface','BackSurface'})do table.insert(surface,p.surfaces and p.surfaces[name]or'Smooth')end
 return Http:JSONEncode({p.class,p.name,p.shape or'Block',p.size,p.cf,p.color,p.material,p.materialVariant or'',p.transparency or 0,p.reflectance or 0,p.canCollide~=false,p.canTouch~=false,p.canQuery~=false,p.castShadow~=false,surface,p.physics or{}})
end
local function sigs(doc)
 local out={};for _,part in ipairs(doc.parts or{})do out[part.id]=fingerprint(part)end;return out
end
local function render(build)
 if build.owner==state.editingOwner and ctx.builderApi()then
  local old=state.replicas[tostring(build.owner)];if old then old.folder:Destroy();state.replicas[tostring(build.owner)]=nil end
  return
 end
 local key=tostring(build.owner);local r=state.replicas[key]
 if not r then local folder=Instance.new('Folder');folder.Name='Build_'..key;folder.Parent=shared;r={folder=folder,parts={},signatures={}};state.replicas[key]=r end
 local seen={}
 for _,d in ipairs(build.doc.parts or{})do
  seen[d.id]=true;local signature=fingerprint(d)
  if r.signatures[d.id]~=signature then
   local part=r.parts[d.id]
   if part and part.ClassName~=d.class then part:Destroy();part=nil end
   if not part then part=Instance.new(d.class);r.parts[d.id]=part end
   local ok=pcall(function()
    part.Name=d.name;part.Anchored=true;part.Size=Vector3.new(table.unpack(d.size));part.CFrame=CFrame.new(table.unpack(d.cf));part.Color=Color3.new(table.unpack(d.color))
    part.Material=Enum.Material[d.material];part.MaterialVariant=d.materialVariant or'';part.Transparency=d.transparency;part.Reflectance=d.reflectance
    part.CanCollide=d.canCollide;part.CanTouch=d.canTouch;part.CanQuery=d.canQuery;part.CastShadow=d.castShadow
    if part:IsA('Part')then part.Shape=Enum.PartType[d.shape or'Block']end
    for surface,value in pairs(d.surfaces or{})do part[surface]=Enum.SurfaceType[value]end
    part.CustomPhysicalProperties=d.physics and PhysicalProperties.new(table.unpack(d.physics))or nil
    part.Parent=r.folder
   end)
   if ok then r.signatures[d.id]=signature else part:Destroy();r.parts[d.id]=nil end
  end
 end
 for id,part in pairs(r.parts)do if not seen[id]then part:Destroy();r.parts[id]=nil;r.signatures[id]=nil end end
end
local function reconcile(doc,reference)
 local api=ctx.builderApi()
 if state.editingOwner==state.buildOwner and api then
  if api.isBusy()then state.deferred={doc=doc,reference=state.deferred and state.deferred.reference or reference};return end
  local current=api.document();local currentSigs=sigs(current);local base=reference.parts;local parts={}
  for _,part in ipairs(doc.parts)do parts[part.id]=part end
  for id in pairs(base)do if not currentSigs[id]then parts[id]=nil end end
  for _,part in ipairs(current.parts)do if currentSigs[part.id]~=base[part.id]then parts[part.id]=part end end
  local merged={format=doc.format,version=doc.version,placeId=doc.placeId,name=current.name~=reference.name and current.name or doc.name,parts={}}
  for _,part in pairs(parts)do table.insert(merged.parts,part)end
  api.sync(merged)
 end
 state.published=sigs(doc);state.publishedName=doc.name;state.deferred=nil
end
function state.attach()
 state.editingOwner=state.buildOwner;state.deferred=nil
 local doc=state.docs[tostring(state.buildOwner)]
 state.published=doc and sigs(doc)or{};state.publishedName=doc and doc.name or nil
 local replica=state.replicas[tostring(state.buildOwner)];if replica then replica.folder:Destroy();state.replicas[tostring(state.buildOwner)]=nil end
end
function state.detach()
 state.editingOwner=nil;state.deferred=nil;state.pendingBuild=false;state.published={};state.publishedName=nil
 for key,doc in pairs(state.docs)do render({owner=tonumber(key),doc=doc})end
end
local function receive(data,sent)
 if state.closed then return end
 local identity=data.self or{};local was=state.buildOwner
 state.connected=true;state.owner=identity.owner==true;state.canBuild=identity.building==true or state.owner;state.temporary=identity.temporary==true
 state.buildOwner=identity.buildOwner or ctx.player.UserId;state.permissionUntil=os.clock()+10
 if SC.setTemporaryAccess then SC.setTemporaryAccess(state.temporary,state.buildOwner)end
 if was~=state.buildOwner then state.deferred=nil end
 state.error=state.owner and'Connected'or(state.temporary and'Temporary access'or(SC.isOwnerAccount(ctx.player)and'Private owner access required'or'Connected'))
 if type(data.roster)=='table'then state.roster=data.roster end
 local reference=sent and{parts=sigs(sent),name=sent.name}or{parts=state.published,name=state.publishedName}
 local publication=data.publication
 if publication then
  state.versions[tostring(state.buildOwner)]=publication.revision
  if publication.doc then
   state.docs[tostring(state.buildOwner)]=publication.doc
   reconcile(publication.doc,publication.conflict and{parts=state.published,name=state.publishedName}or reference)
  elseif sent and not publication.conflict then state.published=sigs(sent);state.publishedName=sent.name end
  if not publication.conflict then state.pendingBuild=false end
 end
 for _,build in ipairs(data.builds or{})do
  if type(build)=='table'and type(build.owner)=='number'and type(build.doc)=='table'and build.doc.placeId==game.PlaceId then
   local key=tostring(build.owner);state.versions[key]=build.revision;state.docs[key]=build.doc
   if build.owner==state.buildOwner and not(publication and publication.doc)then reconcile(build.doc,reference)end
   render(build)
  end
 end
 local desired=data.desired
 if type(desired)=='table'and type(desired.revision)=='number'and desired.revision>state.lastDesired then
  if not SC.isOwnerAccount(ctx.player)then
   if type(desired.paused)=='boolean'then if desired.paused then SC.pauseSession()else SC.unlockSession()end end
   if type(desired.soundsPaused)=='boolean'then SC.setSoundsPaused(desired.soundsPaused)end
   if type(desired.kick)=='string'and state.lastKick~=desired.kick then state.lastKick=desired.kick;ctx.player:Kick('Disconnected by script owner. You can rejoin.')end
  end
  state.lastDesired=desired.revision
 end
 if ctx.update then ctx.update()end
end
function state.enqueue(op,fields,callback)
 if state.closed then return false end
 if not state.connected or not state.owner then report('Private owner access required');if callback then callback(false,state.error)end;return false end
 table.insert(state.queue,{op=op,fields=fields,callback=callback});state.nextTick=0;return true
end
function state.command(target,action)
 if not SC.ownerFeatures or not SC.isOwnerAccount(ctx.player)then return false end
 return state.enqueue('command',{target=target,action=action,requestId=guid()})
end
function state.adopt(doc)
 local key=tostring(state.buildOwner);state.docs[key]=doc;state.published=sigs(doc);state.publishedName=doc.name
end
local function expire()
 if state.temporary and os.clock()>=(state.permissionUntil or 0)then
  state.temporary=false;state.canBuild=false;if SC.setTemporaryAccess then SC.setTemporaryAccess(false,ctx.player.UserId)end
  report('Temporary access needs a connection')
 end
end
function state.tick()
 if state.closed or not state.enabled then return end
 expire()
 local api=ctx.builderApi()
 if state.deferred and api and not api.isBusy()then reconcile(state.deferred.doc,state.deferred.reference)end
 local item=state.connected and table.remove(state.queue,1)or nil
 local op=not state.connected and'join'or item and item.op or'poll';local fields=item and item.fields or{}
 local snapshot
 if op=='poll'and state.canBuild and(ctx.buildingEnabled()or state.pendingBuild)and state.editingOwner==state.buildOwner and api and not api.isBusy()then
  snapshot=api.document();local current=sigs(snapshot);local upsert,removed={},{}
  for _,part in ipairs(snapshot.parts)do if current[part.id]~=state.published[part.id]then table.insert(upsert,part)end end
  for id in pairs(state.published)do if not current[id]then table.insert(removed,id)end end
  if #upsert>0 or #removed>0 or snapshot.name~=state.publishedName then
   op='publish';fields={baseVersion=state.versions[tostring(state.buildOwner)]or 0,buildOwner=state.buildOwner,merge=true,upsert=upsert,removed=removed}
   if snapshot.name~=state.publishedName then fields.name=snapshot.name end
  else snapshot=nil;state.pendingBuild=false end
 end
 local ok,data=pcall(rpc,op,fields)
 if state.closed then return end
 if not ok then
  state.connected=false;report(tostring(data):gsub('^.-:%d+: ',''))
  if item and item.callback then item.callback(false,state.error)end
  return
 end
 receive(data,snapshot)
 if item and item.callback then item.callback(true,data)end
end
function state.close()
 if state.closed then return end
 state.closed=true;state.connected=false;shared:Destroy()
 for _,item in ipairs(state.queue)do if item.callback then pcall(item.callback,false,'Closed')end end;table.clear(state.queue)
 task.spawn(function()pcall(rpc,'leave')end)
end
state.sharedFolder=shared;state.receive=receive
ctx.connect(ctx.Run.Heartbeat,function(dt)
 if state.closed or not SC.authenticated then return end
 expire();state.elapsed+=dt;if state.elapsed<.2 or state.busy or os.clock()<state.nextTick then return end
 state.elapsed=0;state.busy=true;state.nextTick=os.clock()+(ctx.buildingEnabled()and .65 or 1.8)
 task.spawn(function()local ok,err=pcall(state.tick);state.busy=false;if not ok then state.connected=false;report(tostring(err))end;if not state.connected then state.nextTick=os.clock()+3 end end)
end)
return state
end)(SC,{player=player,Run=RS,connect=connect,endpoint='https://headlock-vehicle-sync.vercel.app/control',
 builderApi=function()return SC.building and SC.building.api end,
 buildingEnabled=function()return SC.building and SC.building.enabled end,
 update=function()if SC.building.update then SC.building.update()end;if SC.building.ownerUpdate then SC.building.ownerUpdate()end end})
addCategory('Building',SC.drawBuilding)
addCategory('Owner Panel',SC.drawOwnerPanel)
function SC.refreshOwnerCategories()
 local owner=SC.ownerFeatures and SC.isOwnerAccount(player)
 for _,entry in ipairs(categoryEntries)do
  local visible=entry.name=='Building'and SC.canBuild()or entry.name=='Owner Panel'and owner or(entry.name~='Building'and entry.name~='Owner Panel')
  entry.button.Visible=entry.section==SC.activeGame and visible
 end
 if not SC.canBuild()and SC.setBuilding then SC.setBuilding(false)end
 if(SC.selectedCategory=='Building'and not SC.canBuild())or(SC.selectedCategory=='Owner Panel'and not owner)then SC.selectAimbot()end
end
SC.refreshOwnerCategories()
_G.HeadLockMenuVersion="2026-11-28-shared-building-access"

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
