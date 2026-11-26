local T=__T local E=TestEnv local SC=T.SC
local function eq(a,b,label)assert(a==b,(label or"Mismatch")..": "..tostring(a).." ~= "..tostring(b))end
E.localPlayer.Character.Parent=E.killers E.owner.Character.Parent=E.survivors
E.other2.Character:FindFirstChild("HumanoidRootPart").Position=Vector3.new(50,700,0)
game.services.RunService.Heartbeat:Fire(0.5)
T.selectGame("SAKTK")E.click(T.main,"  Juggernaut")
local button=E.click(T.content,"Auto Kill: OFF")eq(SC.juggernautAutoKill.enabled,true)
local frame=game.services.RunService.Steps.HeadLockMenuJuggernautAutoKill
frame()eq(SC.juggernautAutoKill.target,E.other,"Owner and high respawn skipped")
eq(button.Text,"Auto Kill: ON")
E.other.Character:FindFirstChildOfClass("Humanoid").Health=0
frame()eq(SC.juggernautAutoKill.enabled,false,"Stops after last eligible player")
eq(button.Text,"Auto Kill: OFF")eq(SC.juggernautAutoKill.status.Text,"OFF")
local root=E.localPlayer.Character:FindFirstChild("HumanoidRootPart")
eq(root.CFrame.LookVector.Y,0,"Upright after stopping")
eq(E.localPlayer.Character:FindFirstChildOfClass("Humanoid").AutoRotate,true)
eq(root.AssemblyAngularVelocity.Magnitude,0)eq(root.AssemblyLinearVelocity.Magnitude,0)
eq(E.owner.Character:FindFirstChildOfClass("Humanoid").Health,100,"Owner stays alive")
E.other.Character:FindFirstChildOfClass("Humanoid").Health=100
E.other2.Character:FindFirstChild("HumanoidRootPart").Position=Vector3.new(50,300,0)
E.click(T.content,"Auto Kill: OFF")frame()eq(SC.juggernautAutoKill.target,E.other)
E.other.Character:FindFirstChildOfClass("Humanoid").Health=0
frame()eq(SC.juggernautAutoKill.target,E.other2,"Advances to remaining eligible player")
E.other2.Character:FindFirstChildOfClass("Humanoid").Health=0
frame()eq(SC.juggernautAutoKill.enabled,false)
E.click(T.content,"Auto Kill: OFF")frame()eq(button.Text,"Auto Kill: OFF")
print("Juggernaut owner immunity, height cutoff, target advance, automatic OFF and orientation restore verified")
