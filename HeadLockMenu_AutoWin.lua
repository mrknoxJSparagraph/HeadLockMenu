-- AutoWin installer. Embedded in the core; dependencies use existing menu logic.
return function(SC,ctx)
local Players,Run,player=ctx.Players,ctx.Run,ctx.player
local aw=SC.autoWin
aw.skipped={}; aw.objects=setmetatable({},{__mode="kv"}); aw.arguments=setmetatable({},{__mode="k"})
aw.hooks={}; aw.watches={}; aw.generation=0; aw.nextShot=0; aw.nextEquip=0; aw.status="OFF"
local function report(text)
    if aw.status==text then return end
    aw.status=text
    if aw.update then aw.update() end
end
function SC.recordWeapon(object,args)
    if type(object)~="table" then return end
    local tool=rawget(object,"instance")
    if typeof(tool)~="Instance" or not tool:IsA("Tool") or tool.Name~="M1911" then return end
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
            -- Observe methods the equipped weapon already calls. Preserve their
            -- original arguments/return values, including constructor results.
            for _,name in ipairs({"new","equip","equipped","on_equipped","update_ammo_gui","play_animation","fire"}) do
                local original=rawget(module,name)
                if type(original)=="function" then
                    local wrapper=function(self,...)
                        SC.recordWeapon(self,name=="fire" and table.pack(...) or nil)
                        local results=table.pack(original(self,...))
                        for i=1,results.n do SC.recordWeapon(results[i]) end
                        return table.unpack(results,1,results.n)
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
    if now<(aw.nextObjectScan or 0) or type(getgc)~="function" then return end
    aw.nextObjectScan=now+2
    local ok,objects=pcall(getgc,true)
    if ok and type(objects)=="table" then
        for _,candidate in ipairs(objects) do
            if type(candidate)=="table" and rawget(candidate,"instance")==tool then
                local valid,fire=pcall(function()return candidate.fire end)
                if valid and type(fire)=="function" then SC.recordWeapon(candidate); return candidate end
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
    aw.role=nil; aw.target=nil
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
    local aim=targetRoot.Position+Vector3.new(0,1,0)
    local position=targetRoot.Position-targetRoot.CFrame.LookVector*3+Vector3.new(0,.5,0)
    c:PivotTo(CFrame.lookAt(position,aim)*r.CFrame:ToObjectSpace(c:GetPivot()))
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
    if tool.Parent~=c and now>=aw.nextEquip then
        aw.nextEquip=now+.5
        h:EquipTool(tool)
    elseif tool.Parent==c and not aw.objects[tool] and now>=aw.nextEquip then
        -- Hooks installed after an existing equip need one fresh equip event.
        aw.nextEquip=now+2
        if backpack then h:UnequipTools(); h:EquipTool(tool) end
    end
    if tool.Parent~=c then return end
    return tool
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
    local now=os.clock()
    local tool=equipPistol(mine,h,now)
    if not tool then return end
    local object=findWeaponObject(tool,now)
    if not object then report("Waiting for equipped M1911 controller..."); return end
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
            object:fire(table.unpack(args,1,args.n))
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
    for p in pairs(aw.watches) do unwatchPlayer(p) end
    Run:UnbindFromRenderStep("HeadLockMenuAutoWinFollow")
    Run:UnbindFromRenderStep("HeadLockMenuAutoWinAim")
end
function aw.draw(panel)
    local make,button=ctx.make,ctx.button
    make("TextLabel",{Size=UDim2.new(1,0,0,30),BackgroundTransparency=1,Text="AutoWin",TextColor3=ctx.white,
        Font=Enum.Font.Code,TextSize=20,TextXAlignment=Enum.TextXAlignment.Left},panel)
    local toggle=button("OFF",panel); toggle.Name="AutoWinToggle"; toggle.Position=UDim2.fromOffset(0,38); toggle.Size=UDim2.fromOffset(105,38)
    local status=make("TextLabel",{Name="AutoWinStatus",Position=UDim2.fromOffset(0,82),Size=UDim2.new(1,0,0,40),
        BackgroundTransparency=1,Text=aw.status,TextWrapped=true,TextColor3=ctx.white,Font=Enum.Font.Code,TextSize=12,
        TextXAlignment=Enum.TextXAlignment.Left},panel)
    make("TextLabel",{Position=UDim2.fromOffset(0,126),Size=UDim2.new(1,0,0,24),BackgroundTransparency=1,
        Text="Skip auto kill on players:",TextColor3=ctx.white,Font=Enum.Font.Code,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left},panel)
    local names=button("Players",panel); names.Name="AutoWinPlayers"; names.Position=UDim2.fromOffset(0,154); names.Size=UDim2.new(1,-5,0,36)
    local list=make("ScrollingFrame",{Name="AutoWinPlayerList",Position=UDim2.fromOffset(0,198),Size=UDim2.new(1,0,1,-200),
        BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,CanvasSize=UDim2.fromOffset(0,0),Visible=aw.listOpen==true},panel)
    make("UIListLayout",{Padding=UDim.new(0,4),SortOrder=Enum.SortOrder.LayoutOrder},list)
    aw.update=function()
        if not toggle.Parent then return end
        toggle.Text=aw.enabled and "ON" or "OFF"
        toggle.BackgroundColor3=aw.enabled and ctx.white or ctx.black
        toggle.TextColor3=aw.enabled and ctx.black or ctx.white
        status.Text=aw.status
        list.Visible=aw.listOpen==true
        local count=0; for _,p in ipairs(Players:GetPlayers()) do if p~=player and aw.skipped[p.UserId] then count=count+1 end end
        names.Text="Players ("..count.." selected)"
    end
    aw.refreshPlayers=function()
        if not list.Parent then return end
        for _,child in ipairs(list:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
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
        end end
        list.CanvasSize=UDim2.fromOffset(0,count*38+4)
        aw.update()
    end
    toggle.Activated:Connect(function()SC.setAutoWin(not aw.enabled)end)
    names.Activated:Connect(function()aw.listOpen=not aw.listOpen; aw.update()end)
    aw.refreshPlayers(); aw.update()
end
return aw
end
