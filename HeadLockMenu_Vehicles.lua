-- Integrated vehicle installer; embedded in the core at build time.
return function(SC)
local Players=game:GetService('Players')
local Run=game:GetService('RunService')
local UIS=game:GetService('UserInputService')
local Http=game:GetService('HttpService')
local player=Players.LocalPlayer
local api={paused=false}
for _,key in ipairs({'ClassicJeepCleanup','LocalYellowCarCleanup','VehicleGarageCleanup'}) do
    if type(_G[key])=='function' then pcall(_G[key]) end
end
local CONFIG={Car=1269895074,Bike=719165150,Speed=80,Reverse=28,Acceleration=62,ReverseAcceleration=52,Brake=90,Coast=12,Turning=2}
local settingSpecs={
    {key='Speed',label='TOP SPEED',min=1,max=300,step=1},
    {key='Turning',label='TURN TIGHTNESS',min=.2,max=6,step=.05},
    {key='Acceleration',label='FORWARD ACCELERATION',min=5,max=200,step=1},
    {key='ReverseAcceleration',label='REVERSE ACCELERATION',min=5,max=200,step=1},
    {key='Reverse',label='REVERSE TOP SPEED',min=1,max=150,step=1},
    {key='Brake',label='BRAKING STRENGTH',min=10,max=250,step=1},
}
local settingsFile='LocalVehicleGarage_Settings.json'
local buttonsVisible=true
local function acceptSettings(saved)
    if type(saved)~='table' then return end
    for _,spec in ipairs(settingSpecs) do
        local value=saved[spec.key]
        if type(value)=='number' and value==value then CONFIG[spec.key]=math.clamp(value,spec.min,spec.max) end
    end
    if type(saved.ButtonsVisible)=='boolean' then buttonsVisible=saved.ButtonsVisible end
end
acceptSettings(_G.VehicleGarageSettings)
if type(readfile)=='function' and type(isfile)=='function' then
    pcall(function() if isfile(settingsFile) then acceptSettings(Http:JSONDecode(readfile(settingsFile))) end end)
end
local function saveSettings()
    local saved={ButtonsVisible=buttonsVisible}
    for _,spec in ipairs(settingSpecs) do saved[spec.key]=CONFIG[spec.key] end
    _G.VehicleGarageSettings=saved
    if type(writefile)=='function' then pcall(function() writefile(settingsFile,Http:JSONEncode(saved)) end) end
end
local UP=Vector3.new(0,1,0)
local ZERO=Vector3.zero
local folder=Instance.new('Folder'); folder.Name='LocalVehicleGarage'; folder.Parent=workspace
local gui=Instance.new('ScreenGui')
gui.Name='VehicleGarageUI'; gui.ResetOnSpawn=false; gui.IgnoreGuiInset=false; gui.DisplayOrder=9999
gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; gui.Parent=player:WaitForChild('PlayerGui')
local connections={}
local function listen(signal,fn)
    local c=signal:Connect(fn); table.insert(connections,c); return c
end
local function make(class,parent,props)
    local o=Instance.new(class)
    if class=='TextButton' or class=='TextLabel' or class=='TextBox' then o.Font=Enum.Font.Code end
    for k,v in pairs(props or {}) do o[k]=v end
    o.Parent=parent; return o
end
local function round(o) make('UIStroke',o,{Color=Color3.new(1,1,1),Thickness=1,ApplyStrokeMode=Enum.ApplyStrokeMode.Border}) end
local layout={Gas={x=.87,y=.70,size=68},Brake={x=.76,y=.81,size=68},Left={x=.09,y=.73,size=68},Right={x=.20,y=.73,size=68}}
local function acceptLayout(saved)
    if type(saved)~='table' then return end
    for name,def in pairs(layout) do
        local p=saved[name]
        if type(p)=='table' and type(p.x)=='number' and type(p.y)=='number' and type(p.size)=='number'
            and p.x==p.x and p.y==p.y and p.size==p.size then
            def.x=math.clamp(p.x,.03,.97); def.y=math.clamp(p.y,.05,.95)
            def.size=math.clamp(p.size,44,118)
        end
    end
end
acceptLayout(_G.VehicleGarageLayout)
local layoutFile='LocalVehicleGarage_Controls.json'
if type(readfile)=='function' and type(isfile)=='function' then
    pcall(function() if isfile(layoutFile) then acceptLayout(Http:JSONDecode(readfile(layoutFile))) end end)
end
local vehicles={}
local active=nil
local held={Gas={},Brake={},Left={},Right={}}
local inputOwners={}
local controls={}
local body,status
local lastStatus="Spawn a vehicle, then walk onto its seat."
local menuLinks={}
local sliderViews={}
local function menuListen(signal,fn)
 local c=signal:Connect(fn); table.insert(menuLinks,c); return c
end
local sliderDrag=nil
local closed=false
local busy=false
local exitRide,deleteVehicle
local function resetHeld()
    for name in pairs(held) do
        held[name]={}
        if controls[name] then
            controls[name].BackgroundColor3=Color3.new(0,0,0)
            controls[name].TextColor3=Color3.new(1,1,1)
        end
    end
    inputOwners={}
