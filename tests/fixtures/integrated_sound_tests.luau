local T,E=__T,TestEnv local SC=T.SC
local function click(name)local button=assert(T.content:FindFirstChild(name,true),name)button.Activated:Fire()return button end
local function tick(dt)E.time+=dt game.services.RunService.Heartbeat:Fire(dt)end
T.selectGame()E.click(T.main,"  Sounds")
assert(#SC.sounds.rows==7)
for index,row in ipairs(SC.sounds.rows)do
 assert(T.content:FindFirstChild("SoundPlay_"..index,true))
 assert(T.content:FindFirstChild("SoundAuto_"..index,true))
 assert(T.content:FindFirstChild("SoundInterval_"..index,true):IsA("TextLabel"))
 assert(T.content:FindFirstChild("SoundSlider_"..index,true))
 assert(row.interval==1)
end
local source=E.soundSources.SurvivorsWin
for i=1,3 do click("SoundPlay_1")end
assert(source.PlayCount==3 and #SC.sounds.rows[1].clones==3,"Rapid clicks should play every time")
for _,clone in ipairs(SC.sounds.rows[1].clones)do assert(clone.Parent==source.Parent and clone.IsPlaying)end
local mute=click("SoundMuteMine")
assert(SC.sounds.muteMine and mute.Text=="Mute my sounds: ON")
click("SoundPlay_1")assert(source.PlayCount==4 and source.Volume==0 and SC.sounds.rows[1].clones[#SC.sounds.rows[1].clones].Volume==0)
click("SoundMuteMine")assert(not SC.sounds.muteMine and source.Volume==1)
for _,clone in ipairs(SC.sounds.rows[1].clones)do assert(clone.Volume==1)end
click("SoundAuto_1")assert(source.PlayCount==5)
tick(.9)assert(source.PlayCount==5)
tick(.1)assert(source.PlayCount==6)
local row=SC.sounds.rows[1]
assert(SC.setMenuSoundInterval(row,.14)and row.interval==.1)
assert(SC.setMenuSoundInterval(row,8)and row.interval==5)
local slider=T.content:FindFirstChild("SoundSlider_1",true)
local hit=slider:FindFirstChildOfClass("Frame")
hit.InputBegan:Fire({UserInputType=Enum.UserInputType.Touch,Position=Vector2.new(300,0)})
assert(row.interval==5)
hit.InputBegan:Fire({UserInputType=Enum.UserInputType.Touch,Position=Vector2.new(0,0)})
assert(row.interval==.1)
SC.setMenuSoundInterval(row,.1)
assert(T.content:FindFirstChild("SoundInterval_1",true).Text=="0.1s")
tick(.1)assert(source.PlayCount==7)
for i=1,40 do click("SoundPlay_1")end
assert(source.PlayCount==47 and #row.clones==32,"Every click plays; local overlap stays bounded")
click("SoundAuto_2")assert(E.soundSources.KillerWin.PlayCount==1)
tick(.1)assert(source.PlayCount==48 and E.soundSources.KillerWin.PlayCount==1)
E.click(T.main,"  Credits")tick(.1)assert(source.PlayCount==49,"Loop continues outside panel")
E.click(T.main,"  Sounds")click("SoundAuto_1")
tick(1)assert(source.PlayCount==49,"Disabling loop stops repeats")
local otherDied=E.new("Sound","Died",E.other.Character:FindFirstChild("HumanoidRootPart"))
click("SoundPlay_5")assert(E.soundSources.Died.PlayCount==1 and otherDied.PlayCount==1,"Oof should play for each player")
SC.pauseSession()assert(not SC.sounds.rows[2].enabled and #row.clones==0)
SC.unlockSession()E.click(T.main,"  Sounds")
for _,index in ipairs({3,4,6,7})do click("SoundPlay_"..index)end
assert(E.soundSources.Death.PlayCount==1 and E.soundSources.RageModeRoar.PlayCount==1)
assert(E.soundSources.Blackout.PlayCount==1 and E.soundSources.LockDoorRoar.PlayCount==1)
_G.HeadLockMenuCleanup()
assert(SC.sounds.closed and T.gui.Parent==nil)
for _,item in ipairs(SC.sounds.rows)do assert(not item.enabled and #item.clones==0)end
