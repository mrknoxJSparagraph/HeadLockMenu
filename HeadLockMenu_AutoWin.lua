-- AutoWin installer. Embedded in the core; dependencies use existing menu logic.
return function(SC,ctx)
local Players,Run,player=ctx.Players,ctx.Run,ctx.player
local aw=SC.autoWin
aw.skipped={}; aw.killFirst={}; aw.objects=setmetatable({},{__mode="kv"}); aw.arguments=setmetatable({},{__mode="k"})
aw.modules={}; aw.equipRefresh=setmetatable({},{__mode="k"})
aw.hooks={}; aw.watches={}; aw.generation=0; aw.nextShot=0; aw.nextEquip=0; aw.status="OFF"
aw.ready=setmetatable({},{__mode="k"});aw.replaying=setmetatable({},{__mode="k"})
aw.busy=setmetatable({},{__mode="k"});aw.shots=setmetatable({},{__mode="k"})
aw.observed=setmetatable({},{__mode="k"});aw.shotLinks={};aw.nextPrime=0
local function report(text)
    if aw.status==text then return end
    aw.status=text
    if aw.update then aw.update() end
end
local function firingReady(tool,object)
    local ready=tool and aw.ready[tool]
    return ready~=nil and ready.object==object and ready.character==player.Character
        and tool.Parent==player.Character
end
local function localPistol(object)
    local tool=type(object)=="table" and rawget(object,"instance")
    if typeof(tool)=="Instance" and tool:IsA("Tool") and tool.Name=="M1911"
        and tool.Parent==player.Character then return tool end
end
function SC.autoWinNeedsFirstShot(object)
    local tool=localPistol(object)
    return aw.enabled and SC.autoWinCombat() and tool and not firingReady(tool,object)
end
local function observeTool(tool)
    if aw.observed[tool] then return end
    local handle=tool:FindFirstChild("Handle")
    local sound=handle and handle:FindFirstChild("Fire")
    if sound and sound:IsA("Sound") then
        aw.observed[tool]=true
        table.insert(aw.shotLinks,sound.Played:Connect(function()
            aw.shots[tool]=(aw.shots[tool] or 0)+1
        end))
    end
end
function SC.recordWeapon(object,args)
    if type(object)~="table" then return end
    local tool=rawget(object,"instance")
    if typeof(tool)~="Instance" or not tool:IsA("Tool") or tool.Name~="M1911" then return end
    local valid,fire=pcall(function()return object.fire end)
    if not valid or type(fire)~="function" then return end
    aw.objects[tool]=object
    if args then aw.arguments[tool]=args end
end
function SC.removeWeaponCaptureHooks()
    for i=#aw.hooks,1,-1 do
        local hook=aw.hooks[i]
        if hook.module[hook.name]==hook.wrapper then hook.module[hook.name]=hook.original end
    end
    table.clear(aw.hooks)
end
local function captureWeaponMethods()
    if #aw.hooks>0 then return true end
    local definitions=game:GetService("ReplicatedStorage"):FindFirstChild("Weapon")
    if not definitions then return false end
    local modules={definitions}
    local pistol=definitions:FindFirstChild("M1911")
    if pistol then table.insert(modules,pistol) end
    local loaded={}
    for _,script in ipairs(modules) do
        local ok,module=pcall(require,script)
        if ok and type(module)=="table" and not loaded[module] then
            loaded[module]=true
            aw.modules[module]=true
            -- Observe methods the equipped weapon already calls. Preserve their
            -- original arguments/return values, including constructor results.
            for _,name in ipairs({"new","equip","equipped","on_equipped","update_ammo_gui","play_animation","fire"}) do
                local original=rawget(module,name)
                if type(original)=="function" then
                    local wrapper=function(self,...)
                        SC.recordWeapon(self)
                        local tool=name=="fire" and localPistol(self)
                        if not tool or not aw.enabled then
                            local results=table.pack(original(self,...))
                            for i=1,results.n do SC.recordWeapon(results[i]) end
                            return table.unpack(results,1,results.n)
                        end
                        observeTool(tool)
                        local args=table.pack(...)
                        local normalInput=not aw.replaying[self]
                        local before=aw.shots[tool] or 0
                        local ammoBefore=self.ammo
                        local generation=aw.generation
                        aw.busy[self]=(aw.busy[self] or 0)+1
                        local results=table.pack(pcall(original,self,...))
                        local ammoAfter=self.ammo
                        aw.busy[self]=math.max(0,(aw.busy[self] or 1)-1)
                        local observed=(aw.shots[tool] or 0)>before or(type(ammoBefore)=="number"
                            and type(ammoAfter)=="number" and ammoAfter<ammoBefore)
                        if results[1] and normalInput and observed and aw.enabled
                            and aw.generation==generation and localPistol(self)==tool then
                            aw.ready[tool]={object=self,character=player.Character}
                            SC.recordWeapon(self,args)
                        end
                        if not results[1] then error(results[2],0) end
                        for i=2,results.n do SC.recordWeapon(results[i]) end
                        return table.unpack(results,2,results.n)
                    end
                    module[name]=wrapper
                    table.insert(aw.hooks,{module=module,name=name,original=original,wrapper=wrapper})
                end
            end
        end
    end
    return next(loaded)~=nil