end
local function isHeld(name) return next(held[name])~=nil end
local function viewport() return gui.AbsoluteSize end
local function refreshControl(name)
    local b=controls[name]; local l=layout[name]
    b.Size=UDim2.fromOffset(l.size,l.size)
    b.Position=UDim2.fromScale(l.x,l.y)
    b.BackgroundColor3=Color3.new(0,0,0)
    b.TextColor3=Color3.new(1,1,1)
    b.Visible=buttonsVisible and not api.paused
end
for _,name in ipairs({'Gas','Brake','Left','Right'}) do
    local b=make('TextButton',gui,{Name=name,AnchorPoint=Vector2.new(.5,.5),Text=string.upper(name),
        TextColor3=Color3.new(1,1,1),Font=Enum.Font.Code,TextSize=15,
        BackgroundTransparency=0,AutoButtonColor=false,Active=true,ZIndex=3})
    round(b); controls[name]=b; refreshControl(name)
    listen(b.InputBegan,function(input)
        if input.UserInputType~=Enum.UserInputType.Touch and input.UserInputType~=Enum.UserInputType.MouseButton1 then return end
        if active and buttonsVisible and not api.paused then
            held[name][input]=true; inputOwners[input]=name
            b.BackgroundColor3=Color3.new(1,1,1)
            b.TextColor3=Color3.new(0,0,0)
        end
    end)
end
local function report(message)
    lastStatus=message
    if status and status.Parent and not closed then status.Text=message end
end
local function menuButton(text,x,y,w,callback)
    local b=make('TextButton',body,{Text=text,Position=x==114 and UDim2.new(.5,0,0,y) or UDim2.fromOffset(x,y),Size=w==222 and UDim2.new(1,-8,0,34) or UDim2.new(.5,-8,0,34),
        BackgroundColor3=Color3.new(0,0,0),TextColor3=Color3.new(1,1,1),
        Font=Enum.Font.Code,TextSize=13,ZIndex=7})
    round(b); menuListen(b.Activated,callback); return b
end
local function refreshSlider(spec)
    local view=sliderViews[spec.key]
    if not view then return end
    local value=CONFIG[spec.key]
    local fraction=(value-spec.min)/(spec.max-spec.min)
    view.fill.Size=UDim2.fromScale(fraction,1)
    view.knob.Position=UDim2.fromScale(fraction,.5)
    view.entry.Text=spec.key=='Turning' and string.format('%.2fx',value) or tostring(math.floor(value+.5))
end
local function sliderAt(input)
    local item=sliderDrag and sliderViews[sliderDrag.key]
    if not item or not item.track.Parent then return end
    local spec=item.spec
    local fraction=math.clamp((input.Position.X-item.track.AbsolutePosition.X)/math.max(1,item.track.AbsoluteSize.X),0,1)
    CONFIG[spec.key]=math.clamp(math.floor((spec.min+fraction*(spec.max-spec.min))/spec.step+.5)*spec.step,spec.min,spec.max)
    refreshSlider(spec)
end
listen(UIS.InputChanged,function(input)
    if sliderDrag and (input==sliderDrag.input or (sliderDrag.input.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseMovement)) then
        sliderAt(input); return
    end
end)
listen(UIS.InputEnded,function(input)
    local name=inputOwners[input]
    if name then
        held[name][input]=nil; inputOwners[input]=nil
        if not isHeld(name) then refreshControl(name) end
    end
    if input.UserInputType==Enum.UserInputType.MouseButton1 then
        for key,owner in pairs(inputOwners) do
            if key.UserInputType==Enum.UserInputType.MouseButton1 then held[owner][key]=nil; inputOwners[key]=nil; refreshControl(owner) end
        end
    end
    if sliderDrag and (input==sliderDrag.input or input.UserInputType==Enum.UserInputType.MouseButton1) then
        sliderDrag=nil; if body and body.Parent then body.ScrollingEnabled=true end; saveSettings()
    end
end)
listen(UIS.WindowFocusReleased,function()
    resetHeld(); sliderDrag=nil; if body and body.Parent then body.ScrollingEnabled=true end
    for name in pairs(controls) do refreshControl(name) end
    saveSettings()
end)

local function character()
    local c=player.Character
    local h=c and c:FindFirstChildWhichIsA('Humanoid')
    local r=c and c:FindFirstChild('HumanoidRootPart')
    if not h or not r or h.Health<=0 then return end
    return c,h,r
end
local function weld(a,b)
    local w=Instance.new('WeldConstraint'); w.Part0=a; w.Part1=b; w.Parent=b; return w
end
-- Keep every player's avatar out of local vehicle collisions and ground probes.
local trackedCharacters={}
local function refreshGroundFilters()
    local exclusions={folder}
    for c in pairs(trackedCharacters) do table.insert(exclusions,c) end
    for _,v in ipairs(vehicles) do v.ray.FilterDescendantsInstances=exclusions end
end
local function protectAvatar(v,c)
    v.avatarContacts=v.avatarContacts or {}
    for _,p in ipairs(c:GetDescendants()) do
        if p:IsA('BasePart') and not v.avatarContacts[p] then
            local nc=make('NoCollisionConstraint',v.hull,{Part0=p,Part1=v.hull})
            v.avatarContacts[p]={constraint=nc,character=c}
        end
    end
