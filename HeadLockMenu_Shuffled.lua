local previous=_G.HeadLockMenuLaunchThread
if previous and task.cancel then pcall(task.cancel,previous)end
local session={}
_G.HeadLockMenuLaunchSession=session
local state={stage="Starting menu",ready=false,fallback=false}
_G.HeadLockMenuStartup=state
local screen,label
pcall(function()
 local p=game:GetService("Players").LocalPlayer
 local parent=p and(p:FindFirstChildOfClass("PlayerGui")or p:WaitForChild("PlayerGui",10))
 if type(gethui)=="function"then local ok,value=pcall(gethui)if ok and value then parent=value end end
 if not parent then return end
 local old=parent:FindFirstChild("HeadLockLoader")if old then old:Destroy()end
 screen=Instance.new("ScreenGui")screen.Name="HeadLockLoader"screen.ResetOnSpawn=false screen.IgnoreGuiInset=true screen.DisplayOrder=100010 screen.Parent=parent
 label=Instance.new("TextLabel")label.Size=UDim2.new(1,-32,0,140)label.Position=UDim2.new(0,16,.5,-70)
 label.BackgroundColor3=Color3.new(0,0,0)label.TextColor3=Color3.new(1,1,1)label.Font=Enum.Font.Code label.TextSize=14 label.TextWrapped=true label.Text=state.stage label.Parent=screen
end)
local function status(text)
 state.stage=text if label and label.Parent then label.Text=text end
end
local function current()return _G.HeadLockMenuLaunchSession==session end
local function attempt(url,fallback)
 local done,success,reason=false,false,nil
 _G.HeadLockMenuExecutionReady=nil _G.HeadLockMenuExecutionError=nil
 local worker=task.spawn(function()
  success,reason=pcall(function()
   local source=game:HttpGet(url,true)
   assert(type(source)=="string"and #source>1000,"Download was empty or incomplete")
   assert(not source:match("^%s*<"),"Download returned a webpage")
   if not current()then error("Launch cancelled")end
   local run,why=loadstring(source,"HeadLockMenuCore")assert(run,why or"Menu could not compile")
   run()
   if not fallback then assert(_G.HeadLockMenuExecutionReady,_G.HeadLockMenuExecutionError or"Menu did not finish starting")
   else
    local p=game:GetService("Players").LocalPlayer local pg=p and p:FindFirstChildOfClass("PlayerGui")
    local gui=pg and pg:FindFirstChild("HeadLockMenu")
    assert(gui and gui:FindFirstChild("PasswordScreen")and not pg:FindFirstChild("HeadLockStartup"),"Recovery menu did not finish starting")
   end
  end)
  done=true
 end)
 _G.HeadLockMenuLaunchThread=worker
 local deadline=os.clock()+20
 while current()and not done and os.clock()<deadline do task.wait(.05)end
 if not done then
  if task.cancel then pcall(task.cancel,worker)end
  return false,"Startup timed out"
 end
 return success,tostring(reason)
end
status("Loading menu...")
local ok,why=attempt("https://raw.githubusercontent.com/mrknoxJSparagraph/HeadLockMenu/main/HeadLockMenu_Core.lua",false)
if not current()then return end
if not ok then
 state.error=why warn("HeadLockMenu startup: "..why)
 status("Starting recovery menu...")
 if type(_G.HeadLockMenuCleanup)=="function"then pcall(_G.HeadLockMenuCleanup)end
 pcall(function()
  local p=game:GetService("Players").LocalPlayer local pg=p and p:FindFirstChildOfClass("PlayerGui")
  if pg then for _,child in ipairs(pg:GetChildren())do
   if child.Name=="HeadLockMenu"or child.Name=="HeadLockStartup"or child.Name=="HeadLockPAPMini"then child:Destroy()end
  end end
 end)
 ok,why=attempt("https://raw.githubusercontent.com/mrknoxJSparagraph/HeadLockMenu/abce0b730e6f1a180103a32e2b0b7b1487e73d69/HeadLockMenu_Shuffled.lua",true)
 state.fallback=ok
end
if not current()then return end
if ok then
 state.ready=true
 if state.fallback then
  status("Previous menu restored. The latest update could not start.")
  task.delay(5,function()if screen and screen.Parent then screen:Destroy()end end)
 elseif screen then screen:Destroy()end
else
 state.error=why status("Menu could not start:\n"..why.."\nRejoin, then run the launcher again.")
 warn("HeadLockMenu recovery: "..why)
end