end
local function findWeaponObject(tool,now)
    local object=aw.objects[tool]
    if object and object.instance==tool then return object end
    if now<(aw.nextObjectScan or 0) then return end
    aw.nextObjectScan=now+.5
    local seen={}; local nodes,functions=0,0
    local inspect
    local function accept(candidate)
        if type(candidate)~="table" or rawget(candidate,"instance")~=tool then return end
        local ok,fire=pcall(function()return candidate.fire end)
        if ok and type(fire)=="function" then SC.recordWeapon(candidate); return candidate end
    end
    local debugLibrary=type(debug)=="table" and debug or {}
    local many=debugLibrary.getupvalues or getupvalues
    local single=debugLibrary.getupvalue or getupvalue
    inspect=function(value,depth)
        local kind=type(value)
        if (kind~="table" and kind~="function") or seen[value] or nodes>=4096 then return end
        if value==SC or value==aw or value==ctx or value==_G then return end
        seen[value]=true; nodes=nodes+1
        local found=accept(value)
        if found or depth<=0 then return found end
        if kind=="table" then
            local count=0
            for key,item in next,value do
                count=count+1; if count>256 then break end
                found=inspect(item,depth-1) or inspect(key,depth-1)
                if found then return found end
            end
        elseif functions<160 then
            functions=functions+1
            if type(many)=="function" then
                local ok,values=pcall(many,value)
                if ok and type(values)=="table" then
                    for _,item in next,values do found=inspect(item,depth-1); if found then return found end end
                    return
                end
            end
            if type(single)=="function" then
                for index=1,64 do
                    local ok,first,second=pcall(single,value,index)
                    if not ok or (first==nil and second==nil) then break end
                    -- Executor implementations return either the value alone,
                    -- or Lua's (name, value) pair.
                    local item=second~=nil and second or first
                    found=inspect(item,depth-1); if found then return found end
                end
            end
        end
    end
    local function signalController(signal)
        if not signal or type(getconnections)~="function" then return end
        local ok,links=pcall(getconnections,signal)
        if not ok or type(links)~="table" then return end
        for _,link in ipairs(links) do
            local valid,callback=pcall(function()return link.Function end)
            if valid and type(callback)=="function" then
                local found=inspect(callback,6); if found then return found end
            end
        end
    end
    -- The controller may predate the menu and cache its equip/UI methods.
    -- Read the existing input handlers instead of waiting for a first shot to
    -- pass through the fire hook. Never fire signals or invoke these callbacks.
    local gui=player:FindFirstChildOfClass("PlayerGui")
    local mouseGui=gui and gui:FindFirstChild("Mouse")
    local mobile=mouseGui and mouseGui:FindFirstChild("Mobile Frame")
    local fireButton=mobile and mobile:FindFirstChild("Mobile Fire")
    for _,source in ipairs({fireButton or false,tool}) do
        if source then
            for _,name in ipairs({"Activated","MouseButton1Down","MouseButton1Click","InputBegan"}) do
                local ok,signal=pcall(function()return source[name]end)
                local found=ok and signalController(signal)
                if found then return found end
            end
        end
    end
    if type(player.GetMouse)=="function" then
        local ok,mouse=pcall(player.GetMouse,player)
        if ok and mouse then
            local found=signalController(mouse.Button1Down)
            if found then return found end
        end
    end
    local input=game:GetService("UserInputService")
    local found=signalController(input.InputBegan)
    if found then return found end
    for module in pairs(aw.modules) do found=inspect(module,4); if found then return found end end
    if type(getgc)=="function" then
        local ok,objects=pcall(getgc,true)
        if not ok or type(objects)~="table" then ok,objects=pcall(getgc,false) end
        if ok and type(objects)=="table" then
            -- Direct table results are checked before traversing function-only
            -- results, which some mobile executors return even with true.
            for _,candidate in ipairs(objects) do found=accept(candidate); if found then return found end end
            seen={}; nodes=0; functions=0
            for _,candidate in ipairs(objects) do
                found=inspect(candidate,5); if found then return found end
                if nodes>=4096 then break end
            end
        end
    end