end
local function trackCharacter(c)
    if trackedCharacters[c] then return end
    local record={}; trackedCharacters[c]=record
    for _,v in ipairs(vehicles) do protectAvatar(v,c) end
    record.added=listen(c.DescendantAdded,function(p)
        if p:IsA('BasePart') then
            for _,v in ipairs(vehicles) do
                if not v.dead then protectAvatar(v,c) end
            end
        end
    end)
    refreshGroundFilters()
end
local function untrackCharacter(c)
    local record=trackedCharacters[c]
    if record and record.added then record.added:Disconnect() end
    trackedCharacters[c]=nil
    for _,v in ipairs(vehicles) do
        for p,entry in pairs(v.avatarContacts or {}) do
            if entry.character==c then entry.constraint:Destroy(); v.avatarContacts[p]=nil end
        end
    end
    refreshGroundFilters()
end
local function watchPlayer(p)
    listen(p.CharacterAdded,trackCharacter)
    listen(p.CharacterRemoving,untrackCharacter)
    if p.Character then trackCharacter(p.Character) end
end
for _,p in ipairs(Players:GetPlayers()) do watchPlayer(p) end
listen(Players.PlayerAdded,watchPlayer)
listen(Players.PlayerRemoving,function(p) if p.Character then untrackCharacter(p.Character) end end)

local cameraBinding='VehicleGarageCamera_'..tostring(player.UserId or 0)
Run:BindToRenderStep(cameraBinding,Enum.RenderPriority.Camera.Value-1,function(dt)
    local v=active
    if not v or not v.driver or not v.driver.cameraAnchor or v.dead then return end
    local driver=v.driver
    local desired=(v.seat.CFrame*CFrame.new(0,v.seat.Size.Y/2+3,0)).Position
    local velocity=v.hull:GetVelocityAtPosition(desired)
    local alpha=1-math.exp(-22*math.min(dt,.1))
    driver.cameraPosition=driver.cameraPosition:Lerp(desired+velocity*.025,alpha)
    driver.cameraAnchor.CFrame=CFrame.new(driver.cameraPosition)
end)

local function beginRide(v,c,h,r)
    if active or v.dead or api.paused then return end
    if SC.autoWin and SC.autoWin.enabled then SC.setAutoWin(false) end
    SC.stopConflictingMovement()
    SC.gravity.enabled=false; SC.stopGravity()
    -- The disabled Seat is only a contact trigger. It must never create a
    -- SeatWeld, which merges the character with the client-only vehicle.
    v.seat.Disabled=true
    local stale=v.seat:FindFirstChild('SeatWeld')
    if stale then stale:Destroy() end
    active=v
    v.driver={char=c,hum=h,root=r,auto=h.AutoRotate,assemblyRoot=r.AssemblyRootPart}
    h.AutoRotate=false
    h.Sit=true
    protectAvatar(v,c)
    local attachment=make('Attachment',r,{Name='GarageDriverAttachment'})
    local target=v.seat.CFrame*CFrame.new(0,v.seat.Size.Y/2+1.5,0)
    local mass=math.max(r.AssemblyMass,1)
    -- OneAttachment mode uses a WORLD target, not an attachment on the car.
    -- Neither this constraint nor the orientation constraint connects the
    -- driver's physics mechanism to any client-created vehicle part.
    local follow=make('AlignPosition',r,{
        Name='GarageDriverFollow',Attachment0=attachment,
        Mode=Enum.PositionAlignmentMode.OneAttachment,Position=target.Position,
        ApplyAtCenterOfMass=true,ReactionForceEnabled=false,RigidityEnabled=false,
        ForceLimitMode=Enum.ForceLimitMode.Magnitude,MaxForce=mass*4000,
        MaxVelocity=500,Responsiveness=60})
    local facing=make('AlignOrientation',r,{
        Name='GarageDriverFacing',Attachment0=attachment,
        Mode=Enum.OrientationAlignmentMode.OneAttachment,AlignType=Enum.AlignType.AllAxes,
        CFrame=target.Rotation,ReactionTorqueEnabled=false,RigidityEnabled=false,
        MaxTorque=mass*40000,MaxAngularVelocity=16,Responsiveness=50})
    v.driver.follow=follow; v.driver.facing=facing
    v.driver.objects={follow,facing,attachment}
    local camera=workspace.CurrentCamera
    if camera then
        local anchor=make('Part',folder,{Name='SmoothVehicleCamera',Size=Vector3.new(.1,.1,.1),
            CFrame=CFrame.new(target.Position+UP*1.5),Anchored=true,Transparency=1,
            CanCollide=false,CanTouch=false,CanQuery=false})
        v.driver.camera=camera; v.driver.previousSubject=camera.CameraSubject
        v.driver.cameraAnchor=anchor; v.driver.cameraPosition=anchor.Position
        table.insert(v.driver.objects,anchor)
        camera.CameraSubject=anchor
    end
    resetHeld()
    report('Driving '..v.kind..'. Jump exits. Character moves independently.')
