local T=__T local E=TestEnv local SC=T.SC
local function eq(a,b,message)assert(a==b,(message or"Mismatch")..": "..tostring(a).." ~= "..tostring(b))end
local function category(name)E.click(T.main,"  "..name)end
local box
for _,n in ipairs(T.gui:GetDescendants())do if n:IsA("TextBox")and n.PlaceholderText=="Password"then box=n end end
assert(box,"Password box retained")
assert(E.find(T.gui,"Script made by nonobearbear17","TextLabel"),"Startup credit")
assert(not E.find(T.gui,"Script made by nonobearbear17\nOwner can pause or disconnect this session","TextLabel"),"Startup notice removed")
box.Text="boat"SC.enterButton.Activated:Fire()eq(T.main.Visible,true)
for _,name in ipairs({"Aimbot","Leather","Tracking","Teleport"})do
 category(name)
 local rows=0
 for _,n in ipairs(T.content:GetDescendants())do
  if n:IsA("TextButton")and(n.Name==E.owner.Name or n.Name==E.localPlayer.Name)then error(name..": protected account listed")end
  if n:IsA("TextButton")and(n.Name==E.other.Name or n.Name==E.other2.Name)then rows+=1 end
 end
 eq(rows,2,name.." regular player rows")
end
assert(not E.find(T.main,"Time Bomb","TextButton"),"Time Bomb tab removed")
assert(not E.find(T.main,"TB Prac","TextButton"),"Practice tab removed")
assert(E.find(T.main,"SAKTK","TextLabel"),"SAKTK title")
assert(not T.main:FindFirstChild("GameSections"),"White section strip removed")
assert(not E.find(T.main,"  R6","TextButton"),"R6 removed")
T.selectGame("SAKTK")category("Teleport")
E.click(T.content,"  AltTwo")
local pivots=E.localPlayer.Character.Pivots or 0
E.click(T.content,"Teleport")eq(E.localPlayer.Character.Pivots,pivots+1,"Teleport retained")
T.setTeleport(E.owner)E.click(T.content,"Teleport")eq(E.localPlayer.Character.Pivots,pivots+1,"Stale protected teleport blocked")
T.setSelected(E.owner)local frame=workspace.CurrentCamera.CFrame
game.services.RunService.Steps.HeadLockMenuCamera()eq(workspace.CurrentCamera.CFrame,frame,"Protected aimbot blocked")
T.setTrack(E.owner)eq(T.trackTarget(),nil,"Protected tracking blocked")
T.setTrack(nil)T.startAuto()T.autoTrack.service(E.time)
eq(T.autoTrack.lockedPlayer,E.other,"Auto track skips closer owner")
T.autoTrack.stop()
category("Credits")
assert(E.find(T.content,"(owner only)","TextLabel"))
local function checkbox()
 for _,n in ipairs(T.content:GetDescendants())do if n:IsA("TextButton")and n.Size.X.Offset==26 and n.Size.Y.Offset==26 then return n end end
 error("Missing checkbox")
end
local cb=checkbox()cb.Activated:Fire()
eq(cb.Text,"")eq(SC.ownerFeatures,false)eq(SC.rapidFireMax(),200)
assert(not E.find(T.content,"haha u no get special stuff only me","TextLabel"))
E.localPlayer.Name="NONOBEARBEAR17"
cb.Activated:Fire()eq(cb.Text,"✓")eq(SC.rapidFireMax(),1000)
category("PVP")
local function dragRapidToMax()
 for _,n in ipairs(T.content:GetDescendants())do
  if n:IsA("Frame")and n.Position and n.Position.Y.Offset==117 then
   local handle=n:FindFirstChildOfClass("Frame")
   handle.InputBegan:Fire({UserInputType=Enum.UserInputType.MouseButton1,Position=Vector2.new(300,0)})return
  end
 end error("No rapid slider")
end
dragRapidToMax()eq(T.getPower(),1000)
assert(E.find(T.content,"1000%","TextLabel"),"Slider updates to 1000%")
eq(T.interval({shoot_wait=0.1},false),0.003,"Owner max affects firing interval")
category("Credits")cb=checkbox()eq(cb.Text,"✓","Checkbox persists across categories")
cb.Activated:Fire()eq(SC.rapidFireMax(),200)eq(T.getPower(),200,"Unchecking clamps value")
category("PVP")dragRapidToMax()eq(T.getPower(),200)
eq(T.interval({shoot_wait=0.1},false),0.015,"Normal max interval")
for _,name in ipairs({"nonobearbear","bluddyblud17","nonobearbear1","nonobearbear100","NONOBEARBEAR17"})do eq(SC.isOwnerAccount({Name=name}),true,name)end
for _,name in ipairs({"nonobearbear0","nonobearbear101","nonobearbear01","nonobearbear17x","AltOne"})do eq(SC.isOwnerAccount({Name=name}),false,name)end
E.localPlayer.Name="AltOne"SC.setOwnerFeatures(true)eq(SC.ownerFeatures,false)eq(SC.rapidFireMax(),200)
T.setPower(1000)eq(T.interval({shoot_wait=0.1},false),0.015,"Runtime ceiling enforced")
_G.HeadLockMenuCleanup()eq(T.gui.Parent,nil,"Cleanup still works")
print("Menu, selectors, Teleport, checkbox, slider, owner recognition and cleanup verified")