end
local function living(target,container)
    local c=target and target.Character
    local h=c and c:FindFirstChildOfClass("Humanoid")
    local r=c and c:FindFirstChild("HumanoidRootPart")
    if c and c.Parent==container and h and h.Health>0 and r then return c,h,r end
end
local function releaseInput(primer)
    local release=primer and primer.release
    if release then primer.release=nil;pcall(release) end
end
local function cancelPrime()
    local primer=aw.primer
    aw.primer=nil
    releaseInput(primer)
end
local function sendSignal(signal,...)
    local sent=false
    if type(getconnections)=="function" then
        local ok,links=pcall(getconnections,signal)
        if ok and type(links)=="table" then for _,link in ipairs(links) do
            local valid,callback=pcall(function()return link.Function end)
            if valid and type(callback)=="function" then
                local worked=pcall(callback,...);sent=worked or sent
            else
                local worked=pcall(function(...)link:Fire(...)end,...);sent=worked or sent
            end
        end end
    end
    if not sent and type(firesignal)=="function" then sent=pcall(firesignal,signal,...) end
    return sent
end
local function primeWeapon(tool,now)
    if aw.primer or now<aw.nextPrime then return end
    local object=aw.objects[tool]
    if object and (aw.busy[object] or 0)>0 then return end
    aw.nextPrime=now+4
    local primer={tool=tool,generation=aw.generation}
    aw.primer=primer
    local function current()
        return aw.primer==primer and aw.enabled and not SC.paused and not SC.closing
            and aw.generation==primer.generation and SC.autoWinCombat()
            and not aw.skipped[aw.target.UserId] and tool.Parent==player.Character
    end
    local function waitForReady()
        local deadline=os.clock()+.25
        repeat
            if not current() or firingReady(tool,aw.objects[tool]) then return end
            task.wait(.02)
        until os.clock()>=deadline
    end
    task.spawn(function()
        if not current() then
            if aw.primer==primer then aw.primer=nil end
            return
        end
        local input=game:GetService("UserInputService")
        local gui=player:FindFirstChildOfClass("PlayerGui")
        local mouseGui=gui and gui:FindFirstChild("Mouse")
        local mobile=mouseGui and mouseGui:FindFirstChild("Mobile Frame")
        local button=mobile and mobile:FindFirstChild("Mobile Fire")
        local camera=workspace.CurrentCamera
        local view=camera and camera.ViewportSize or Vector2.new(800,600)
        local point=Vector2.new(view.X*.5,view.Y*.5)
        if button and button.Visible and button.AbsoluteSize.X>0 and button.AbsoluteSize.Y>0 then
            point=button.AbsolutePosition+button.AbsoluteSize/2
        end
        local methods={}
        local function click(name,down,up)
            table.insert(methods,{name=name,run=function()
                primer.release=up
                local ok,why=pcall(down)
                if ok then waitForReady() else primer.error=tostring(why) end
                releaseInput(primer)
            end})
        end
        local created,virtual=pcall(function()return input:CreateVirtualInput()end)
        if created and virtual then
            click("virtual input",function()virtual:SendMouseButton(point,Enum.UserInputType.MouseButton1,true,0)end,
                function()virtual:SendMouseButton(point,Enum.UserInputType.MouseButton1,false,0)end)
        end
        local managerOk,manager=pcall(game.GetService,game,"VirtualInputManager")
        if managerOk and manager then
            click("mouse input",function()manager:SendMouseButtonEvent(point.X,point.Y,0,true,game,0)end,
                function()manager:SendMouseButtonEvent(point.X,point.Y,0,false,game,0)end)
        end
        if button then
            click("fire button",function()sendSignal(button.MouseButton1Down,point.X,point.Y)end,
                function()sendSignal(button.MouseButton1Up,point.X,point.Y)end)
            table.insert(methods,{name="fire click",run=function()sendSignal(button.MouseButton1Click)end})
            if aw.lastInput then
                table.insert(methods,{name="fire activation",run=function()sendSignal(button.Activated,aw.lastInput,1)end})
                click("fire touch",function()sendSignal(button.InputBegan,aw.lastInput)end,
                    function()sendSignal(button.InputEnded,aw.lastInput)end)
                local icon=button:FindFirstChild("Icon")
                if icon then
                    click("fire icon touch",function()sendSignal(icon.InputBegan,aw.lastInput)end,
                        function()sendSignal(icon.InputEnded,aw.lastInput)end)
                end
            end
        end
        local mouseOk,mouse=pcall(function()return player:GetMouse()end)
        if mouseOk and mouse then
            click("player mouse",function()sendSignal(mouse.Button1Down)end,function()sendSignal(mouse.Button1Up)end)
        end
        for _,method in ipairs(methods) do
            if not current() or firingReady(tool,aw.objects[tool]) then break end
            report("Starting first trigger: "..method.name)
            local ok,why=pcall(method.run)
            releaseInput(primer)
            if not ok then primer.error=tostring(why) end
            waitForReady()
        end
        releaseInput(primer)
        if aw.primer==primer then
            local stillCurrent=current()
            aw.primer=nil
            if stillCurrent and not firingReady(tool,aw.objects[tool]) then
                report("Automatic trigger unavailable. No first shot detected.")
            end
        end
    end)
