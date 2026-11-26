local T=__T local E=TestEnv local SC=T.SC
local function eq(a,b,label)assert(a==b,(label or"Mismatch")..": "..tostring(a).." ~= "..tostring(b))end
T.selectGame("SAKTK")E.click(T.main,"  C-Fly")
E.click(T.content,"Follow Jug: OFF")eq(SC.cFlyFollowJug,false)
assert(E.find(T.content,"nuh uh you cant kill me","TextLabel"),"Owner denial shown below")
E.click(T.content,"OFF")
E.click(T.content,"Follow Jug: OFF")eq(SC.cFlyFollowJug,false)
local fly=game.services.RunService.Steps.HeadLockMenuCFly
assert(fly,"C-Fly retained")
local old=E.localPlayer.Character.Pivots or 0
fly(1/60)eq(E.localPlayer.Character.Pivots or 0,old,"No owner teleport")
E.owner.Character.Parent=E.survivors E.other.Character.Parent=E.killers
game.services.RunService.Heartbeat:Fire(0.5)
E.click(T.content,"Follow Jug: OFF")eq(SC.cFlyFollowJug,true)
fly(1/60)eq(E.localPlayer.Character.Pivots,old+1,"Non-owner Follow Jug works")
E.other.Character.Parent=E.survivors E.owner.Character.Parent=E.killers
game.services.RunService.Heartbeat:Fire(0.5)
fly(1/60)eq(SC.cFlyFollowJug,false,"Following stops if new Jug is an owner")
assert(E.find(T.content,"Follow Jug: OFF","TextButton"))
assert(E.find(T.content,"nuh uh you cant kill me","TextLabel"))
E.click(T.content,"ON")
eq(E.localPlayer.Character:FindFirstChild("HumanoidRootPart").Anchored,false)
eq(game.services.RunService.Steps.HeadLockMenuCFly,nil)
print("C-Fly, owner denial message, normal following and owner transition verified")