end
exitRide=function()
    local v=active; if not v then return end
    active=nil; resetHeld(); v.lastExit=os.clock()
    local driver=v.driver; v.driver=nil
    if driver then
        if driver.camera and driver.camera.CameraSubject==driver.cameraAnchor then
            driver.camera.CameraSubject=(driver.previousSubject and driver.previousSubject.Parent) and driver.previousSubject or driver.hum
        end
        for _,obj in ipairs(driver.objects or {}) do obj:Destroy() end
    end
    local sw=v.seat:FindFirstChild('SeatWeld'); if sw then sw:Destroy() end
    v.seat.Disabled=true
    if driver and driver.hum.Parent then
        driver.hum.AutoRotate=driver.auto; driver.hum.Sit=false
        driver.hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end
    local constraints=v.driverConstraints; v.driverConstraints={}
    task.delay(.8,function()
        for _,n in ipairs(constraints) do n:Destroy() end
        -- Keep the contact seat disabled: no native SeatWeld should be created.
    end)
    report('Exited. Walk onto any vehicle seat to drive.')
end
listen(UIS.JumpRequest,exitRide)
listen(UIS.InputBegan,function(input,processed)
    if not processed and input.KeyCode==Enum.KeyCode.Space then exitRide() end
end)
listen(player.CharacterRemoving,exitRide)
local function bounds(entries,ref)
    local lo=Vector3.new(math.huge,math.huge,math.huge)
    local hi=Vector3.new(-math.huge,-math.huge,-math.huge)
    for _,p in ipairs(entries) do
        for _,x in ipairs({-1,1}) do for _,y in ipairs({-1,1}) do for _,z in ipairs({-1,1}) do
            local q=ref:PointToObjectSpace(p.CFrame:PointToWorldSpace(p.Size*Vector3.new(x,y,z)/2))
            lo=Vector3.new(math.min(lo.X,q.X),math.min(lo.Y,q.Y),math.min(lo.Z,q.Z))
            hi=Vector3.new(math.max(hi.X,q.X),math.max(hi.Y,q.Y),math.max(hi.Z,q.Z))
        end end end
    end
    return lo,hi
end
local function nearbySpawn(c,r,extent,averageRadius,lo,hi,origin,yawLook)
-- Try only the nearest front/right/left/rear slots. Never grow
-- a serial grid that pushes later spawns away from the character.
local right=Vector3.new(-yawLook.Z,0,yawLook.X)
local ahead=math.max(5,extent.Z/2+3)
local beside=math.max(4,extent.X/2+3)
local rp=RaycastParams.new(); rp.FilterType=Enum.RaycastFilterType.Exclude
local exclusions={folder}
for tracked in pairs(trackedCharacters) do table.insert(exclusions,tracked) end
rp.FilterDescendantsInstances=exclusions; rp.RespectCanCollide=true
local overlap=OverlapParams.new(); overlap.FilterType=Enum.RaycastFilterType.Exclude
local ignored={c}
for tracked in pairs(trackedCharacters) do table.insert(ignored,tracked) end
overlap.FilterDescendantsInstances=ignored; overlap.RespectCanCollide=true
local spawnCF
for _,offset in ipairs({yawLook*ahead,right*beside,-right*beside,-yawLook*ahead}) do
    local candidate=r.Position+offset
    local floor=workspace:Raycast(candidate+UP*6,-UP*16,rp)
    if floor and floor.Normal.Y>.4 then
        candidate=Vector3.new(candidate.X,floor.Position.Y+averageRadius*1.5+.25,candidate.Z)
        local cf=CFrame.lookAt(candidate,candidate+yawLook)
        local geometryOffset=(lo+hi)/2-origin
        local box=cf*CFrame.new(geometryOffset+UP*.2)
        local clear=true
        for _,part in ipairs(workspace:GetPartBoundsInBox(box,Vector3.new(extent.X+.3,math.max(.5,extent.Y-.4),extent.Z+.3),overlap)) do
            if part.CanCollide then clear=false; break end
        end
        if clear then spawnCF=cf; break end
    end