end
local function releaseFlight()
    local flight=aw.flight
    aw.flight=nil
    if not flight then return end
    if flight.root.Parent then
        flight.root.Anchored=flight.anchored
        flight.root.AssemblyLinearVelocity=Vector3.zero
    end
    if flight.hum.Parent then flight.hum.AutoRotate=flight.autoRotate end
    for part,value in pairs(flight.collisions) do if part.Parent then part.CanCollide=value end end
end
local function stopOwnedKill()
    if aw.ownsKill then SC.stopJuggernautAutoKill(); aw.ownsKill=false end
end
local function resetRole()
    aw.generation=aw.generation+1
    cancelPrime();aw.nextPrime=0
    aw.role=nil; aw.target=nil
    aw.priorityQueue=nil
    aw.nextObjectScan=0
    releaseFlight(); stopOwnedKill()
end
local function followTarget(c,h,r,targetRoot)
    local flight=aw.flight
    if flight and flight.root~=r then releaseFlight(); flight=nil end
    if not flight then
        flight={root=r,hum=h,anchored=r.Anchored,autoRotate=h.AutoRotate,collisions={}}
        aw.flight=flight
    end
    for _,part in ipairs(c:GetDescendants()) do
        if part:IsA("BasePart") then
            if flight.collisions[part]==nil then flight.collisions[part]=part.CanCollide end
            part.CanCollide=false
        end
    end
    h.AutoRotate=false; r.Anchored=true; r.AssemblyLinearVelocity=Vector3.zero
    SC.followJugPosition(c,targetRoot)
