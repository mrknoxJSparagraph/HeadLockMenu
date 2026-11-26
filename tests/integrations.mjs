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
E.scripts=E.new('Folder','PlayerScripts',E.localPlayer)
E.checks=E.new('LocalScript','Checks',E.scripts)E.checks.Enabled=true
E.backpack=E.new('Backpack','Backpack',E.localPlayer)
E.tool=E.new('Tool','M1911',E.backpack)
E.fireCount=0
E.base={fire=function(self,...)
 assert(self.instance.Parent==E.localPlayer.Character,'shot while not equipped')
 E.fireCount+=1
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
`;
async function run(name,test,extra=''){
 const state=await LuauState.createAsync({print:console.log});
 try{
  const code=mock+'\n'+prelude+'\n'+extra+'\n'+instrumented+`\nassert(_G.HeadLockMenuExecutionReady,table.concat(TestEnv.warnings,' | '))\nassert(__T)\n`+test; await state.loadstring(code,name,true)();
  console.log('PASS '+name);
 }finally{state.destroy();}
}
await run('Defaults, Credits, owner gate, hidden category and cleanup',`
local E,T=TestEnv,__T local SC=T.SC
T.selectGame()
assert(not SC.antiFling.enabled and not SC.antiFling.connection)
assert(E.checks.Enabled==false)
local category=E.find(T.main,'  AutoWin','TextButton')assert(category and not category.Visible)
E.click(T.main,'  Credits')
local checkbox=T.content:FindFirstChild('OwnerFeaturesCheckbox',true)assert(checkbox)
assert(E.find(T.content,'(owner only)','TextLabel'))
for _,node in ipairs(T.content:GetDescendants())do if node:IsA('TextLabel')then
 assert(not node.Text:find('Rapid Fire max',1,true)and not node.Text:find('Anti-fling:',1,true)and not node.Text:find('Additional script',1,true))
end end
checkbox.Activated:Fire()assert(SC.ownerFeatures and category.Visible)
E.click(T.main,'  AutoWin')assert(T.content:FindFirstChild('AutoWinToggle').Text=='OFF')
SC.setOwnerFeatures(false)assert(not category.Visible and SC.selectedCategory=='Credits'and not SC.autoWin.enabled)
E.localPlayer.Name='RegularUser' SC.setOwnerFeatures(true)assert(not SC.ownerFeatures and not category.Visible)
assert(SC.setAutoWin(true)==false)
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
assert(T.autoKillSurvivor(E.owner),'owner survivor unexpectedly excluded from AutoWin local Juggernaut branch')
SC.setAutoWin(false)
assert(not SC.juggernautAutoKill.enabled and not aw.flight and not root.Anchored and E.hum.AutoRotate)
assert(E.base.update_ammo_gui==aw.originalGui or #aw.hooks==0)
_G.HeadLockMenuCleanup()
`);
await run('Player selector supports multiple selections and live membership changes',`
local E,T=TestEnv,__T local SC=T.SC
T.selectGame();SC.setOwnerFeatures(true);E.click(T.main,'  AutoWin')
local list=T.content:FindFirstChild('AutoWinPlayerList')assert(list and not list.Visible)
T.content:FindFirstChild('AutoWinPlayers').Activated:Fire()assert(list.Visible)
list:FindFirstChild('Skip_'..E.owner.UserId).Activated:Fire()
list:FindFirstChild('Skip_'..E.other.UserId).Activated:Fire()
assert(SC.autoWin.skipped[E.owner.UserId]and SC.autoWin.skipped[E.other.UserId])
local newcomer=E.addPlayer('NewPlayer',77,40,300)
game.services.Players.PlayerAdded:Fire(newcomer)
assert(list:FindFirstChild('Skip_77'))
newcomer.Parent=nil;table.remove(E.players,table.find(E.players,newcomer))
game.services.Players.PlayerRemoving:Fire(newcomer)
assert(not list:FindFirstChild('Skip_77'))
E.click(T.main,'  Credits');assert(SC.autoWin.refreshPlayers==nil)
_G.HeadLockMenuCleanup()
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