end
assert(spawnCF,'No clear space beside you. Move a few steps and try again.')
return spawnCF,rp
end
local function newVehicle(kind)
    if busy then return end
    local c,h,r=character(); if not c then report('Spawn your character first.'); return end
    busy=true; report('Loading '..kind..'…')
    task.spawn(function()
        local model
        local success,err=pcall(function()
            local objects=game:GetObjects('rbxassetid://'..CONFIG[kind])
            model=objects and objects[1]
            if closed then if model then model:Destroy() end; return end
            assert(model,'Asset loader returned no model.')
            assert(player.Character==c and h.Parent and h.Health>0,'Your character changed while loading. Spawn the vehicle again.')
            if not model:IsA('Model') then
                local wrapper=Instance.new('Model'); model.Parent=wrapper; model=wrapper
            end
            local sourceSeat=model:FindFirstChildWhichIsA('VehicleSeat',true) or model:FindFirstChildWhichIsA('Seat',true)
            assert(sourceSeat,'Model has no seat; cannot determine its forward direction.')
            local ref=sourceSeat.CFrame
            local originalParts,visibleParts,wheelParts={},{},{}
            for _,p in ipairs(model:GetDescendants()) do
                if p:IsA('BasePart') then
                    p.Anchored=true; table.insert(originalParts,p)
                    if p.Transparency<.95 then table.insert(visibleParts,p) end
                    local ancestor=p; local wheel=false
                    while ancestor and ancestor~=model do
                        local name=string.lower(ancestor.Name)
                        if string.find(name,'wheel',1,true) or string.find(name,'tire',1,true) or string.find(name,'tyre',1,true) or (name=='rim' or string.match(name,'^rim[%s_%-%.%d]')) then wheel=true end
                        ancestor=ancestor.Parent
                    end
                    if wheel and p.Transparency<.95 then table.insert(wheelParts,p) end
                end
            end
            assert(#visibleParts>0,'No visible geometry in this model.')
            for _,p in ipairs(model:GetDescendants()) do
                if p:IsA('LuaSourceContainer') or p:IsA('JointInstance') or p:IsA('Constraint') or p:IsA('BodyMover') then p:Destroy() end
            end
            local lo,hi=bounds(visibleParts,ref); local extent=hi-lo
            -- Preserve the downloaded geometry; classify only likely road wheels.
            local groups=kind=='Bike' and {{},{}} or {{},{},{},{}}
            local midZ=(lo.Z+hi.Z)/2
            local wheelSet={}
            for _,p in ipairs(wheelParts) do
                local localPos=ref:PointToObjectSpace(p.Position)
                if localPos.Y<lo.Y+extent.Y*.55 then
                    local index=localPos.Z<midZ and 1 or 2
                    if kind=='Car' then index=(localPos.X<0 and 1 or 2)+(localPos.Z>midZ and 2 or 0) end
                    table.insert(groups[index],p); wheelSet[p]=true
                end
            end
            local wheelInfo={}; local averageY=0; local averageRadius=0
            for i,g in ipairs(groups) do
                local center,radius
                if #g>0 then
                    local a,b=bounds(g,ref); center=(a+b)/2
                    radius=math.clamp(math.max(b.Y-a.Y,b.Z-a.Z)/2,.65,2.3)
                else
                    radius=math.clamp(extent.Y*.18,.85,1.7)
                    local front=kind=='Bike' and i==1 or kind=='Car' and i<=2
                    center=Vector3.new(kind=='Bike' and (lo.X+hi.X)/2 or (i%2==1 and lo.X+radius*.35 or hi.X-radius*.35),lo.Y+radius,midZ+(front and -1 or 1)*extent.Z*.32)
                end
                wheelInfo[i]={position=center,radius=radius,parts=g}
                averageY=averageY+center.Y/#groups; averageRadius=averageRadius+radius/#groups
            end
            local origin=Vector3.new((lo.X+hi.X)/2,averageY+averageRadius*.5,midZ)
            local chassisRef=ref*CFrame.new(origin)
            local yawLook=r.CFrame.LookVector; yawLook=Vector3.new(yawLook.X,0,yawLook.Z)
            yawLook=yawLook.Magnitude>.01 and yawLook.Unit or Vector3.new(0,0,-1)
            local spawnCF,rp=nearbySpawn(c,r,extent,averageRadius,lo,hi,origin,yawLook)
            local hull=make('Part',model,{Name='StableChassis',Size=Vector3.new(math.max(kind=='Bike' and 1.2 or 2.5,extent.X*.70),.8,math.max(3,extent.Z*.70)),
                CFrame=spawnCF,Transparency=1,Anchored=true,CanCollide=true,CanTouch=false,RootPriority=-127,
                CustomPhysicalProperties=PhysicalProperties.new(2,.15,0,100,100)})
            local v={model=model,hull=hull,kind=kind,wheels={},links={},driverConstraints={},lastExit=-10,
                heading=math.atan2(-yawLook.X,-yawLook.Z),steer=0,dead=false,ray=rp,normal=UP}
            model.PrimaryPart=hull; model.Name='Local'..kind
            -- Replace VehicleSeat with a passive Seat so the native mobile vehicle
            -- controller never injects a competing throttle or steering signal.
            local seatCF=chassisRef:ToObjectSpace(sourceSeat.CFrame); local seatSize=sourceSeat.Size
            sourceSeat.Transparency=1; sourceSeat.CanTouch=false
            local seat=make('Seat',model,{Name='DriverSeat',Size=seatSize,CFrame=spawnCF*seatCF,
                Transparency=1,Anchored=true,CanCollide=false,CanTouch=true,Massless=true,Disabled=true})
            v.seat=seat; weld(hull,seat)
            for _,p in ipairs(originalParts) do
                local localCF=chassisRef:ToObjectSpace(p.CFrame)
                p.CFrame=spawnCF*localCF; p.CanCollide=false; p.CanTouch=false; p.CanQuery=false; p.Massless=true; p.RootPriority=-127
                if p:IsA('Seat') or p:IsA('VehicleSeat') then p.Disabled=true end
                if not wheelSet[p] then weld(hull,p) end
            end
            for i,w in ipairs(wheelInfo) do
                local pos=w.position-origin
                local mount=make('Attachment',hull,{Position=pos+UP*1.2})
                local force=make('VectorForce',hull,{Attachment0=mount,RelativeTo=Enum.ActuatorRelativeTo.World,Force=ZERO,ApplyAtCenterOfMass=false})
                local wheel={mount=mount,force=force,position=pos,radius=w.radius,rest=1.2,travel=2.7,angle=0,joints={},height=0,front=kind=='Bike' and i==1 or kind=='Car' and i<=2}
                for _,p in ipairs(w.parts) do
                    local original=spawnCF:ToObjectSpace(p.CFrame)
                    local joint=make('Motor6D',hull,{Name='VisualWheel',Part0=hull,Part1=p,C0=CFrame.new(pos),C1=original:Inverse()*CFrame.new(pos)})
                    table.insert(wheel.joints,joint)
                end
                table.insert(v.wheels,wheel)
            end
            local att=make('Attachment',hull)
            v.drive=make('VectorForce',hull,{Attachment0=att,RelativeTo=Enum.ActuatorRelativeTo.World,ApplyAtCenterOfMass=true,Force=ZERO})
            v.balance=make('AlignOrientation',hull,{Attachment0=att,Mode=Enum.OrientationAlignmentMode.OneAttachment,
                AlignType=Enum.AlignType.AllAxes,Responsiveness=20,MaxAngularVelocity=12,MaxTorque=100000,RigidityEnabled=false,CFrame=spawnCF.Rotation})
            model.Parent=folder
            for _,p in ipairs(model:GetDescendants()) do if p:IsA('BasePart') then p.Anchored=false end end
            table.insert(vehicles,v)
            for c in pairs(trackedCharacters) do protectAvatar(v,c) end
            refreshGroundFilters()
            local function on(signal,fn) local connection=signal:Connect(fn); table.insert(v.links,connection) end
            on(seat.Touched,function(hit)
                local cc,hh,rr=character()
                if not cc or active or v.dead or os.clock()-v.lastExit<1 or not hit:IsDescendantOf(cc) then return end
                if (rr.Position-seat.Position).Magnitude>6 then return end
                beginRide(v,cc,hh,rr)
            end)
            report(kind..' spawned. '..#vehicles..' total. Walk onto its seat.')
        end)
        if not success then if model then model:Destroy() end; report('Load failed: '..string.sub(tostring(err),1,150)) end
        busy=false
    end)
end
deleteVehicle=function(v)
    if not v or v.dead then return end
    if active==v then exitRide() end
    v.dead=true
    for _,c in ipairs(v.links) do c:Disconnect() end
    v.model:Destroy()
    for i,item in ipairs(vehicles) do if item==v then table.remove(vehicles,i); break end end
end
local function longitudinalAcceleration(speed,gas,brake,driven)
    local target,rate=0,CONFIG.Coast
    if driven then
        if brake then
            -- Holding BRAKE crosses smoothly through zero into reverse.
            target=-CONFIG.Reverse
            rate=speed>.15 and CONFIG.Brake or CONFIG.ReverseAcceleration
            if gas then target=0; rate=CONFIG.Brake end
        elseif gas then
            target=CONFIG.Speed
            rate=speed<-.15 and CONFIG.Brake or CONFIG.Acceleration
        end
    else rate=CONFIG.Brake end
    -- Acceleration is applied to actual measured speed immediately.
    -- No target-speed ramp followed by a second slow response filter.
    local driveAcceleration=math.clamp((target-speed)*14,-rate,rate)
    return driveAcceleration
end
local function inputs()
    local gas,brake=isHeld('Gas'),isHeld('Brake')
    local turn=(isHeld('Right') and 1 or 0)-(isHeld('Left') and 1 or 0)
    if not UIS:GetFocusedTextBox() then
        gas=gas or UIS:IsKeyDown(Enum.KeyCode.W) or UIS:IsKeyDown(Enum.KeyCode.Up)
        brake=brake or UIS:IsKeyDown(Enum.KeyCode.S) or UIS:IsKeyDown(Enum.KeyCode.Down)
        if UIS:IsKeyDown(Enum.KeyCode.A) or UIS:IsKeyDown(Enum.KeyCode.Left) then turn=turn-1 end
        if UIS:IsKeyDown(Enum.KeyCode.D) or UIS:IsKeyDown(Enum.KeyCode.Right) then turn=turn+1 end
    end
    if api.paused then return false,false,0 end
    return gas,brake,math.clamp(turn,-1,1)
end
local function sampleGround(v,wheel,origin)
    local probeRadius=wheel.radius*.8
    local extra=wheel.radius-probeRadius
    local hit=workspace:Spherecast(origin,probeRadius,-UP*(wheel.travel+extra),v.ray)
    if hit and hit.Normal.Y>.35 then return hit,hit.Distance-extra end
    -- Spherecasts miss surfaces overlapping the starting sphere. A raised ray
    -- keeps suspension support when a wheel is briefly compressed into a step.
    local raise=wheel.radius*1.25
    hit=workspace:Raycast(origin+UP*raise,-UP*(wheel.travel+raise+wheel.radius),v.ray)
    if hit and hit.Normal.Y>.35 then
        return hit,hit.Distance-raise-wheel.radius
    end
    return nil,wheel.travel
end
local lastError=0
listen(Run.PreSimulation,function(dt)
    dt=math.min(dt,.05)
    local cc,hh=character()
    if active and (api.paused or not hh or active.driver.hum~=hh or (SC.autoWin and SC.autoWin.enabled)) then exitRide() end
    if active and hh then
        -- Ignore the mobile walking stick while driving. Touch buttons supply
        -- independent inputs, so native walking controls cannot fight the seat.
        hh:Move(ZERO,false)
        local v=active
        local driver=v.driver
        local target=v.seat.CFrame*CFrame.new(0,v.seat.Size.Y/2+1.5,0)
        driver.follow.Position=target.Position+v.hull:GetVelocityAtPosition(target.Position)*math.min(dt,.025)*.5
        driver.follow.MaxVelocity=math.max(500,CONFIG.Speed*2)
        driver.facing.CFrame=target.Rotation
    end
    local gas,brake,turn=inputs()
    for _,v in ipairs(vehicles) do
        if not v.dead and v.model.Parent then
            local success,err=pcall(function()
                local hull=v.hull; local cf=hull.CFrame
                local mass=hull.AssemblyMass
                if mass==math.huge or mass<=0 then return end
                local forward=cf.LookVector; local lateral=cf.RightVector
                local velocity=hull.AssemblyLinearVelocity
                local speed=velocity:Dot(forward)
                local driven=active==v
                local driveAcceleration=longitudinalAcceleration(speed,gas,brake,driven)
                v.steer=v.steer+((driven and turn or 0)-v.steer)*(1-math.exp(-24*dt))
                local support=0; local normalSum=ZERO
                for _,wheel in ipairs(v.wheels) do
                    local origin=wheel.mount.WorldPosition
                    local hit,distance=sampleGround(v,wheel,origin)
                    if hit then
                        local quarterMass=mass/#v.wheels
                        local stiffness=quarterMass*workspace.Gravity/1.1
                        local damping=2*math.sqrt(stiffness*quarterMass)*.9
                        local pointVelocity=hull:GetVelocityAtPosition(origin):Dot(UP)
                        local load=quarterMass*workspace.Gravity+(wheel.rest-distance)*stiffness-pointVelocity*damping
                        wheel.force.Force=UP*math.clamp(load,0,quarterMass*workspace.Gravity*3.5)
                        support=support+1; normalSum=normalSum+hit.Normal
                    else wheel.force.Force=ZERO end
                    wheel.height=wheel.height+(math.clamp(wheel.rest-distance,-1.2,1.2)-wheel.height)*(1-math.exp(-14*dt))
                    wheel.angle=(wheel.angle+speed/wheel.radius*dt)%(math.pi*2)
                    -- The wheel hub has the vehicle's axes, so rotation is applied
                    -- about its actual axle, independent of each mesh's orientation.
                    local steerAngle=wheel.front and -v.steer*math.rad(math.clamp(18+CONFIG.Turning*8,18,58))/(1+math.abs(speed)/140) or 0
                    for _,joint in ipairs(wheel.joints) do
                        joint.Transform=CFrame.new(0,wheel.height,0)*CFrame.Angles(0,steerAngle,0)*CFrame.Angles(wheel.angle,0,0)
                    end
                end
                if support>0 then
                    local raw=normalSum.Unit
                    local slope=Vector3.new(raw.X*.65,math.max(.75,raw.Y),raw.Z*.65).Unit
                    v.normal=v.normal:Lerp(slope,1-math.exp(-5*dt)).Unit
                    local yawRate=-v.steer*math.clamp(speed/7,-1,1)*2*CONFIG.Turning/(1+math.abs(speed)/140)
                    v.heading=v.heading+yawRate*dt
                    local gripLimit=100+CONFIG.Turning*70
                    local grip=math.clamp(-velocity:Dot(lateral)*(10+CONFIG.Turning*2),-gripLimit,gripLimit)
                    local traction=(forward*driveAcceleration+lateral*grip)*mass
                    v.drive.Force=traction*math.min(1,support/2)
                else
                    v.drive.Force=ZERO
                    v.normal=v.normal:Lerp(UP,1-math.exp(-2*dt)).Unit
                end
                local facing=Vector3.new(-math.sin(v.heading),0,-math.cos(v.heading))
                local tangent=facing-v.normal*facing:Dot(v.normal)
                if tangent.Magnitude>.01 then v.balance.CFrame=CFrame.lookAt(ZERO,tangent.Unit,v.normal) end
                v.balance.MaxTorque=mass*workspace.Gravity*math.max(5,hull.Size.Z)*2
            end)
            if not success and os.clock()-lastError>3 then
                lastError=os.clock(); report('Vehicle error: '..string.sub(tostring(err),1,130)); warn(err)
            end
        end
    end
end)
function api.cleanup()
    if closed then return end
    while #vehicles>0 do deleteVehicle(vehicles[#vehicles]) end
    api.unmount()
    closed=true
    Run:UnbindFromRenderStep(cameraBinding)
    for _,c in ipairs(connections) do c:Disconnect() end
    folder:Destroy(); gui:Destroy(); _G.VehicleGarageCleanup=nil
end


function api.unmount()
    if sliderDrag then saveSettings() end
    sliderDrag=nil; sliderViews={}
    for _,c in ipairs(menuLinks) do c:Disconnect() end
    table.clear(menuLinks)
    body=nil; status=nil
end
function api.setPaused(value)
    api.paused=value==true
    if api.paused then exitRide() end
    resetHeld()
    for name in pairs(controls) do refreshControl(name) end
end
function api.draw(container)
    api.unmount()
    body=make('ScrollingFrame',container,{Name='VehicleSettings',Size=UDim2.fromScale(1,1),
        BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,
        CanvasSize=UDim2.fromOffset(0,802),ScrollingDirection=Enum.ScrollingDirection.Y,Active=true})
    make('TextLabel',body,{Size=UDim2.new(1,0,0,30),BackgroundTransparency=1,Text='Vehicles',
        TextColor3=Color3.new(1,1,1),Font=Enum.Font.Code,TextSize=20,TextXAlignment=Enum.TextXAlignment.Left})
    menuButton('Spawn Car',0,40,222,function() newVehicle('Car') end)
    menuButton('Spawn Motorcycle',0,82,222,function() newVehicle('Bike') end)
    menuButton('Delete One',0,124,108,function()
        deleteVehicle(active or vehicles[#vehicles]); report(#vehicles..' vehicles remaining.')
    end)
    menuButton('Delete All',114,124,108,function()
        while #vehicles>0 do deleteVehicle(vehicles[#vehicles]) end
        report('All spawned vehicles deleted.')
    end)
    menuButton('Exit Vehicle',0,166,222,exitRide)
local toggle
local function toggleText() toggle.Text=buttonsVisible and 'Controls: ON' or 'Controls: OFF' end
toggle=menuButton('Controls',0,210,222,function()
    buttonsVisible=not buttonsVisible; resetHeld()
    for name in pairs(controls) do refreshControl(name) end
    toggleText(); saveSettings()
    report(buttonsVisible and 'Driving buttons shown.' or 'Driving buttons hidden. Keyboard controls still work.')
end)
toggleText()
for index,spec in ipairs(settingSpecs) do
    local y=258+(index-1)*82
    make('TextLabel',body,{Position=UDim2.fromOffset(0,y),Size=UDim2.new(1,-78,0,20),BackgroundTransparency=1,
        Text=spec.label,TextXAlignment=Enum.TextXAlignment.Left,TextColor3=Color3.new(1,1,1),TextSize=11,Font=Enum.Font.Code,ZIndex=7})
    local entry=make('TextBox',body,{Name=spec.key..'Value',Position=UDim2.new(1,-70,0,y-2),Size=UDim2.fromOffset(58,24),
        BackgroundColor3=Color3.new(0,0,0),TextColor3=Color3.new(1,1,1),TextSize=12,Font=Enum.Font.Code,
        ClearTextOnFocus=false,Text='',ZIndex=8})
    round(entry)
    -- A 34px touch target surrounds the thinner visible slider.
    local track=make('TextButton',body,{Name=spec.key..'Slider',Position=UDim2.fromOffset(4,y+24),Size=UDim2.new(1,-20,0,34),
        Text='',BackgroundTransparency=1,AutoButtonColor=false,Active=true,ZIndex=8})
    local rail=make('Frame',track,{Position=UDim2.fromScale(0,.4),Size=UDim2.fromScale(1,.2),BackgroundColor3=Color3.new(0,0,0),BorderSizePixel=0,ZIndex=8})
    round(rail)
    local fill=make('Frame',rail,{Size=UDim2.fromScale(0,1),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,ZIndex=8})
    round(fill)
    local knob=make('Frame',track,{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(0,.5),Size=UDim2.fromOffset(18,24),
        BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,ZIndex=9})
    round(knob)
    if spec.key=='Turning' then
        make('TextLabel',body,{Position=UDim2.fromOffset(4,y+58),Size=UDim2.new(1,-20,0,17),BackgroundTransparency=1,
            Text='WIDE     →     MEDIUM     →     VERY TIGHT',TextSize=9,Font=Enum.Font.Code,TextColor3=Color3.new(1,1,1),ZIndex=7})
    end
    sliderViews[spec.key]={spec=spec,track=track,fill=fill,knob=knob,entry=entry}
    refreshSlider(spec)
    menuListen(track.InputBegan,function(input)
        if input.UserInputType~=Enum.UserInputType.Touch and input.UserInputType~=Enum.UserInputType.MouseButton1 then return end
        sliderDrag={input=input,key=spec.key}; body.ScrollingEnabled=false; sliderAt(input)
    end)
    menuListen(entry.FocusLost,function()
        local value=tonumber((entry.Text:gsub('[xX]','')))
        if value and value==value then CONFIG[spec.key]=math.clamp(value,spec.min,spec.max) end
        refreshSlider(spec); saveSettings()
    end)
end

    status=make('TextLabel',body,{Name='VehicleStatus',Position=UDim2.fromOffset(0,754),Size=UDim2.new(1,-8,0,42),
        BackgroundTransparency=1,Text=lastStatus,TextWrapped=true,TextSize=12,
        Font=Enum.Font.Code,TextColor3=Color3.new(1,1,1),TextXAlignment=Enum.TextXAlignment.Left})
end
api.spawn=newVehicle
api.exit=exitRide
api.deleteAll=function() while #vehicles>0 do deleteVehicle(vehicles[#vehicles]) end end
api.settings=CONFIG
_G.VehicleGarageCleanup=api.cleanup
SC.vehicles=api
return api

end