end
function SC.setAutoWin(value)
    value=value==true and SC.ownerFeatures and SC.isOwnerAccount(player) and not SC.paused and not SC.closing
    if value==aw.enabled then return value end
    aw.session=(aw.session or 0)+1
    aw.enabled=value; resetRole()
    if value then
        aw.resume={fly=SC.cFlyEnabled,followJug=SC.cFlyFollowJug}
        ctx.stopMovement()
        if SC.vehicles then SC.vehicles.exit() end
        SC.gravity.enabled=false; SC.stopGravity()
        aw.nextEquip=0; aw.nextObjectScan=0; aw.nextShot=0; aw.initialized=false
        table.clear(aw.equipRefresh)
        report("Preparing M1911...")
        local session=aw.session
        task.spawn(function()
            local ok,reason=pcall(function()
                assert(ctx.ensureFire(),"Weapon controller unavailable")
                if not aw.enabled or aw.session~=session then return end
                assert(captureWeaponMethods(),"Weapon controller unavailable")
                assert(ctx.ensureRecoil(),"No Recoil hook unavailable")
                assert(ctx.ensureSpread(),"No Spread hook unavailable")
            end)
            if not aw.enabled or aw.session~=session then
                if not aw.enabled then SC.removeWeaponCaptureHooks() end
                return
            end
            aw.initialized=ok
            if ok then SC.stepAutoWin(true) else report("AutoWin could not start: "..tostring(reason)) end
        end)
    else
        SC.removeWeaponCaptureHooks()
        report("OFF")
        local resume=aw.resume; aw.resume=nil
        if resume and resume.fly and not SC.paused and not SC.closing and player.Character then
            if ctx.startFly() then SC.cFlyFollowJug=resume.followJug end
        end
    end
    if aw.update then aw.update() end
    return value
end
local function equipPistol(c,h,now)
    local tool=c:FindFirstChild("M1911")
    local backpack=player:FindFirstChildOfClass("Backpack")
    if not tool then tool=backpack and backpack:FindFirstChild("M1911") end
    if not tool or not tool:IsA("Tool") then report("Waiting for M1911 in inventory"); return end
    if aw.weaponCharacter~=c or aw.equippingTool~=tool then
        if aw.weaponCharacter~=c then aw.objects[tool]=nil;aw.arguments[tool]=nil end
        aw.weaponCharacter=c;aw.equippingTool=tool
        aw.nextEquip=0;aw.nextObjectScan=0
    end
    if tool.Parent~=c and now>=aw.nextEquip then
        aw.nextEquip=now+.5
        h:EquipTool(tool)
    elseif tool.Parent==c and not aw.objects[tool] and not aw.equipRefresh[tool] and now>=aw.nextEquip then
        -- Hooks installed after an existing equip need one fresh equip event.
        aw.nextEquip=now+2
        aw.equipRefresh[tool]=true
        if backpack then h:UnequipTools(); h:EquipTool(tool) end
    end
    if tool.Parent~=c then return end
    return tool
end
function aw.chooseFirst(eligible,current)
    if not aw.enabled or aw.role~="juggernaut" then return end
    if current and aw.killFirst[current.UserId] and eligible(current) then return current end
    if not aw.priorityQueue then
        aw.priorityQueue={}
        for _,p in ipairs(Players:GetPlayers()) do
            if p~=player and aw.killFirst[p.UserId] then table.insert(aw.priorityQueue,p) end
        end
        for i=#aw.priorityQueue,2,-1 do
            local other=math.random(i)
            aw.priorityQueue[i],aw.priorityQueue[other]=aw.priorityQueue[other],aw.priorityQueue[i]
        end
    end
    for _,p in ipairs(aw.priorityQueue) do
        if p.Parent==Players and aw.killFirst[p.UserId] and eligible(p) then return p end
    end
