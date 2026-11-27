import fs from 'node:fs';
import {LuauState} from 'luau-web';
const mock=fs.readFileSync('tests/fixtures/roblox_mock.luau','utf8');
const source=fs.readFileSync('HeadLockMenu_Core.lua','utf8');
const compiler=await LuauState.createAsync();
try {
 for(const file of ['HeadLockMenu_Core.lua','HeadLockMenu_Shuffled.lua','HeadLockMenu_AutoWin.lua','HeadLockMenu_Vehicles.lua']) {
  compiler.loadstring(fs.readFileSync(file,'utf8'),file,true);
 }
 console.log('PASS full core, launcher and installers compile as Luau');
} finally {compiler.destroy();}
const instrumented=source.replace('SC.watchOwnerEmotes()\n\nend\nlocal __ok',`__T={SC=SC,main=main,content=content,gui=gui,selectGame=selectGame,interval=rapidFireInterval,
setJug=function(p)juggernautPlayer=p end,autoKillSurvivor=autoKillSurvivor}
SC.watchOwnerEmotes()\n\nend\nlocal __ok`);
const prelude=`
PhysicalProperties={new=function(...)return {...}end}
for _,name in ipairs({'HttpService'})do game.services[name]=TestEnv.new('Service',name)end
game.services.HttpService.JSONEncode=function(_,value)return value end
game.services.HttpService.JSONDecode=function(_,value)return value end
local E=TestEnv
E.localPlayer.Name='nonobearbear1'
E.owner.Name='RegularOpponent'
E.scripts=E.new('Folder','PlayerScripts',E.localPlayer)
E.checks=E.new('LocalScript','Checks',E.scripts)E.checks.Enabled=true
E.backpack=E.new('Backpack','Backpack',E.localPlayer)
E.tool=E.new('Tool','M1911',E.backpack)
local handle=E.new('Part','Handle',E.tool)
E.fireSound=E.new('Sound','Fire',handle);E.fireSound.Played=E.signal()
E.fireCount=0;E.inputs=0;E.releases=0
E.fireContext=function()E.contextCalls=(E.contextCalls or 0)+1 end
E.base={fire=function(self,...)
 assert(self.instance.Parent==E.localPlayer.Character,'shot while not equipped')
 local context=...;context()
 assert(context==E.fireContext,'missing original firing context')
 if E.fireCount==0 then assert(self.shoot_wait==.2,'initial trigger skipped normal weapon setup')end
 E.fireCount+=1
 E.fireSound.Played:Fire()
 self.ammo-=1
 self:fire_wait()
 self:recoil_camera()
 E.lastSpread=self:compute_inaccuracy()
end,
update_ammo_gui=function()end,
play_animation=function()end,
recoil_camera=function()E.recoils=(E.recoils or 0)+1 end,
compute_inaccuracy=function()return 5 end}
E.definition=E.new('ModuleScript','Weapon',E.storage)E.definition.Return=E.base
E.new('ModuleScript','M1911',E.definition).Return=setmetatable({},{__index=E.base})
E.object=setmetatable({instance=E.tool,ammo=8,stolen=false,shoot_wait=.2,playing_animations={},
fire_wait=function()task.wait(.2)end,refill=function(self)self.ammo=8 end},{__index=E.base})
E.hum=E.localPlayer.Character:FindFirstChildOfClass('Humanoid')
E.hum.EquipTool=function(self,tool)tool.Parent=E.localPlayer.Character; E.object:update_ammo_gui()end
E.hum.UnequipTools=function(self)E.tool.Parent=E.backpack end
typeof=function(v)if type(v)=='table'and v._props then return 'Instance'else return type(v)end end
-- Add signals not needed by older menu tests.
local uis=game.services.UserInputService
uis.WindowFocusReleased=E.signal();uis.JumpRequest=E.signal()
uis.GetFocusedTextBox=function()return nil end
uis.CreateVirtualInput=function()
 return {SendMouseButton=function(self,point,button,down)
  if down then E.inputs+=1;E.object:fire(E.fireContext)else E.releases+=1 end
 end}
end
`;
async function run(name,test,extra=''){
 const state=await LuauState.createAsync({print:console.log});
 try{
  const code=mock+'\n'+prelude+'\n'+extra+'\n'+instrumented+`\nassert(_G.HeadLockMenuExecutionReady,table.concat(TestEnv.warnings,' | '))\nassert(__T)\n`+test; await state.loadstring(code,name,true)();
  console.log('PASS '+name);
 }finally{state.destroy();}
}
await run('Defaults, Credits and public AutoWin access without the owner checkbox',`
local E,T=TestEnv,__T local SC=T.SC
T.selectGame()
assert(not SC.antiFling.enabled and not SC.antiFling.connection)
assert(E.checks.Enabled==false)
local category=E.find(T.main,'  AutoWin','TextButton')assert(category and category.Visible)
E.click(T.main,'  Credits')
local checkbox=T.content:FindFirstChild('OwnerFeaturesCheckbox',true)assert(checkbox)
assert(E.find(T.content,'(owner only)','TextLabel'))
for _,node in ipairs(T.content:GetDescendants())do if node:IsA('TextLabel')then
 assert(not node.Text:find('Rapid Fire max',1,true)and not node.Text:find('Anti-fling:',1,true)and not node.Text:find('Additional script',1,true))
end end
checkbox.Activated:Fire()assert(SC.ownerFeatures and category.Visible)
E.click(T.main,'  AutoWin')assert(T.content:FindFirstChild('AutoWinToggle',true).Text=='OFF')
SC.setOwnerFeatures(false)assert(category.Visible and SC.selectedCategory=='AutoWin'and not SC.autoWin.enabled)
E.localPlayer.Name='RegularUser' SC.setOwnerFeatures(true)assert(not SC.ownerFeatures and category.Visible)
assert(SC.setAutoWin(true)and E.fireCount>0,'regular account cannot start AutoWin')
SC.setOwnerFeatures(false);assert(SC.autoWin.enabled,'Credits checkbox still controls public AutoWin')
SC.stepAutoWin(true);assert(SC.autoWin.enabled and SC.autoWinCombat())
assert(math.abs(T.interval(E.object,true)-.003)<.0001,'public AutoWin lost rapid firing')
_G.HeadLockMenuCleanup()assert(E.checks.Enabled and not SC.antiFling.enabled and T.gui.Parent==nil)
assert(game.services.RunService.Steps.HeadLockMenuAutoWinFollow==nil)
`);
await run('Automatic equip, rapid shots, skipped Juggernaut, next round, local Juggernaut and restoration',`
local E,T=TestEnv,__T local SC=T.SC local aw=SC.autoWin
SC.setOwnerFeatures(true)
local root=E.localPlayer.Character:FindFirstChild('HumanoidRootPart')
assert(SC.setAutoWin(true))
assert(E.tool.Parent==E.localPlayer.Character and aw.objects[E.tool]==E.object)
assert(aw.role=='survivor'and aw.target==E.owner and root.Anchored)
assert(E.fireCount>=1 and E.lastSpread==0 and not E.recoils)
assert(SC.rapidFireEnabled==false and SC.rapidFirePower==100 and SC.infiniteAmmoEnabled==false)
assert(not SC.cFlyEnabled and not SC.cFlyFollowJug)
assert(E.localPlayer.Character.LastPivot==E.owner.Character:FindFirstChild('HumanoidRootPart').CFrame,'AutoWin differs from Follow Jug positioning')
assert(math.abs(T.interval(E.object,true)-.003)<.0001)
local count=E.fireCount
E.time+=.02;SC.stepAutoWin(false);assert(E.fireCount>count and E.object.ammo==8)
aw.skipped[E.owner.UserId]=true;SC.stepAutoWin(true)
assert(aw.target==nil and not root.Anchored and aw.status:find('Skipping',1,true))
count=E.fireCount;E.time+=1;SC.stepAutoWin(false);assert(E.fireCount==count)
-- Next Juggernaut is not in the skip list.
E.owner.Character.Parent=E.survivors;E.other.Character.Parent=E.killers
SC.stepAutoWin(true);assert(aw.target==E.other and E.fireCount>count)
-- Becoming Juggernaut stops flight and invokes existing Auto Kill.
E.other.Character.Parent=E.survivors;E.localPlayer.Character.Parent=E.killers
aw.skipped[E.other.UserId]=true
SC.stepAutoWin(true)
assert(aw.role=='juggernaut'and aw.ownsKill and SC.juggernautAutoKill.enabled and not root.Anchored)
assert(T.autoKillSurvivor(E.other))
assert(T.autoKillSurvivor(E.owner),'regular survivor unexpectedly excluded from AutoWin local Juggernaut branch')
SC.setAutoWin(false)
assert(not SC.juggernautAutoKill.enabled and not aw.flight and not root.Anchored and E.hum.AutoRotate)
assert(E.base.update_ammo_gui==aw.originalGui or #aw.hooks==0)
_G.HeadLockMenuCleanup()
`);
await run('Regular accounts see AutoWin at the bottom and can use it without Credits',`
local E,T=TestEnv,__T local SC=T.SC
T.selectGame()
local category=assert(E.find(T.main,'  AutoWin','TextButton'))
local vehicles=assert(E.find(T.main,'  Vehicles','TextButton'))
assert(category.Visible and category.LayoutOrder==vehicles.LayoutOrder+1)
assert(not SC.ownerFeatures and not SC.isOwnerAccount(E.localPlayer))
E.click(T.main,'  AutoWin')
T.content:FindFirstChild('AutoWinToggle',true).Activated:Fire()
assert(SC.autoWin.enabled and E.fireCount>=1)
_G.HeadLockMenuCleanup()
`, `TestEnv.localPlayer.Name='RegularUser'`);
await run('Owner Juggernauts are skipped without shooting or following',`
local E,T=TestEnv,__T local SC=T.SC
SC.setAutoWin(true)
assert(SC.autoWin.enabled and E.fireCount==0 and E.inputs==0)
assert(SC.autoWin.target==nil and not SC.autoWinCombat())
assert(SC.autoWin.status:find('Skipping owner',1,true))
assert(not E.localPlayer.Character:FindFirstChild('HumanoidRootPart').Anchored)
E.owner.Name='RegularOpponent';SC.stepAutoWin(true)
assert(E.fireCount>=1 and SC.autoWin.target==E.owner)
E.owner.Name='nonobearbear17';SC.stepAutoWin(true)
local count=E.fireCount
E.time+=1;SC.stepAutoWin(false)
assert(E.fireCount==count and SC.autoWin.target==nil and not SC.autoWinCombat())
assert(not E.localPlayer.Character:FindFirstChild('HumanoidRootPart').Anchored)
_G.HeadLockMenuCleanup()
`, `TestEnv.localPlayer.Name='RegularUser';TestEnv.owner.Name='nonobearbear17'`);
await run('Owner survivors are immune to Auto Kill selection including Kill First priorities',`
local E,T=TestEnv,__T local SC=T.SC
E.owner.Character.Parent=E.survivors;E.localPlayer.Character.Parent=E.killers
SC.autoWin.killFirst[E.owner.UserId]=true
SC.setAutoWin(true)
assert(SC.autoWin.role=='juggernaut' and SC.juggernautAutoKill.enabled)
assert(not T.autoKillSurvivor(E.owner),'priority list allowed targeting an owner survivor')
local step=game.services.RunService.Steps.HeadLockMenuJuggernautAutoKill
step();assert(SC.juggernautAutoKill.target and SC.juggernautAutoKill.target~=E.owner)
E.other.Name='bluddyblud17';E.other2.Name='nonobearbear100'
step();assert(not SC.juggernautAutoKill.target and not SC.juggernautAutoKill.enabled)
-- The same exclusions apply when the local user is also an owner.
E.localPlayer.Name='nonobearbear1'
assert(not T.autoKillSurvivor(E.owner) and not T.autoKillSurvivor(E.other))
_G.HeadLockMenuCleanup()
`, `TestEnv.localPlayer.Name='RegularUser';TestEnv.owner.Name='nonobearbear17'`);
await run('Queued shots recheck owner immunity before firing',`
local E,T=TestEnv,__T local SC=T.SC
SC.setAutoWin(true)
local queued={}
task.spawn=function(fn,...)table.insert(queued,{fn=fn,args=table.pack(...)})end
local count=E.fireCount
E.time+=.03;SC.stepAutoWin(false)
assert(SC.autoWin.firing and #queued>0)
E.owner.Name='nonobearbear17'
while #queued>0 do local item=table.remove(queued,1);item.fn(table.unpack(item.args,1,item.args.n))end
assert(E.fireCount==count and not SC.autoWinCombat())
SC.stepAutoWin(true);assert(SC.autoWin.target==nil)
_G.HeadLockMenuCleanup()
`, `TestEnv.localPlayer.Name='RegularUser'`);
await run('Player selector supports multiple selections and live membership changes',`
local E,T=TestEnv,__T local SC=T.SC
T.selectGame();SC.setOwnerFeatures(true);E.click(T.main,'  AutoWin')
local list=T.content:FindFirstChild('AutoWinPlayerList',true)assert(list and not list.Visible)
T.content:FindFirstChild('AutoWinPlayers',true).Activated:Fire()assert(list.Visible)
list:FindFirstChild('Skip_'..E.owner.UserId).Activated:Fire()
list:FindFirstChild('Skip_'..E.other.UserId).Activated:Fire()
assert(SC.autoWin.skipped[E.owner.UserId]and SC.autoWin.skipped[E.other.UserId])
local first=T.content:FindFirstChild('AutoWinKillFirstList',true)
assert(first and not first.Visible)
T.content:FindFirstChild('AutoWinKillFirstPlayers',true).Activated:Fire()assert(first.Visible)
first:FindFirstChild('KillFirst_'..E.owner.UserId).Activated:Fire()
first:FindFirstChild('KillFirst_'..E.other2.UserId).Activated:Fire()
assert(SC.autoWin.killFirst[E.owner.UserId]and SC.autoWin.killFirst[E.other2.UserId])
assert(SC.autoWin.skipped[E.other.UserId]and not SC.autoWin.killFirst[E.other.UserId],'the two lists share selection state')
local scroll=T.content:FindFirstChild('AutoWinSettings')assert(scroll.CanvasSize.Y.Offset>500)
local newcomer=E.addPlayer('NewPlayer',77,40,300)
game.services.Players.PlayerAdded:Fire(newcomer)
assert(list:FindFirstChild('Skip_77'))
assert(first:FindFirstChild('KillFirst_77'))
newcomer.Parent=nil;table.remove(E.players,table.find(E.players,newcomer))
game.services.Players.PlayerRemoving:Fire(newcomer)
assert(not list:FindFirstChild('Skip_77'))
assert(not first:FindFirstChild('KillFirst_77'))
E.click(T.main,'  Credits');assert(SC.autoWin.refreshPlayers==nil)
_G.HeadLockMenuCleanup()
`);
await run('Cold cached mobile controller starts shooting without a manual bullet',`
local E,T=TestEnv,__T local SC=T.SC
SC.setOwnerFeatures(true)
assert(E.fireCount==0)
SC.setAutoWin(true)
assert(E.fireCount>=1,'cold pistol still needs a manual first shot')
assert(E.callbackCalls==1,'normal mobile trigger was skipped or duplicated')
assert(SC.autoWin.arguments[E.tool][1]==E.fireContext)
assert(SC.autoWin.objects[E.tool]==E.object)
_G.HeadLockMenuCleanup()
`, `
local E=TestEnv
E.hum.EquipTool=function(self,tool)tool.Parent=E.localPlayer.Character end
game.services.UserInputService.CreateVirtualInput=function()return nil end
local pg=E.localPlayer:FindFirstChildOfClass('PlayerGui')
local mouse=E.new('ScreenGui','Mouse',pg)
local frame=E.new('Frame','Mobile Frame',mouse)
E.fireButton=E.new('ImageButton','Mobile Fire',frame)
E.fireButton.MouseButton1Down=E.signal()
E.callbackCalls=0
local callback=function()E.callbackCalls+=1;E.object:fire(E.fireContext)end
getconnections=function(signal)
 if signal==E.fireButton.MouseButton1Down then return {{Function=callback}}end
 return {}
end
debug=table.clone(debug)
debug.getupvalues=function(fn)
 if fn==callback then return {{state={equipped=E.object}}}end
 return {}
end
getgc=nil
`);
await run('Cold GC controller is prepared before the next Juggernaut spawns',`
local E,T=TestEnv,__T local SC=T.SC
SC.setOwnerFeatures(true)
E.owner.Character.Parent=E.survivors
SC.setAutoWin(true)
assert(E.fireCount==0 and SC.autoWin.objects[E.tool]==E.object,'pistol was not prepared while waiting')
E.owner.Character.Parent=E.killers
SC.stepAutoWin(true)
assert(E.fireCount>=1,'spawn did not start firing immediately')
_G.HeadLockMenuCleanup()
`, `
TestEnv.hum.EquipTool=function(self,tool)tool.Parent=TestEnv.localPlayer.Character end
getgc=function()return {TestEnv.object}end
`);
await run('Function-only GC results can expose a cached pistol controller',`
local E,T=TestEnv,__T local SC=T.SC
SC.setOwnerFeatures(true);SC.setAutoWin(true)
assert(E.fireCount>=1 and SC.autoWin.objects[E.tool]==E.object)
_G.HeadLockMenuCleanup()
`, `
local E=TestEnv
E.hum.EquipTool=function(self,tool)tool.Parent=E.localPlayer.Character end
local cached=function()return E.object end
getgc=function()return {cached}end
debug=table.clone(debug)
debug.getupvalues=function(fn)if fn==cached then return {E.object}end return {}end
`);
await run('Discovered cold object uses a normal trigger and preserves its firing callback for replay',`
local E,T=TestEnv,__T local SC=T.SC
SC.setOwnerFeatures(true);SC.setAutoWin(true)
assert(E.inputs==1 and E.releases==1 and E.fireCount>=1)
assert(SC.autoWin.arguments[E.tool][1]==E.fireContext)
assert(SC.autoWin.ready[E.tool].object==E.object)
local count=E.fireCount
for i=1,5 do E.time+=.03;SC.stepAutoWin(false)end
assert(E.fireCount>count and E.inputs==1,'replayed first input instead of captured firing context')
assert(SC.autoWin.arguments[E.tool][1]==E.fireContext,'replay erased required callback')
SC.setAutoWin(false)
count=E.fireCount;E.time+=1;SC.stepAutoWin(false);assert(E.fireCount==count)
_G.HeadLockMenuCleanup()
`, `getgc=function()return {TestEnv.object}end`);
await run('No-op automatic input is reported without treating controller discovery as a shot',`
local E,T=TestEnv,__T local SC=T.SC
SC.setOwnerFeatures(true);SC.setAutoWin(true)
assert(E.inputs==1 and E.releases==1 and E.fireCount==0)
assert(SC.autoWin.ready[E.tool]==nil and SC.autoWin.arguments[E.tool]==nil)
assert(SC.autoWin.status=='Automatic trigger unavailable. No first shot detected.')
assert(SC.autoWin.primer==nil)
_G.HeadLockMenuCleanup()
`, `
local E=TestEnv
getgc=function()return {E.object}end
game.services.UserInputService.CreateVirtualInput=function()
 return {SendMouseButton=function(self,point,button,down)
  if down then E.inputs+=1 else E.releases+=1 end
 end}
end
`);
await run('Failed first input falls back to the mobile icon with the actual toggle input',`
local E,T=TestEnv,__T local SC=T.SC
T.selectGame();SC.setOwnerFeatures(true);E.click(T.main,'  AutoWin')
T.content:FindFirstChild('AutoWinToggle',true).Activated:Fire(E.touch)
assert(E.inputs==1 and E.releases==1 and E.iconCalls==1 and E.fireCount>=1)
assert(SC.autoWin.arguments[E.tool][1]==E.fireContext)
assert(SC.autoWin.primer==nil and SC.autoWin.busy[E.object]==0)
_G.HeadLockMenuCleanup()
`, `
local E=TestEnv
E.touch={UserInputType=Enum.UserInputType.Touch}
getgc=function()return {E.object}end
game.services.UserInputService.CreateVirtualInput=function()
 return {SendMouseButton=function(self,point,button,down)
  if down then E.inputs+=1;E.object:fire()else E.releases+=1 end
 end}
end
local pg=E.localPlayer:FindFirstChildOfClass('PlayerGui')
local frame=E.new('Frame','Mobile Frame',E.new('ScreenGui','Mouse',pg))
local button=E.new('ImageButton','Mobile Fire',frame)
for _,name in ipairs({'MouseButton1Down','MouseButton1Up','MouseButton1Click'})do button[name]=E.signal()end
local icon=E.new('ImageLabel','Icon',button)
E.iconCalls=0
getconnections=function(signal)
 if signal==icon.InputBegan then return {{Function=function(input)
  assert(input==E.touch and __T.SC.autoWin.arguments[E.tool]==nil)
  E.iconCalls+=1;E.object:fire(E.fireContext)
 end}}end
 return {}
end
`);
await run('Stale context recovery',`
local E,T=TestEnv,__T local SC=T.SC
SC.setOwnerFeatures(true);SC.setAutoWin(true)
E.expired=true;E.time+=.03;SC.stepAutoWin(false)
assert(SC.autoWin.ready[E.tool]==nil and SC.autoWin.arguments[E.tool]==nil,'stale context was retained: '..SC.autoWin.status)
assert(SC.autoWin.replaying[E.object]==nil and SC.autoWin.busy[E.object]==0,'replay did not release busy flag')
assert(SC.autoWin.status:find('expired context',1,true),'unexpected replay error: '..SC.autoWin.status)
E.fireContext=function()end
E.time+=.03;SC.stepAutoWin(false)
assert(E.inputs==2 and SC.autoWin.ready[E.tool],'failed to recover: '..SC.autoWin.status..' inputs='..E.inputs)
assert(SC.autoWin.arguments[E.tool][1]==E.fireContext,'fresh callback not cached')
_G.HeadLockMenuCleanup()
`, `TestEnv.fireContext=function()assert(not TestEnv.expired,'expired context')end`);
await run('OFF during a held first trigger releases input and cancels firing and flight',`
local E,T=TestEnv,__T local SC=T.SC
SC.setOwnerFeatures(true);SC.setAutoWin(true)
assert(not SC.autoWin.enabled and SC.autoWin.primer==nil)
assert(E.inputs==1 and E.releases==1 and not E.down and E.fireCount==0)
assert(not E.localPlayer.Character:FindFirstChild('HumanoidRootPart').Anchored)
assert(E.hum.AutoRotate)
_G.HeadLockMenuCleanup()
`, `
local E=TestEnv
game.services.UserInputService.CreateVirtualInput=function()
 return {SendMouseButton=function(self,point,button,down)
  E.down=down
  if down then E.inputs+=1;__T.SC.setAutoWin(false)else E.releases+=1 end
 end}
end
`);
await run('Respawned pistol does not inherit old discovery or equip delays',`
local E,T=TestEnv,__T local SC=T.SC
SC.setOwnerFeatures(true);SC.setAutoWin(true)
local count=E.fireCount;local oldTool=E.tool;local oldObject=E.object
E.localPlayer.CharacterRemoving:Fire(E.localPlayer.Character)
local temporary=E.addPlayer('RespawnFixture',91,0,300)
local c=temporary.Character
table.remove(E.players,table.find(E.players,temporary));temporary.Parent=nil;temporary.Character=nil
E.localPlayer.Character=c
E.tool=E.new('Tool','M1911',E.backpack)
E.object=table.clone(oldObject);E.object.instance=E.tool;E.object.ammo=8
E.hum=c:FindFirstChildOfClass('Humanoid')
E.hum.EquipTool=function(self,tool)tool.Parent=c end
E.hum.UnequipTools=function(self)E.tool.Parent=E.backpack end
getgc=function()return {oldObject,E.object}end
SC.autoWin.nextEquip=E.time+2;SC.autoWin.nextObjectScan=E.time+2
E.localPlayer.CharacterAdded:Fire(c)
assert(E.fireCount>count and E.tool.Parent==c,'respawn waited on an old cooldown')
assert(SC.autoWin.objects[E.tool]==E.object and E.tool~=oldTool)
_G.HeadLockMenuCleanup()
`);
await run('Juggernaut finishes shuffled selected players before the rest',`
local E,T=TestEnv,__T local SC=T.SC local aw=SC.autoWin
E.owner.Character.Parent=E.survivors;E.localPlayer.Character.Parent=E.killers
for i=5,11 do E.addPlayer('Survivor'..i,i,1,300)end
aw.killFirst[E.owner.UserId]=true;aw.killFirst[E.other.UserId]=true;aw.killFirst[E.other2.UserId]=true
-- The survivor skip list does not exempt targets when I am Juggernaut.
aw.skipped[E.owner.UserId]=true
math=table.clone(math)
local oldRandom=math.random;local shuffleCalls={}
math.random=function(n)table.insert(shuffleCalls,n)return 1 end
SC.setOwnerFeatures(true);SC.setAutoWin(true)
local step=game.services.RunService.Steps.HeadLockMenuJuggernautAutoKill
local killed={}
for i=1,3 do
 step()
 local p=assert(SC.juggernautAutoKill.target)
 assert(aw.killFirst[p.UserId]and not killed[p],'non-priority or repeated target before priorities finished')
 local queue=aw.priorityQueue;step();assert(SC.juggernautAutoKill.target==p and aw.priorityQueue==queue,'reshuffled during a live target')
 killed[p]=true;p.Character:FindFirstChildOfClass('Humanoid').Health=0
end
assert(#shuffleCalls==2 and shuffleCalls[1]==3 and shuffleCalls[2]==2,'not a shuffled queue')
math.random=oldRandom
for i=1,7 do
 step()
 local p=assert(SC.juggernautAutoKill.target)
 assert(not aw.killFirst[p.UserId]and not killed[p])
 killed[p]=true;p.Character:FindFirstChildOfClass('Humanoid').Health=0
end
step();assert(not SC.juggernautAutoKill.enabled)
SC.setAutoWin(false);_G.HeadLockMenuCleanup()
`);
await run('Delayed initialization survives respawn and skipped players cancel queued shots',`
local E,T=TestEnv,__T local SC=T.SC
SC.setOwnerFeatures(true)
local queued={}
task.spawn=function(callback,...)table.insert(queued,{callback=callback,args=table.pack(...)})end
assert(SC.setAutoWin(true)and not SC.autoWin.initialized)
-- Character changes may increment the round generation during require/equip.
E.localPlayer.CharacterRemoving:Fire(E.localPlayer.Character)
while #queued>0 do local item=table.remove(queued,1)item.callback(table.unpack(item.args,1,item.args.n))end
assert(SC.autoWin.initialized and E.fireCount>=1)
E.time+=1;local count=E.fireCount
SC.stepAutoWin(false)assert(SC.autoWin.firing)
SC.autoWin.skipped[E.owner.UserId]=true;SC.stepAutoWin(true)
while #queued>0 do local item=table.remove(queued,1)item.callback(table.unpack(item.args,1,item.args.n))end
assert(E.fireCount==count and not SC.autoWin.firing)
SC.setAutoWin(false)
assert(SC.setAutoWin(true));SC.setAutoWin(false)
while #queued>0 do local item=table.remove(queued,1)item.callback(table.unpack(item.args,1,item.args.n))end
assert(not SC.autoWin.enabled and #SC.autoWin.hooks==0)
_G.HeadLockMenuCleanup()
`);
await run('Vehicles lazy startup, matching font, repeated category navigation and input cleanup',`
local E,T=TestEnv,__T local SC=T.SC
T.selectGame();assert(SC.vehicles==nil)
E.click(T.main,'  Vehicles')assert(SC.vehicles,table.concat(E.warnings,' | '))
assert(E.find(T.content,'Spawn Car')and E.find(T.content,'Spawn Motorcycle'))
assert(E.find(T.content,'Delete All')and E.find(T.content,'Controls: ON'))
local controls=E.localPlayer:FindFirstChild('PlayerGui'):FindFirstChild('VehicleGarageUI')
assert(controls and controls:FindFirstChild('Gas').Position.X.Scale==.87)
for _,n in ipairs(T.content:GetDescendants())do if n:IsA('TextLabel')or n:IsA('TextButton')or n:IsA('TextBox')then assert(n.Font==Enum.Font.Code)end end
E.click(T.content,'Controls: ON');assert(not controls:FindFirstChild('Gas').Visible)
E.click(T.content,'Controls: OFF');assert(controls:FindFirstChild('Gas').Visible)
local box=T.content:FindFirstChild('SpeedValue',true)box.Text='135';box.FocusLost:Fire();assert(SC.vehicles.settings.Speed==135)
E.click(T.main,'  Credits');E.click(T.main,'  Vehicles')
assert(T.content:FindFirstChild('SpeedValue',true).Text=='135')
SC.pauseSession();assert(not controls:FindFirstChild('Gas').Visible)
SC.unlockSession();assert(controls:FindFirstChild('Gas').Visible)
_G.HeadLockMenuCleanup();assert(controls.Parent==nil)
assert(game.services.RunService.Steps['VehicleGarageCamera_1']==nil)
`);
