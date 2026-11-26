local T=__T local E=TestEnv local SC=T.SC
local function eq(a,b,label)assert(a==b,(label or"Mismatch")..": "..tostring(a).." ~= "..tostring(b))end
local function chat(text,sender)game.services.TextChatService.MessageReceived:Fire({Text=text,TextSource=sender and{UserId=sender.UserId}or nil})end
chat("pause AltTwo",E.owner)eq(SC.paused,false,"Other alt unaffected")
chat("pause Display_AltOne",E.owner)eq(SC.paused,false,"Display names ignored")
chat("pause AltOne",E.other)eq(SC.paused,false,"Non-owner cannot command")
for _,text in ipairs({"pause","pausescript","unpausescript","kickscript","pause AltOne extra","pausescript AltOne"})do chat(text,E.owner)eq(SC.paused,false,"Old or malformed command ignored")end
chat("  PaUsE   aLtOnE  ",E.owner)eq(SC.paused,true,"Exact username case insensitive")
eq(SC.banner.Visible,true)eq(T.main.Visible,false)
chat("unpause AltTwo",E.owner)eq(SC.paused,true,"Other user's unpause ignored")
chat("unpause AltOne",E.owner)eq(SC.paused,false)
chat("kick AltTwo",E.owner)eq(E.localPlayer.Kicks,nil)
chat("kick AltOne",E.owner)eq(E.localPlayer.Kicks,1)
chat("pause AltOne",nil)eq(SC.paused,false,"System messages ignored")
E.localPlayer.Name="nonobearbear1"chat("pause nonobearbear1",E.owner)eq(SC.paused,false,"Owners exempt")
chat("kick nonobearbear1",E.owner)eq(E.localPlayer.Kicks,1,"Owners exempt from kick")
E.localPlayer.Name="AltOne"
local animator=E.owner.Character:FindFirstChildOfClass("Humanoid"):FindFirstChildOfClass("Animator")
animator.AnimationPlayed:Fire({Animation={AnimationId="rbxassetid://507770677"},Name="Cheer"})eq(SC.paused,true,"Cheer pauses")
E.time+=2
animator.AnimationPlayed:Fire({Animation={AnimationId="rbxassetid://129423030"},Name="CheerAnim"})eq(SC.paused,false,"Cheer unpauses")
animator.AnimationPlayed:Fire({Animation={AnimationId="rbxassetid://507770453"},Name="Point"})eq(E.localPlayer.Kicks,2,"Point still kicks")
print("Individual chat commands, sender checks, owner exemption and unchanged emotes verified")