end
function SC.stepAutoWin(refresh)
    if not aw.enabled or not aw.initialized then return end
    if SC.paused or SC.closing or not SC.ownerFeatures or not SC.isOwnerAccount(player) then SC.setAutoWin(false); return end
    if refresh then ctx.updateJuggernaut() end
    local killers=workspace:FindFirstChild("Killers")
    local survivors=workspace:FindFirstChild("Characters to kill")
    local target=ctx.getJuggernaut()
    local mine,h,r=living(player,player.Character and player.Character.Parent)
    if not mine or (mine.Parent~=killers and mine.Parent~=survivors) or SC.tripKind or (SC.fling and SC.fling.active) then
        if aw.role then resetRole() end
        report("Waiting for round..."); return
    end
    -- Resolve the already-created weapon while waiting for the round as well,
    -- so the first detected Juggernaut does not need a manual trigger press.
    local now=os.clock()
    local tool,object
    if mine.Parent==survivors then
        tool=equipPistol(mine,h,now)
        if tool then observeTool(tool);object=findWeaponObject(tool,now) end
    end
    if target==player and mine.Parent==killers then
        if aw.role~="juggernaut" then resetRole(); aw.role="juggernaut" end
        if not SC.juggernautAutoKill.enabled and os.clock()>=(aw.nextKillStart or 0) then
            aw.nextKillStart=os.clock()+.15
            aw.ownsKill=SC.startJuggernautAutoKill()==true
        end
        report("Juggernaut: Auto Kill ON"); return
    end
    local model,_,targetRoot=living(target,killers)
    if not model or target==player or mine.Parent~=survivors or aw.skipped[target.UserId] then
        if aw.role then resetRole() end
        report(model and aw.skipped[target.UserId] and ("Skipping "..target.Name) or "Waiting for Juggernaut...")
        return
    end
    if aw.role~="survivor" or aw.target~=target then
        resetRole(); aw.role="survivor"; aw.target=target; aw.nextShot=0
    end
    if SC.cFlyEnabled then ctx.stopFly() end
    SC.trackEnabled=false; SC.followEnabled=false; SC.speedEnabled=false
    if SC.juggernautAutoKill.enabled then SC.stopJuggernautAutoKill() end
    followTarget(mine,h,r,targetRoot)
    if not tool then return end
    object=object or aw.objects[tool]
    if not firingReady(tool,object) then
        primeWeapon(tool,now)
        object=aw.objects[tool]
        if not firingReady(tool,object) then return end
    end
    if aw.primer or (aw.busy[object] or 0)>0 then return end
    if aw.firing or now<aw.nextShot then return end
    local generation=aw.generation
    aw.nextShot=now+.003; aw.firing=true
    task.spawn(function()
        local ok,reason=pcall(function()
            if not aw.enabled or aw.generation~=generation or tool.Parent~=player.Character or aw.skipped[target.UserId] then return end
            local args=aw.arguments[tool] or table.pack()
            assert(type(object.fire)=="function","M1911 firing method unavailable")
            local head=model:FindFirstChild("Head") or targetRoot
            local camera=workspace.CurrentCamera
            if camera and (head.Position-camera.CFrame.Position).Magnitude>.05 then
                camera.CFrame=CFrame.lookAt(camera.CFrame.Position,head.Position)
            end
            aw.replaying[object]=true
            local results=table.pack(pcall(object.fire,object,table.unpack(args,1,args.n)))
            aw.replaying[object]=nil
            if not results[1] then
                aw.ready[tool]=nil;aw.arguments[tool]=nil;aw.nextPrime=0
                error(results[2],0)
            end
        end)
        aw.firing=false
        if not aw.enabled or aw.generation~=generation then return end
        if ok then report("Following "..target.Name.." | 1000%")
        else aw.nextShot=os.clock()+1; report("M1911: "..string.sub(tostring(reason),1,110)) end
    end)
end
local function changed()
    if aw.enabled then task.defer(function()if aw.enabled and not SC.closing then SC.stepAutoWin(true) end end) end
end
local function watchPlayer(p)
    aw.priorityQueue=nil
    local record={links={}}; aw.watches[p]=record
    local function watchCharacter(c)
        for _,link in ipairs(record.characterLinks or {}) do link:Disconnect() end
        record.characterLinks={}
        local function on(signal,callback)table.insert(record.characterLinks,signal:Connect(callback))end
        on(c:GetPropertyChangedSignal("Parent"),changed)
        on(c.ChildAdded,changed)
        local h=c:FindFirstChildOfClass("Humanoid")
        if h then on(h.Died,changed) end
        changed()
    end
    table.insert(record.links,p.CharacterAdded:Connect(watchCharacter))
    table.insert(record.links,p.CharacterRemoving:Connect(function()
        if p==player then resetRole() end
        changed()
    end))
    if p.Character then watchCharacter(p.Character) end
end
local function unwatchPlayer(p)
    aw.priorityQueue=nil
    local record=aw.watches[p]
    if record then
        for _,links in ipairs({record.links,record.characterLinks or {}}) do for _,link in ipairs(links) do link:Disconnect() end end
        aw.watches[p]=nil
    end
    if aw.target==p then resetRole() end
    if aw.refreshPlayers then task.defer(aw.refreshPlayers) end
