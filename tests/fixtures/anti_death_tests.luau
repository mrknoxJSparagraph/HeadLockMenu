local T,E=__T,TestEnv local SC=T.SC
local function eq(a,b,label)assert(a==b,(label or"Mismatch")..": "..tostring(a).." ~= "..tostring(b))end
local c=E.localPlayer.Character local h=c:FindFirstChildOfClass("Humanoid")local root=c:FindFirstChild("HumanoidRootPart")
local function damage(health)h.Health=health h.HealthChanged:Fire(health)end
local function round(role,max)
 c.Parent=workspace SC.syncAntiDeath()h.MaxHealth=max h.Health=max
 c.Parent=role=="juggernaut"and E.killers or E.survivors
 root.Position=Vector3.new(0,300,0)root.CFrame=CFrame.new(root.Position)
 SC.syncAntiDeath()
end
T.selectGame()E.click(T.main,"  Anti-Death")
eq(E.find(T.main,"  R6","TextButton"),nil,"R6 removed")
round("survivor",150)SC.setAntiThreshold("survivor",60)
local toggle=assert(T.content:FindFirstChild("SurvivorAntiToggle",true))toggle.Activated:Fire()
eq(SC.anti.survivor.enabled,true)
local baseline=c.Pivots or 0 damage(100)eq(c.Pivots or 0,baseline)
T.setTrack(E.other)SC.followEnabled=true SC.speedEnabled=true T.autoTrack.mode="Tracking"
damage(60)eq(c.Pivots,baseline+1,"Survivor escape at threshold")
eq(root.Position.X,109.30000305175781)eq(root.Position.Y,335.49996948242188)eq(root.Position.Z,62)
eq(SC.anti.survivor.spent,true)eq(SC.trackEnabled,false)eq(SC.followEnabled,false)eq(SC.speedEnabled,false)eq(T.autoTrack.mode,nil)
damage(50)eq(c.Pivots,baseline+1,"Escape is one-shot")
SC.setAntiThreshold("survivor",55)eq(SC.anti.survivor.spent,true,"Cannot rearm above remaining HP")
SC.setAntiThreshold("survivor",40)eq(SC.anti.survivor.spent,false)
damage(40)eq(c.Pivots,baseline+2,"Lower threshold rearms")
round("survivor",100)SC.setAntiThreshold("survivor",60)
baseline=c.Pivots or 0 root.Position=Vector3.new(0,700,0)root.CFrame=CFrame.new(root.Position)
damage(50)eq(c.Pivots or 0,baseline,"High spawn area never triggers")eq(SC.anti.survivor.spent,false)
root.Position=Vector3.new(0,506.5,0)root.CFrame=CFrame.new(root.Position)
damage(49)eq(c.Pivots or 0,baseline,"Exact cutoff excluded")eq(SC.anti.survivor.spent,false)
root.Position=Vector3.new(0,506.499,0)root.CFrame=CFrame.new(root.Position)
damage(48)eq(c.Pivots,baseline+1,"Combat area is active")
round("survivor",150)SC.setAntiThreshold("survivor",75)
baseline=c.Pivots or 0 damage(75)eq(c.Pivots,baseline+1)
damage(60)eq(c.Pivots,baseline+1,"Survivor cannot repeatedly escape while still below threshold")
damage(75)eq(SC.anti.survivor.spent,true,"Healing exactly to threshold does not rearm")
damage(76)eq(SC.anti.survivor.spent,false,"Healing above threshold automatically rearms")
eq(c.Pivots,baseline+1,"Healing itself does not teleport")
damage(75)eq(c.Pivots,baseline+2,"Next drop to threshold escapes again")
damage(74)eq(c.Pivots,baseline+2)
damage(150)eq(SC.anti.survivor.spent,false)
damage(74)eq(c.Pivots,baseline+3,"Crossing below threshold after healing also escapes")
round("survivor",150)SC.setAntiThreshold("survivor",60)
baseline=c.Pivots or 0 damage(0)eq(c.Pivots or 0,baseline,"Fatal hits cannot be escaped after death")
round("juggernaut",1400)SC.setAntiThreshold("juggernaut",1000)SC.anti.juggernaut.enabled=true
baseline=c.Pivots or 0 damage(1000)eq(c.Pivots,baseline+1,"Juggernaut uses its own threshold")
damage(900)eq(c.Pivots,baseline+1)
round("juggernaut",500)
eq(SC.anti.juggernaut.max,500)eq(SC.anti.juggernaut.threshold,357,"New round rescales the saved percentage")
eq(SC.anti.juggernaut.spent,false)
baseline=c.Pivots or 0 eq(c.Pivots or 0,baseline,"No escape merely from spawning")
damage(499)eq(c.Pivots or 0,baseline,"Old 1000 HP setting cannot trigger in new 500 HP round")
damage(357)eq(c.Pivots,baseline+1)
SC.setAntiThreshold("juggernaut",300)damage(300)eq(c.Pivots,baseline+2,"Juggernaut rearms by lowering slider")
-- Actual C-Fly is stopped and its anchored root is restored before escape.
round("juggernaut",1400)SC.setAntiThreshold("juggernaut",1000)
E.click(T.main,"  C-Fly")E.click(T.content,"OFF")eq(root.Anchored,true)
damage(1000)eq(root.Anchored,false)eq(SC.cFlyEnabled,false)
-- The visible Speed toggle must also reflect the automatic movement stop.
round("survivor",100)SC.setAntiThreshold("survivor",60)
E.click(T.main,"  Speed")E.click(T.content,"OFF")eq(SC.speedEnabled,true)
damage(60)eq(SC.speedEnabled,false)assert(E.find(T.content,"OFF","TextButton"))
local oldHealthListeners=h.HealthChanged.listeners
local replacement=E.addPlayer("ReplacementCharacter",999,0,300,E.killers)
local newHumanoid=replacement.Character:FindFirstChildOfClass("Humanoid")newHumanoid.MaxHealth=900 newHumanoid.Health=900
E.localPlayer.Character=replacement.Character SC.syncAntiDeath()
eq(SC.anti.humanoid,newHumanoid)eq(SC.anti.juggernaut.max,900)
for _,connection in ipairs(oldHealthListeners)do eq(connection.Connected,false,"Old character listener disconnected")end
local newListeners=newHumanoid.HealthChanged.listeners
_G.HeadLockMenuCleanup()
for _,connection in ipairs(newListeners)do eq(connection.Connected,false,"New character listener cleaned up")end
eq(SC.anti.connection,nil)eq(SC.anti.survivor.enabled,false)eq(SC.anti.juggernaut.enabled,false)
for _,connection in ipairs(oldHealthListeners)do eq(connection.Connected,false,"Health listener cleaned up")end
print("Both Anti-Death roles, HP ranges, new rounds, manual rearming, movement stopping, height cutoff and cleanup verified")
