local originalNew=Instance.new
TestEnv.audio={}
game.services.Debris={AddItem=function(_,item,delay)assert(delay>=2)item.DebrisDelay=delay end}
Instance.new=function(class)
 local object=originalNew(class)
 if class=="TextBox"then object.IsFocused=function()return false end end
 if class=="Sound"then
  object.Ended=TestEnv.signal()object.Stopped=TestEnv.signal()
  object.IsPlaying=false object.IsLoaded=true object.Looped=false object.SoundId="rbxassetid://1"object.Volume=1 object.PlaybackSpeed=1 object.TimeLength=4
  object.Play=function(self)self.PlayCount=(self.PlayCount or 0)+1 self.IsPlaying=true end
  object.Stop=function(self)self.StopCount=(self.StopCount or 0)+1 self.IsPlaying=false self.Stopped:Fire()end
  object.Clone=function(self)local copy=Instance.new("Sound")copy.Name=self.Name copy.SoundId=self.SoundId copy.TimeLength=self.TimeLength return copy end
  table.insert(TestEnv.audio,object)
 end
 return object
end
TestEnv.soundSources={}
for _,name in ipairs({"SurvivorsWin","KillerWin","Blackout"})do TestEnv.soundSources[name]=TestEnv.new("Sound",name,workspace)end
for _,name in ipairs({"Death","RageModeRoar","LockDoorRoar"})do TestEnv.soundSources[name]=TestEnv.new("Sound",name,TestEnv.owner.Character:FindFirstChild("HumanoidRootPart"))end
TestEnv.soundSources.Died=TestEnv.new("Sound","Died",TestEnv.localPlayer.Character:FindFirstChild("HumanoidRootPart"))