end
for _,p in ipairs(Players:GetPlayers()) do watchPlayer(p) end
ctx.connect(Players.PlayerAdded,function(p)watchPlayer(p); if aw.refreshPlayers then aw.refreshPlayers() end end)
ctx.connect(Players.PlayerRemoving,unwatchPlayer)
ctx.connect(Run.Heartbeat,function()SC.stepAutoWin(false)end)
Run:BindToRenderStep("HeadLockMenuAutoWinFollow",Enum.RenderPriority.Character.Value+3,function()
    if aw.enabled and aw.role=="survivor" and not SC.paused then SC.stepAutoWin(false) end
end)
Run:BindToRenderStep("HeadLockMenuAutoWinAim",Enum.RenderPriority.Camera.Value+2,function()
    if not SC.autoWinCombat() then return end
    local target=aw.target and aw.target.Character
    local head=target and (target:FindFirstChild("Head") or target:FindFirstChild("HumanoidRootPart"))
    local camera=workspace.CurrentCamera
    if head and camera and (head.Position-camera.CFrame.Position).Magnitude>.05 then
        camera.CFrame=CFrame.lookAt(camera.CFrame.Position,head.Position)
    end
end)
function aw.cleanup()
    SC.setAutoWin(false)
    SC.removeWeaponCaptureHooks()
    cancelPrime()
    for _,link in ipairs(aw.shotLinks) do link:Disconnect() end
    table.clear(aw.shotLinks)
    for p in pairs(aw.watches) do unwatchPlayer(p) end
    Run:UnbindFromRenderStep("HeadLockMenuAutoWinFollow")
    Run:UnbindFromRenderStep("HeadLockMenuAutoWinAim")
end
function aw.draw(panel)
    local make,button=ctx.make,ctx.button
    panel=make("ScrollingFrame",{Name="AutoWinSettings",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,
        BorderSizePixel=0,ScrollBarThickness=3,CanvasSize=UDim2.fromOffset(0,286),ScrollingDirection=Enum.ScrollingDirection.Y},panel)
    make("TextLabel",{Size=UDim2.new(1,0,0,30),BackgroundTransparency=1,Text="AutoWin",TextColor3=ctx.white,
        Font=Enum.Font.Code,TextSize=20,TextXAlignment=Enum.TextXAlignment.Left},panel)
    local toggle=button("OFF",panel); toggle.Name="AutoWinToggle"; toggle.Position=UDim2.fromOffset(0,38); toggle.Size=UDim2.fromOffset(105,38)
    local status=make("TextLabel",{Name="AutoWinStatus",Position=UDim2.fromOffset(0,82),Size=UDim2.new(1,0,0,40),
        BackgroundTransparency=1,Text=aw.status,TextWrapped=true,TextColor3=ctx.white,Font=Enum.Font.Code,TextSize=12,
        TextXAlignment=Enum.TextXAlignment.Left},panel)
    make("TextLabel",{Position=UDim2.fromOffset(0,126),Size=UDim2.new(1,0,0,24),BackgroundTransparency=1,
        Text="Skip auto kill on players:",TextColor3=ctx.white,Font=Enum.Font.Code,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left},panel)
    local names=button("Players",panel); names.Name="AutoWinPlayers"; names.Position=UDim2.fromOffset(0,154); names.Size=UDim2.new(1,-5,0,36)
    local list=make("ScrollingFrame",{Name="AutoWinPlayerList",Position=UDim2.fromOffset(0,198),Size=UDim2.new(1,0,0,140),
        BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,CanvasSize=UDim2.fromOffset(0,0),Visible=aw.listOpen==true},panel)
    make("UIListLayout",{Padding=UDim.new(0,4),SortOrder=Enum.SortOrder.LayoutOrder},list)
    local priorityLabel=make("TextLabel",{Size=UDim2.new(1,0,0,24),BackgroundTransparency=1,
        Text="Kill first when I'm Juggernaut:",TextColor3=ctx.white,Font=Enum.Font.Code,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left},panel)
    local priorityNames=button("Players",panel); priorityNames.Name="AutoWinKillFirstPlayers"; priorityNames.Size=UDim2.new(1,-5,0,36)
    local priorityList=make("ScrollingFrame",{Name="AutoWinKillFirstList",Size=UDim2.new(1,0,0,140),
        BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,CanvasSize=UDim2.fromOffset(0,0),Visible=aw.killListOpen==true},panel)
    make("UIListLayout",{Padding=UDim.new(0,4),SortOrder=Enum.SortOrder.LayoutOrder},priorityList)
    aw.update=function()
        if not toggle.Parent then return end
        toggle.Text=aw.enabled and "ON" or "OFF"
        toggle.BackgroundColor3=aw.enabled and ctx.white or ctx.black
        toggle.TextColor3=aw.enabled and ctx.black or ctx.white
        status.Text=aw.status
        list.Visible=aw.listOpen==true
        local count,priorities=0,0
        for _,p in ipairs(Players:GetPlayers()) do if p~=player then
            if aw.skipped[p.UserId] then count=count+1 end
            if aw.killFirst[p.UserId] then priorities=priorities+1 end
        end end
        names.Text="Players ("..count.." selected)"
        priorityNames.Text="Players ("..priorities.." selected)"
        local y=aw.listOpen and 354 or 206
        priorityLabel.Position=UDim2.fromOffset(0,y)
        priorityNames.Position=UDim2.fromOffset(0,y+28)
        priorityList.Position=UDim2.fromOffset(0,y+72)
        priorityList.Visible=aw.killListOpen==true
        panel.CanvasSize=UDim2.fromOffset(0,y+80+(aw.killListOpen and 146 or 0))
    end
    aw.refreshPlayers=function()
        if not list.Parent then return end
        for _,child in ipairs(list:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
        for _,child in ipairs(priorityList:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
        local players=Players:GetPlayers(); table.sort(players,function(a,b)return a.Name:lower()<b.Name:lower()end)
        local count=0
        for _,p in ipairs(players) do if p~=player then
            count=count+1
            local selected=aw.skipped[p.UserId]
            local row=button((selected and "[x] " or "[ ] ")..p.Name,list)
            row.Name="Skip_"..p.UserId; row.LayoutOrder=count; row.Size=UDim2.new(1,-6,0,34)
            row.TextSize=13; row.TextXAlignment=Enum.TextXAlignment.Left; row.TextTruncate=Enum.TextTruncate.AtEnd
            row.BackgroundColor3=selected and ctx.white or ctx.black; row.TextColor3=selected and ctx.black or ctx.white
            row.Activated:Connect(function()
                aw.skipped[p.UserId]=not aw.skipped[p.UserId] or nil
                SC.stepAutoWin(true); aw.refreshPlayers(); aw.update()
            end)
            local first=aw.killFirst[p.UserId]
            local priorityRow=button((first and "[x] " or "[ ] ")..p.Name,priorityList)
            priorityRow.Name="KillFirst_"..p.UserId; priorityRow.LayoutOrder=count; priorityRow.Size=UDim2.new(1,-6,0,34)
            priorityRow.TextSize=13; priorityRow.TextXAlignment=Enum.TextXAlignment.Left; priorityRow.TextTruncate=Enum.TextTruncate.AtEnd
            priorityRow.BackgroundColor3=first and ctx.white or ctx.black; priorityRow.TextColor3=first and ctx.black or ctx.white
            priorityRow.Activated:Connect(function()
                aw.killFirst[p.UserId]=not aw.killFirst[p.UserId] or nil
                aw.priorityQueue=nil
                SC.stepAutoWin(true); aw.refreshPlayers(); aw.update()
            end)
        end end
        list.CanvasSize=UDim2.fromOffset(0,count*38+4)
        priorityList.CanvasSize=UDim2.fromOffset(0,count*38+4)
        aw.update()
    end
    toggle.Activated:Connect(function(input)
        if input then aw.lastInput=input end
        SC.setAutoWin(not aw.enabled)
    end)
    names.Activated:Connect(function()aw.listOpen=not aw.listOpen; aw.update()end)
    priorityNames.Activated:Connect(function()aw.killListOpen=not aw.killListOpen; aw.update()end)
    aw.refreshPlayers(); aw.update()
end
return aw
end
