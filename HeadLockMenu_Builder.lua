return function(options)
options=options or{}
local Players=game:GetService('Players')
local UIS=game:GetService('UserInputService')
local Run=game:GetService('RunService')
local Http=game:GetService('HttpService')
local GuiService=game:GetService('GuiService')
local player=Players.LocalPlayer
local pg=player:WaitForChild('PlayerGui')
if type(_G.HeadLockTrackBuilderCleanup)=='function' then pcall(_G.HeadLockTrackBuilderCleanup)end
local api={version=6}
local ui={boxEnabled=true,trowelMode='Move',blocked={},currentTool='Move',brush={material='Concrete',color=Color3.fromRGB(110,110,110),transparency=0},tools={},toolListeners={}}
ui.settings=type(_G.HeadLockTrackBuilderSettings)=='table'and _G.HeadLockTrackBuilderSettings or{}
_G.HeadLockTrackBuilderSettings=ui.settings
local LIMIT=1500
local MIN,MAX=.05,2048
local PREFIX='HEADLOCK_TRACK_V1\n'
local backupFile='HeadLockTrack_Draft_v1.json'
local connections={}
local objects={}
local history,redo={},{}
local selected,drag,panelDrag
local selection={}
local multiSelect=true
local selectionBoxes={}
local circle={count=24,radius=20,sweep=360,axis='Y'}
local circleCenter,circleManual
local circleFields={}
local circleCenterButton,groupSizeLabel,circleAxisButton
local mode,shape,tab='Idle','Block','Build'
local moveStep,angleStep=1,15
local localAxes=ui.settings.localAxes~=false
local closed,minimized=false,false
local changed=false
local nextId=0
local blockWorldUntil=0
local lastTouch,lastTouchAt
local trackName='My track'
local white=Color3.new(1,1,1)
local black=Color3.new(0,0,0)
local gray=Color3.fromRGB(170,170,170)
local folder=workspace:FindFirstChild('HeadLockTrackDraft')
if not folder or not folder:IsA('Folder')then folder=Instance.new('Folder');folder.Name='HeadLockTrackDraft';folder.Parent=workspace end
local function connect(signal,fn)local c=signal:Connect(fn);table.insert(connections,c);return c end
local cameraLocks,cameraRecords={},{}
local frozenFrame,frozenFocus
local cameraBinding='HeadLockTrackBuilderCamera_'..tostring(player.UserId)
local function freezeCamera()
 local camera=workspace.CurrentCamera
 if not camera then return end
 if not cameraRecords[camera]then cameraRecords[camera]={kind=camera.CameraType}end
 if not frozenFrame then frozenFrame=camera.CFrame;frozenFocus=camera.Focus end
 camera.CameraType=Enum.CameraType.Scriptable
 camera.CFrame=frozenFrame;camera.Focus=frozenFocus
end
local function lockCamera(key)
 if closed then return end
 cameraLocks[key]=true;freezeCamera()
end
local function restoreCamera()
 for camera,saved in pairs(cameraRecords)do
  pcall(function()if camera.CameraType==Enum.CameraType.Scriptable then camera.CameraType=saved.kind end end)
 end
 table.clear(cameraRecords);frozenFrame=nil;frozenFocus=nil
end
local function unlockCamera(key)
 cameraLocks[key]=nil
 if not next(cameraLocks)then restoreCamera()end
end
local function unlockAllCamera()
 table.clear(cameraLocks);restoreCamera()
end
Run:BindToRenderStep(cameraBinding,Enum.RenderPriority.Camera.Value+1,function()
 if not closed and next(cameraLocks)then freezeCamera()end
end)
local function make(class,parent,props)
 local o=Instance.new(class)
 if o:IsA('GuiObject')then o.BorderSizePixel=0 end
 if class=='TextButton'or class=='TextLabel'or class=='TextBox'then o.Font=Enum.Font.Sarpanch;o.TextColor3=white;o.TextSize=13 end
 for k,v in pairs(props or {})do o[k]=v end
 o.Parent=parent;return o
end
local function stroke(o)make('UIStroke',o,{Color=white,Thickness=1,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})end
local function finite(n)return type(n)=='number'and n==n and math.abs(n)<1e8 end
local function number(text)local n=tonumber(text);if finite(n)then return n end end
local function snap(n,step)if step<=0 then return n end;return math.floor(n/step+.5)*step end
local function list(v)return {v.X,v.Y,v.Z}end
local function enumName(v)return v.Name end
local function vector(a)return Vector3.new(a[1],a[2],a[3])end
local function member(enum,name)local ok,v=pcall(function()return enum[name]end);if ok then return v end end
local classes={Part=true,WedgePart=true,CornerWedgePart=true}
local shapes={Block=true,Ball=true,Cylinder=true}
local surfaces={'TopSurface','BottomSurface','LeftSurface','RightSurface','FrontSurface','BackSurface'}
local function record(p)
 local data={id=p:GetAttribute('TrackPieceId'),class=p.ClassName,name=p.Name,size=list(p.Size),cf={p.CFrame:GetComponents()},
  color={p.Color.R,p.Color.G,p.Color.B},material=enumName(p.Material),materialVariant=p.MaterialVariant,
  transparency=p.Transparency,reflectance=p.Reflectance,canCollide=p.CanCollide,canTouch=p.CanTouch,canQuery=p.CanQuery,
  castShadow=p.CastShadow,anchored=true,surfaces={}}
 if p:IsA('Part')then data.shape=enumName(p.Shape)end
 for _,key in ipairs(surfaces)do data.surfaces[key]=enumName(p[key])end
 local phys=p.CustomPhysicalProperties
 if phys then data.physics={phys.Density,phys.Friction,phys.Elasticity,phys.FrictionWeight,phys.ElasticityWeight}end
 return data
end
local function count()local n=0;for _,p in pairs(objects)do if p.Parent==folder then n+=1 end end;return n end
local function exists(p)return p and p.Parent==folder and objects[p:GetAttribute('TrackPieceId')]==p end
local function selectionParts()
 local list={}
 for id in pairs(selection)do
  local part=objects[id]
  if exists(part)then selection[id]=part;table.insert(list,part)else selection[id]=nil end
 end
 table.sort(list,function(a,b)return a:GetAttribute('TrackPieceId')<b:GetAttribute('TrackPieceId')end)
 if not exists(selected)or not selection[selected:GetAttribute('TrackPieceId')]then selected=list[#list]end
 return list
end
local function groupBounds(parts,basis)
 parts=parts or selectionParts()
 if #parts==0 then return nil end
 if #parts==1 and not basis then return parts[1].CFrame,parts[1].Size end
 local ref=basis or(exists(selected)and selected or parts[#parts]).CFrame.Rotation
 local lo=Vector3.new(math.huge,math.huge,math.huge);local hi=-lo
 for _,part in ipairs(parts)do
  for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
   local corner=part.CFrame:PointToWorldSpace(Vector3.new(part.Size.X*x,part.Size.Y*y,part.Size.Z*z)/2)
   local v=ref:PointToObjectSpace(corner)
   lo=Vector3.new(math.min(lo.X,v.X),math.min(lo.Y,v.Y),math.min(lo.Z,v.Z));hi=Vector3.new(math.max(hi.X,v.X),math.max(hi.Y,v.Y),math.max(hi.Z,v.Z))
  end end end
 end
 return ref*CFrame.new((lo+hi)/2),hi-lo
end
local function snapshot(parts)
 local out={};for _,part in ipairs(parts)do out[part:GetAttribute('TrackPieceId')]=record(part)end;return out
end
local function newId()nextId+=1;return 'p_'..Http:GenerateGUID(false):gsub('[{}%-]','')..'_'..nextId end
local function normalize(doc)
 assert(type(doc)=='table'and doc.format=='HeadLockTrack'and doc.version==1,'Not a Track Builder export')
 assert(type(doc.parts)=='table'and #doc.parts<=LIMIT,'Track is too large')
 assert(doc.placeId==game.PlaceId,'This track belongs to a different map/place')
 local seen,out={},{}
 local function array(v,n,lo,hi)
  assert(type(v)=='table'and #v==n,'Invalid number array')
  local a={};for i=1,n do assert(finite(v[i])and v[i]>=lo and v[i]<=hi,'Value outside supported range');a[i]=v[i]end;return a
 end
 for _,raw in ipairs(doc.parts)do
  assert(type(raw)=='table'and classes[raw.class],'Unsupported part class')
  assert(type(raw.id)=='string'and #raw.id>0 and #raw.id<=100 and not seen[raw.id],'Duplicate or invalid piece ID');seen[raw.id]=true
  local cf=array(raw.cf,12,-1e7,1e7)
  for i=4,12 do assert(math.abs(cf[i])<=1.001,'Invalid rotation')end
  local r1=Vector3.new(cf[4],cf[5],cf[6]);local r2=Vector3.new(cf[7],cf[8],cf[9]);local r3=Vector3.new(cf[10],cf[11],cf[12])
  assert(math.abs(r1.Magnitude-1)<.002 and math.abs(r2.Magnitude-1)<.002 and math.abs(r3.Magnitude-1)<.002,'Invalid rotation')
  assert(math.abs(r1:Dot(r2))<.002 and math.abs(r1:Dot(r3))<.002 and math.abs(r2:Dot(r3))<.002 and r1:Cross(r2):Dot(r3)>.998,'Invalid rotation')
  local transparency=raw.transparency or 0;local reflectance=raw.reflectance or 0
  assert(finite(transparency)and transparency>=0 and transparency<=1 and finite(reflectance)and reflectance>=0 and reflectance<=1,'Invalid appearance')
  assert(type(raw.material)=='string'and member(Enum.Material,raw.material),'Unsupported material')
  if raw.class=='Part'then assert(shapes[raw.shape or 'Block'],'Unsupported shape')end
  local surf={};for _,key in ipairs(surfaces)do local s=raw.surfaces and raw.surfaces[key]or 'Smooth';assert(type(s)=='string'and member(Enum.SurfaceType,s),'Invalid surface');surf[key]=s end
  local phys=raw.physics and array(raw.physics,5,0,100)or nil
  if phys then assert(phys[1]>=.01 and phys[1]<=100 and phys[2]<=2 and phys[3]<=1,'Invalid physical properties')end
  table.insert(out,{id=raw.id,class=raw.class,name=tostring(raw.name or 'Track piece'):sub(1,80),size=array(raw.size,3,MIN,MAX),cf=cf,color=array(raw.color,3,0,1),
   shape=raw.shape or 'Block',material=raw.material,materialVariant=type(raw.materialVariant)=='string'and raw.materialVariant:sub(1,100)or '',
   transparency=transparency,reflectance=reflectance,canCollide=raw.canCollide~=false,canTouch=raw.canTouch==true,canQuery=raw.canQuery~=false,
   castShadow=raw.castShadow~=false,anchored=true,surfaces=surf,physics=phys})
 end
 return {format='HeadLockTrack',version=1,placeId=game.PlaceId,name=tostring(doc.name or 'My track'):sub(1,80),parts=out}
end
local function apply(id,data)
 local p=objects[id]
 if data==false then if p then p:Destroy();objects[id]=nil end;return end
 if p and p.ClassName~=data.class then p:Destroy();p=nil end
 if not p then p=Instance.new(data.class);objects[id]=p;p:SetAttribute('TrackPieceId',id)end
 p.Name=data.name;p.Anchored=true;p.Size=vector(data.size);p.CFrame=CFrame.new(table.unpack(data.cf));p.Color=Color3.new(table.unpack(data.color))
 p.Material=Enum.Material[data.material];p.MaterialVariant=data.materialVariant or '';p.Transparency=data.transparency;p.Reflectance=data.reflectance
 p.CanCollide=data.canCollide;p.CanTouch=data.canTouch;p.CanQuery=data.canQuery;p.CastShadow=data.castShadow
 if p:IsA('Part')then p.Shape=Enum.PartType[data.shape or 'Block']end
 for _,key in ipairs(surfaces)do p[key]=Enum.SurfaceType[data.surfaces and data.surfaces[key]or 'Smooth']end
 p.CustomPhysicalProperties=data.physics and PhysicalProperties.new(table.unpack(data.physics))or nil
 p.Parent=folder;return p
end
for _,p in ipairs(folder:GetChildren())do
 if p:IsA('BasePart')and classes[p.ClassName]then
  local id=p:GetAttribute('TrackPieceId')
  if type(id)~='string'or objects[id]then id=newId();p:SetAttribute('TrackPieceId',id)end
  p.Anchored=true;p.CanQuery=true;objects[id]=p
 end
end
local gui=make('ScreenGui',pg,{Name='HeadLockTrackBuilder',ResetOnSpawn=false,IgnoreGuiInset=false,DisplayOrder=10010,ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
local panel=make('Frame',gui,{Name='BuilderPanel',Position=UDim2.fromOffset(24,100),Size=UDim2.fromOffset(330,440),BackgroundColor3=black,Active=true});stroke(panel)
local scale=make('UIScale',panel,{Scale=1})
local title=make('TextButton',panel,{Text='TRACK BUILDER',TextXAlignment=Enum.TextXAlignment.Left,Position=UDim2.fromOffset(12,0),Size=UDim2.new(1,-90,0,36),BackgroundTransparency=1,AutoButtonColor=false})
local minimize=make('TextButton',panel,{Text='−',Position=UDim2.new(1,-74,0,0),Size=UDim2.fromOffset(36,36),BackgroundTransparency=1})
local close=make('TextButton',panel,{Text='×',Position=UDim2.new(1,-38,0,0),Size=UDim2.fromOffset(36,36),BackgroundTransparency=1})
local content=make('Frame',panel,{Position=UDim2.fromOffset(0,36),Size=UDim2.new(1,0,1,-36),BackgroundTransparency=1})
local toolbar=make('Frame',content,{Position=UDim2.fromOffset(10,0),Size=UDim2.new(1,-20,0,32),BackgroundTransparency=1})
local pages={};local tabs={}
local status=make('TextLabel',content,{Name='Status',Position=UDim2.new(0,12,1,-42),Size=UDim2.new(1,-24,0,34),BackgroundTransparency=1,Text='',TextColor3=gray,TextSize=11,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left})
local selectionText=make('TextLabel',content,{Position=UDim2.fromOffset(12,36),Size=UDim2.new(1,-24,0,28),BackgroundTransparency=1,Text='0 PIECES',TextXAlignment=Enum.TextXAlignment.Left,TextSize=12})
for i,name in ipairs({'Build','Edit','Style','Circle','Save'})do
 local b=make('TextButton',toolbar,{Text=string.upper(name),Position=UDim2.new((i-1)/5,0,0,0),Size=UDim2.new(.2,-3,1,0),TextSize=11,BackgroundColor3=black});stroke(b);tabs[name]=b
 local page=make('ScrollingFrame',content,{Name=name..'Page',Position=UDim2.fromOffset(10,106),Size=UDim2.new(1,-20,1,-154),CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=3,BackgroundTransparency=1,Visible=name=='Build',BorderSizePixel=0});pages[name]=page
end
local function tell(text)if not closed then status.Text=text end end
local refresh,selectPart,finishDrag,setTab
local function safe(fn)return function(...)local ok,err=pcall(fn,...);if not ok then tell(tostring(err):gsub('^.-:%d+: ',''):sub(1,140))end end end
local function button(parent,text,x,y,w,fn)
 local b=make('TextButton',parent,{Text=text,Position=UDim2.new(x,2,0,y),Size=UDim2.new(w,-4,0,32),BackgroundColor3=black,AutoButtonColor=true});stroke(b)
 if fn then connect(b.Activated,safe(fn))end;return b
end
local function label(parent,text,y)
 return make('TextLabel',parent,{Text=text,Position=UDim2.fromOffset(3,y),Size=UDim2.new(1,-6,0,22),BackgroundTransparency=1,TextColor3=gray,TextXAlignment=Enum.TextXAlignment.Left,TextSize=11})
end
local function field(parent,name,x,y,w,text,fn)
 local b=make('TextBox',parent,{Name=name,Text=text or '',PlaceholderText=name,ClearTextOnFocus=false,Position=UDim2.new(x,2,0,y),Size=UDim2.new(w,-4,0,31),BackgroundColor3=black,TextSize=13});stroke(b)
 if fn then connect(b.FocusLost,safe(function()fn(b.Text)end))end;return b
end
local box=make('SelectionBox',gui,{Color3=Color3.fromRGB(0,134,171),SurfaceColor3=Color3.fromRGB(0,134,171),SurfaceTransparency=.5,LineThickness=.04})
local handles,arcs
local gizmo=make('Part',workspace,{Name='TrackBuilderGizmo',Anchored=true,Transparency=1,CanCollide=false,CanTouch=false,CanQuery=false,Size=Vector3.new(1,1,1)})
pcall(function()
 handles=make('Handles',gui,{Color3=white,Faces=Faces.new(Enum.NormalId.Left,Enum.NormalId.Right,Enum.NormalId.Top,Enum.NormalId.Bottom,Enum.NormalId.Front,Enum.NormalId.Back),Visible=false,Style=Enum.HandlesStyle.Movement})
 arcs=make('ArcHandles',gui,{Color3=white,Axes=Axes.new(Enum.Axis.X,Enum.Axis.Y,Enum.Axis.Z),Visible=false})
end)
ui.moveHandles=handles;ui.rotateHandles=arcs
local function document()
 local parts={};for _,p in pairs(objects)do if exists(p)then table.insert(parts,record(p))end end
 table.sort(parts,function(a,b)return a.id<b.id end)
 return {format='HeadLockTrack',version=1,placeId=game.PlaceId,name=trackName,parts=parts}
end
local function draft()
 local data=document();_G.HeadLockTrackDraft=data
 if type(writefile)=='function'then pcall(writefile,backupFile,Http:JSONEncode(data))end
 changed=false
end
local function push(before,after)
 local equal=true;for id,data in pairs(before)do if Http:JSONEncode(data)~=Http:JSONEncode(after[id])then equal=false;break end end
 if equal then return end
 table.insert(history,{before=before,after=after});if #history>50 then table.remove(history,1)end
 table.clear(redo);changed=true
end
local function groupEdit(fn)
 local parts=selectionParts();assert(#parts>0,'Select a piece first')
 if finishDrag then finishDrag()end
 local before=snapshot(parts)
 local ok,err=pcall(fn,parts)
 if not ok then for id,data in pairs(before)do apply(id,data)end;error(err,0)end
 push(before,snapshot(parts));if refresh then refresh()end
end
local function edit(fn)groupEdit(function(parts)for _,part in ipairs(parts)do fn(part)end end)end
local function moveGroup(delta)
 groupEdit(function(parts)for _,part in ipairs(parts)do part.CFrame=part.CFrame+delta end end)
end
local function rotateGroup(turn,world)
 groupEdit(function(parts)
  local pivot=groupBounds(parts)
  local target=world and CFrame.new(pivot.Position)*turn*pivot.Rotation or pivot*turn
  for _,part in ipairs(parts)do part.CFrame=target*pivot:ToObjectSpace(part.CFrame)end
 end)
end
local function scaleLimits(parts)
 local lo,hi=0,math.huge
 for _,part in ipairs(parts)do
  lo=math.max(lo,MIN/math.min(part.Size.X,part.Size.Y,part.Size.Z));hi=math.min(hi,MAX/math.max(part.Size.X,part.Size.Y,part.Size.Z))
 end
 return lo,hi
end
local function scaleGroup(factor)
 groupEdit(function(parts)
  local low,high=scaleLimits(parts);assert(finite(factor)and factor>=low and factor<=high,'Group scale exceeds piece size limits')
  local pivot=groupBounds(parts)
  for _,part in ipairs(parts)do
   local offset=pivot:ToObjectSpace(part.CFrame)
   part.Size=part.Size*factor;part.CFrame=pivot*CFrame.new(offset.Position*factor)*offset.Rotation
  end
 end)
end
local function styleTemplate()
 if exists(selected)then local d=record(selected);return d end
 return {color={.42,.42,.42},material='Concrete',materialVariant='',transparency=0,reflectance=0,canCollide=true,canTouch=false,canQuery=true,castShadow=true,surfaces={}}
end
local function spawnAt(cf)
 assert(count()<LIMIT,'Piece limit reached')
 if finishDrag then finishDrag()end
 local d=styleTemplate();if ui.brushSet then d.material=ui.brush.material;d.color={ui.brush.color.R,ui.brush.color.G,ui.brush.color.B};d.transparency=ui.brush.transparency;d.materialVariant=''end;d.id=newId();d.class=shape=='Ramp'and 'WedgePart'or shape=='Corner'and 'CornerWedgePart'or 'Part';d.shape=shapes[shape]and shape or 'Block'
 d.name=shape;d.size={8,1,8};if shape=='Ramp'or shape=='Corner'then d.size={8,4,12}elseif shape=='Ball'then d.size={4,4,4}elseif shape=='Cylinder'then d.size={2,4,4}end
 if shape=='Block'and ui.brushSet then d.size={2,2,2}end
 d.cf={cf:GetComponents()};d.physics=nil
 local p=apply(d.id,d);push({[d.id]=false},{[d.id]=record(p)});selectPart(p);tell('Placed '..shape..'.');return p
end
local function characterRoot()local c=player.Character;return c and c:FindFirstChild('HumanoidRootPart'),c end
local function frontFrame()
 local root,c=characterRoot();local cam=workspace.CurrentCamera
 local cf=root and root.CFrame or cam.CFrame
 local point=cf.Position+cf.LookVector*12
 local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances=c and {c}or {}
 local hit=workspace:Raycast(point+Vector3.new(0,25,0),Vector3.new(0,-100,0),params)
 local h=(shape=='Ramp'or shape=='Corner')and 2 or (shape=='Ball'or shape=='Cylinder')and 2 or(ui.brushSet and 1 or .5)
 return CFrame.new(hit and hit.Position+Vector3.new(0,h,0)or point)
end
local function deleteSelected()
 local parts=selectionParts();assert(#parts>0,'Select a piece first');finishDrag()
 local before=snapshot(parts);local after={}
 for id in pairs(before)do after[id]=false;apply(id,false)end
 push(before,after);selectPart(nil);tell('Deleted '..#parts..' pieces.')
end
local function selectMany(parts)
 finishDrag();table.clear(selection);selected=nil
 for _,part in ipairs(parts)do if exists(part)then selection[part:GetAttribute('TrackPieceId')]=part;selected=part end end
 if mode=='Place'then mode='Move'end
 if refresh then refresh()end
end
local function duplicate()
 local parts=selectionParts();assert(#parts>0,'Select a piece first');finishDrag();assert(count()+#parts<=LIMIT,'Piece limit reached')
 local pivot,size=groupBounds(parts);local delta=pivot.RightVector*(size.X+moveStep)
 local before,after,copies={},{},{}
 for _,part in ipairs(parts)do
  local d=record(part);d.id=newId();d.cf={(part.CFrame+delta):GetComponents()}
  local copy=apply(d.id,d);before[d.id]=false;after[d.id]=record(copy);table.insert(copies,copy)
 end
 push(before,after);selectMany(copies);tell('Duplicated '..#copies..' pieces.')
end
function ui.copyItems(items,transform)
 assert(count()+#items<=LIMIT,'Piece limit reached')
 local copies,before={},{}
 local ok,err=pcall(function()
  for _,item in ipairs(items)do
   local d=record(item.part);d.id=newId();before[d.id]=false
   transform(d,item)
   table.insert(copies,apply(d.id,d))
  end
 end)
 if not ok then for id in pairs(before)do apply(id,false)end;error(err,0)end
 return copies,before
end
function ui.items(parts)
 local items={};for _,part in ipairs(parts)do table.insert(items,{part=part,cf=part.CFrame,size=part.Size})end;return items
end
function ui.cloneBy(delta)
 assert(typeof(delta)=='Vector3'and finite(delta.X)and finite(delta.Y)and finite(delta.Z),'Invalid clone offset')
 finishDrag();local parts=selectionParts();assert(#parts>0,'Select a piece first')
 if delta.Magnitude<1e-6 then return{}end
 local copies,before=ui.copyItems(ui.items(parts),function(d,item)d.cf={(item.cf+delta):GetComponents()}end)
 push(before,snapshot(copies));ui.assign(copies);return copies
end
function ui.mirrorCopies(parts,face)
 local pivot,size=groupBounds(parts,localAxes and(exists(selected)and selected or parts[#parts]).CFrame.Rotation or CFrame.new())
 local normal=pivot:VectorToWorldSpace(face)
 local extent=math.abs(face.X)*size.X+math.abs(face.Y)*size.Y+math.abs(face.Z)*size.Z
 local plane=pivot.Position+normal*(extent/2)
 local function reflect(v)return v-normal*(2*v:Dot(normal))end
 return ui.copyItems(ui.items(parts),function(d,item)
  local cf=item.cf;local position=plane+reflect(cf.Position-plane)
  local right,up,back=-reflect(cf.RightVector),reflect(cf.UpVector),reflect(-cf.LookVector)
  if d.class=='CornerWedgePart'then
   right=reflect(cf.LookVector);back=-reflect(cf.RightVector)
   d.size={item.size.Z,item.size.Y,item.size.X}
   local old=d.surfaces;d.surfaces={TopSurface=old.TopSurface,BottomSurface=old.BottomSurface,RightSurface=old.FrontSurface,LeftSurface=old.BackSurface,FrontSurface=old.RightSurface,BackSurface=old.LeftSurface}
  else
   d.surfaces.LeftSurface,d.surfaces.RightSurface=d.surfaces.RightSurface,d.surfaces.LeftSurface
  end
  d.cf={position.X,position.Y,position.Z,right.X,up.X,back.X,right.Y,up.Y,back.Y,right.Z,up.Z,back.Z}
 end)
end
function ui.mirrorBy(face)
 finishDrag();local parts=selectionParts();assert(#parts>0,'Select a piece first')
 assert(typeof(face)=='Vector3'and math.abs(face.Magnitude-1)<1e-6 and(math.abs(face.X)==1 or math.abs(face.Y)==1 or math.abs(face.Z)==1),'Choose a mirror axis')
 local copies,before=ui.mirrorCopies(parts,face)
 push(before,snapshot(copies));ui.assign(copies);return copies
end
local circleAxes={X=Vector3.new(1,0,0),Y=Vector3.new(0,1,0),Z=Vector3.new(0,0,1)}
local function circleOrigin(pivot,axis,radius)
 if circleManual and circleCenter then return circleCenter end
 return pivot.Position-(axis=='X'and Vector3.new(0,0,1)or Vector3.new(1,0,0))*radius
end
local function createCircle(options)
 finishDrag();local parts=selectionParts();assert(#parts>0,'Select the pieces to repeat first')
 options=options or {};assert(type(options)=='table','Invalid circle settings')
 local stations=options.count or circle.count;local radius=options.radius or circle.radius;local sweep=options.sweep or circle.sweep;local axis=options.axis or circle.axis
 assert(finite(stations)and stations%1==0 and stations>=2 and stations<=360,'Copies must be a whole number from 2–360')
 assert(finite(radius)and radius>=MIN and radius<=100000,'Radius must be 0.05–100000')
 assert(finite(sweep)and math.abs(sweep)>=.1 and math.abs(sweep)<=360,'Arc must be between 0.1 and 360 degrees')
 assert(circleAxes[axis],'Choose X, Y or Z axis')
 assert(count()+(stations-1)*#parts<=LIMIT,'Too many copies. Maximum 1500 pieces')
 local pivot=groupBounds(parts);local center=options.center or circleOrigin(pivot,axis,radius)
 assert(typeof(center)=='Vector3'and finite(center.X)and finite(center.Y)and finite(center.Z)and math.max(math.abs(center.X),math.abs(center.Y),math.abs(center.Z))<=1e7,'Invalid circle center')
 local normal=circleAxes[axis];local radial=pivot.Position-center;radial=radial-normal*radial:Dot(normal)
 radial=radial.Magnitude>1e-6 and radial.Unit or(axis=='X'and Vector3.new(0,0,1)or Vector3.new(1,0,0))
 local step=math.rad(sweep)/(math.abs(sweep)==360 and stations or stations-1)
 local templates={};for _,part in ipairs(parts)do table.insert(templates,{data=record(part),offset=pivot:ToObjectSpace(part.CFrame)})end
 local before=snapshot(parts);local after={};local ids={}
 for station=0,stations-1 do
  local target=CFrame.new(center)*CFrame.fromAxisAngle(normal,step*station)*CFrame.new(radial*radius)*pivot.Rotation
  for _,item in ipairs(templates)do
   local d=table.clone(item.data);if station>0 then d.id=newId();before[d.id]=false end
   local cf=target*item.offset;local pos=cf.Position
   assert(finite(pos.X)and finite(pos.Y)and finite(pos.Z)and math.max(math.abs(pos.X),math.abs(pos.Y),math.abs(pos.Z))<=1e7,'Circle extends beyond position limits')
   d.cf={cf:GetComponents()};after[d.id]=d;table.insert(ids,d.id)
  end
 end
 local ok,err=pcall(function()for id,data in pairs(after)do apply(id,data)end end)
 if not ok then for id,data in pairs(before)do apply(id,data)end;error(err,0)end
 push(before,after);local copies={};for _,id in ipairs(ids)do table.insert(copies,objects[id])end;selectMany(copies)
 tell('Created '..stations..' stations / '..#copies..' selected pieces.');return copies
end
local function historyStep(from,to,key)
 finishDrag();local entry=table.remove(from);if not entry then tell('Nothing to '..key..'.');return end
 local changes=key=='undo'and entry.before or entry.after
 for id,data in pairs(changes)do apply(id,data)end
 table.insert(to,entry);changed=true;selectionParts();refresh();tell(string.upper(key)..'.')
end
local function clear()
 finishDrag();local before,after={},{}
 for id,p in pairs(objects)do before[id]=record(p);after[id]=false end
 for id in pairs(before)do apply(id,false)end
 push(before,after);selectPart(nil);tell('Draft cleared.')
end
local function import(data)
 finishDrag()
 if type(data)=='string'then assert(#data<4000000,'Import too large');if data:sub(1,#PREFIX)==PREFIX then data=data:sub(#PREFIX+1)end;data=Http:JSONDecode(data)end
 data=normalize(data)
 local before,after={},{}
 for id,p in pairs(objects)do before[id]=record(p);after[id]=false end
 for _,d in ipairs(data.parts)do if before[d.id]==nil then before[d.id]=false end;after[d.id]=d end
 local oldName=trackName
 local ok,err=pcall(function()for id,d in pairs(after)do apply(id,d)end end)
 if not ok then for id,d in pairs(before)do apply(id,d)end;trackName=oldName;error(err,0)end
 trackName=data.name;push(before,after);selectPart(nil);draft();tell('Loaded '..#data.parts..' pieces.');return #data.parts
end
local function sync(data,resetHistory)
 assert(not drag,'Finish the current edit first')
 data=normalize(data)
 local function signature(d)
  local surf={};for _,key in ipairs(surfaces)do table.insert(surf,d.surfaces and d.surfaces[key]or'Smooth')end
  return Http:JSONEncode({d.class,d.name,d.shape or'Block',d.size,d.cf,d.color,d.material,d.materialVariant or'',d.transparency or 0,d.reflectance or 0,d.canCollide~=false,d.canTouch==true,d.canQuery~=false,d.castShadow~=false,surf,d.physics or{}})
 end
 local incoming={};for _,part in ipairs(data.parts)do incoming[part.id]=part end
 local affected={}
 for id,p in pairs(objects)do
  if not incoming[id]then affected[id]=true;apply(id,false)
  elseif signature(record(p))~=signature(incoming[id])then affected[id]=true;apply(id,incoming[id])end
 end
 for id,part in pairs(incoming)do if not objects[id]then affected[id]=true;apply(id,part)end end
 local function prune(stack)
  for i=#stack,1,-1 do
   local entry=stack[i]
   for id in pairs(affected)do entry.before[id]=nil;entry.after[id]=nil end
   if next(entry.before)==nil then table.remove(stack,i)end
  end
 end
 if resetHistory then table.clear(history);table.clear(redo);selectPart(nil)else prune(history);prune(redo);selectionParts()end
 trackName=data.name;changed=true;refresh();return #data.parts
end
local exportBox,exportWindow
local function exportText()return PREFIX..Http:JSONEncode(document())end
local function showTransfer(text)
 if exportWindow then exportWindow:Destroy()end
 exportWindow=make('Frame',gui,{Name='TransferWindow',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.new(.85,0,.78,0),BackgroundColor3=black,Active=true,ZIndex=20});stroke(exportWindow)
 make('TextLabel',exportWindow,{Text='TRACK DATA',Position=UDim2.fromOffset(12,6),Size=UDim2.new(1,-58,0,28),BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=21})
 local closeTransfer=make('TextButton',exportWindow,{Text='×',Position=UDim2.new(1,-38,0,2),Size=UDim2.fromOffset(34,34),BackgroundTransparency=1,ZIndex=21})
 connect(closeTransfer.Activated,function()exportWindow:Destroy();exportWindow=nil;exportBox=nil end)
 exportBox=make('TextBox',exportWindow,{Name='TrackData',Text=text or '',PlaceholderText='Paste a HEADLOCK_TRACK_V1 export here',ClearTextOnFocus=false,MultiLine=true,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,TextSize=11,
  Position=UDim2.fromOffset(12,42),Size=UDim2.new(1,-24,1,-94),BackgroundColor3=black,ZIndex=21});stroke(exportBox)
 local load=button(exportWindow,'LOAD DATA',0,0,.5,function()import(exportBox.Text);exportWindow:Destroy();exportWindow=nil;exportBox=nil end)
 load.Position=UDim2.new(0,12,1,-40);load.Size=UDim2.new(.5,-18,0,30);load.ZIndex=21
 local selectAll=button(exportWindow,'SELECT ALL',.5,0,.5,function()exportBox:CaptureFocus();exportBox.CursorPosition=#exportBox.Text+1;exportBox.SelectionStart=1 end)
 selectAll.Position=UDim2.new(.5,6,1,-40);selectAll.Size=UDim2.new(.5,-18,0,30);selectAll.ZIndex=21
end
local function save()
 finishDrag();draft();local text=exportText()
 local copy=type(setclipboard)=='function'and setclipboard or type(toclipboard)=='function'and toclipboard or type(syn)=='table'and syn.write_clipboard
 local ok=type(copy)=='function'and pcall(copy,text)
 if ok then tell('COPIED '..count()..' pieces.')else showTransfer(text);tell('Clipboard unavailable. Use SELECT ALL and copy.')end
 return text
end
local function updateGizmos()
 local parts=selectionParts();local p=selected
 local accent=ui.colors and(ui.colors[mode]or ui.colors.Move)or Color3.fromRGB(0,134,171)
 box.Color3=accent;box.SurfaceColor3=accent;box.Adornee=mode~='Idle'and p or nil
 for id,outline in pairs(selectionBoxes)do
  if mode=='Idle'or not selection[id]or selection[id]==p then outline:Destroy();selectionBoxes[id]=nil end
 end
 for _,part in ipairs(parts)do
  local id=part:GetAttribute('TrackPieceId')
  if mode~='Idle'and part~=p then
   if not selectionBoxes[id]then selectionBoxes[id]=make('SelectionBox',gui,{Color3=accent,SurfaceColor3=accent,SurfaceTransparency=.5,LineThickness=.04})end
   selectionBoxes[id].Adornee=part;selectionBoxes[id].Color3=accent;selectionBoxes[id].SurfaceColor3=accent
  end
 end
 if ui.groupOutline then ui.groupOutline.Color3=accent;ui.groupOutline.Adornee=mode~='Idle'and #parts>1 and gizmo or nil end
 local pivot,size=groupBounds(parts)
 if mode=='Mirror'and pivot then pivot,size=groupBounds(parts,localAxes and p.CFrame.Rotation or CFrame.new())end
 if pivot then
  gizmo.Size=Vector3.new(math.clamp(size.X,MIN,MAX),math.clamp(size.Y,MIN,MAX),math.clamp(size.Z,MIN,MAX))
  gizmo.CFrame=(localAxes or mode=='Scale'or mode=='Mirror')and pivot or CFrame.new(pivot.Position)
 end
 if handles then handles.Adornee=p and gizmo or nil;handles.Style=mode=='Scale'and Enum.HandlesStyle.Resize or Enum.HandlesStyle.Movement;handles.Color3=accent;handles.Visible=p~=nil and(mode=='Move'or mode=='Scale'or mode=='Clone') end
 if arcs then arcs.Adornee=p and gizmo or nil;arcs.Color3=accent;arcs.Visible=p~=nil and mode=='Rotate' end
 if ui.mirrorHandles then ui.mirrorHandles.Adornee=p and gizmo or nil;ui.mirrorHandles.Visible=p~=nil and mode=='Mirror'end
end
finishDrag=function()
 if ui.cancelBox then ui.cancelBox(false)end
 if not drag then unlockCamera('gizmo');return end
 local d=drag;drag=nil;unlockCamera('gizmo');blockWorldUntil=os.clock()+.15
 if d.clone and(not d.copies or math.abs(d.amount or 0)<1e-6)then
  for _,part in ipairs(d.copies or{})do apply(part:GetAttribute('TrackPieceId'),false)end
  if ui.assign then ui.assign(d.originals)end
  return
 end
 local after={};for id in pairs(d.before)do after[id]=exists(objects[id])and record(objects[id])or false end
 push(d.before,after)
 if refresh then refresh()end
end
local function beginDrag(face)
 if ui.cancelBox then ui.cancelBox(true)end
 finishDrag();local parts=selectionParts()
 if #parts>0 and(mode=='Move'or mode=='Scale'or mode=='Rotate'or mode=='Clone'or mode=='Mirror')then
  local pivot,size=groupBounds(parts);local items={}
  for _,part in ipairs(parts)do table.insert(items,{part=part,cf=part.CFrame,size=part.Size})end
  local low,high=scaleLimits(parts)
  drag={parts=parts,items=items,before=snapshot(parts),pivot=pivot,size=size,low=low,high=high,localAxes=localAxes,
   input=lastTouch and os.clock()-(lastTouchAt or 0)<.2 and lastTouch or nil,clone=mode=='Clone',originals=parts}
  if mode=='Mirror'then
   local copies,before=ui.mirrorCopies(parts,face)
   drag.before=before;drag.parts=copies;ui.assign(copies)
  end
  blockWorldUntil=math.huge;lockCamera('gizmo')
 end
end
local faces={[Enum.NormalId.Right]=Vector3.new(1,0,0),[Enum.NormalId.Left]=Vector3.new(-1,0,0),[Enum.NormalId.Top]=Vector3.new(0,1,0),[Enum.NormalId.Bottom]=Vector3.new(0,-1,0),[Enum.NormalId.Back]=Vector3.new(0,0,1),[Enum.NormalId.Front]=Vector3.new(0,0,-1)}
local axes={[Enum.Axis.X]=Vector3.new(1,0,0),[Enum.Axis.Y]=Vector3.new(0,1,0),[Enum.Axis.Z]=Vector3.new(0,0,1)}
if handles then
 connect(handles.MouseButton1Down,safe(beginDrag))
 connect(handles.MouseDrag,safe(function(face,distance)
  if not drag then return end
  local v=faces[face];if not v then return end
  local amount=snap(distance,moveStep)
  if mode=='Scale'then
   local absolute=Vector3.new(math.abs(v.X),math.abs(v.Y),math.abs(v.Z));local original=drag.size:Dot(absolute)
   if #drag.items==1 then
    local item=drag.items[1];amount=math.clamp(original+amount,MIN,MAX)-original
    item.part.Size=item.size+absolute*amount;item.part.CFrame=item.cf*CFrame.new(v*amount/2)
   else
    local factor=math.clamp((original+amount)/original,drag.low,drag.high);amount=original*(factor-1)
    local pivot=drag.pivot*CFrame.new(v*amount/2)
    for _,item in ipairs(drag.items)do
     local offset=drag.pivot:ToObjectSpace(item.cf)
     item.part.Size=item.size*factor;item.part.CFrame=pivot*CFrame.new(offset.Position*factor)*offset.Rotation
    end
   end
  elseif mode=='Move'or mode=='Clone'then
   local delta=drag.localAxes and drag.pivot:VectorToWorldSpace(v*amount)or v*amount
   if mode=='Clone'then
    drag.amount=amount
    if not drag.copies and math.abs(amount)>1e-6 then
     local copies,before=ui.copyItems(drag.items,function(d,item)d.cf={(item.cf+delta):GetComponents()}end)
     drag.copies=copies;drag.before=before;ui.assign(copies)
    end
    for i,part in ipairs(drag.copies or{})do part.CFrame=drag.items[i].cf+delta end
   else for _,item in ipairs(drag.items)do item.part.CFrame=item.cf+delta end end
  end
  refresh()
 end))
 connect(handles.MouseButton1Up,finishDrag)
end
if arcs then
 connect(arcs.MouseButton1Down,beginDrag)
 connect(arcs.MouseDrag,safe(function(axis,angle)
  if drag and axes[axis]then
   local turn=CFrame.fromAxisAngle(axes[axis],math.rad(snap(math.deg(angle),angleStep)))
   local pivot=drag.localAxes and drag.pivot*turn or CFrame.new(drag.pivot.Position)*turn*drag.pivot.Rotation
   for _,item in ipairs(drag.items)do item.part.CFrame=pivot*drag.pivot:ToObjectSpace(item.cf)end
   refresh()
  end
 end))
 connect(arcs.MouseButton1Up,finishDrag)
end
local modeButtons,shapeButtons={},{}
local fields={}
local function setMode(name)if ui.cancelBox then ui.cancelBox(true)end;finishDrag();mode=name;updateGizmos();refresh();tell('') end
local function nudge(axis,sign)
 local parts=selectionParts();assert(#parts>0,'Select a piece first')
 local v=Vector3.new(axis==1 and 1 or 0,axis==2 and 1 or 0,axis==3 and 1 or 0)
 if mode=='Scale'then
  if #parts>1 then local _,size=groupBounds(parts);scaleGroup((list(size)[axis]+moveStep*sign)/list(size)[axis])
  else edit(function(p)local s=list(p.Size);s[axis]=math.clamp(s[axis]+moveStep*sign,MIN,MAX);p.Size=vector(s)end)end
 elseif mode=='Clone'then local pivot=groupBounds(parts);ui.cloneBy(localAxes and pivot:VectorToWorldSpace(v*moveStep*sign)or v*moveStep*sign)
 elseif mode=='Mirror'then ui.mirrorBy(v*sign)
 elseif mode=='Rotate'then rotateGroup(CFrame.fromAxisAngle(v,math.rad(angleStep*sign)),not localAxes)
 else local pivot=groupBounds(parts);moveGroup(localAxes and pivot:VectorToWorldSpace(v*moveStep*sign)or v*moveStep*sign)end
end
button(content,'ALL',0,66,.5,function()local parts={};for _,part in pairs(objects)do if exists(part)then table.insert(parts,part)end end;selectMany(parts)end)
button(content,'NONE',.5,66,.5,function()selectMany({})end)
local build=pages.Build
label(build,'PIECE',0)
for i,name in ipairs({'Block','Ramp','Corner','Ball','Cylinder'})do
 local col=(i-1)%3;local row=math.floor((i-1)/3)
 shapeButtons[name]=button(build,string.upper(name),col/3,26+row*38,1/3,function()shape=name;refresh()end)
end
button(build,'PLACE AT TAP',0,108,.5,function()if ui.tools.Hammer then ui.equip('Hammer');ui.materialWindow.Visible=false else setMode('Place')end end)
button(build,'ADD IN FRONT',.5,108,.5,function()spawnAt(frontFrame());if ui.tools.Trowel then ui.equip('Move')else setMode('Move')end end)
button(build,'DUPLICATE',0,144,.5,duplicate)
button(build,'DELETE',.5,144,.5,deleteSelected)
button(build,'UNDO',0,184,.5,function()historyStep(history,redo,'undo')end)
button(build,'REDO',.5,184,.5,function()historyStep(redo,history,'redo')end)
local editPage=pages.Edit
for i,name in ipairs({'Move','Rotate','Clone','Mirror','Scale'})do modeButtons[name]=button(editPage,string.upper(name),(i-1)/5,0,1/5,function()if name=='Scale'then ui.equip('Scale')else ui.equip('Trowel');ui.setTrowelMode(name);ui.showMain('Edit')end end);modeButtons[name].TextSize=10 end
local spaceButton=button(editPage,'AXES: LOCAL',0,40,.5,function()ui.setAxes(not localAxes)end)
local snapMove=field(editPage,'Stud step',.5,40,.25,'1',function(t)local n=number(t);assert(n and n>=0 and n<=100,'Step must be 0–100');moveStep=n;refresh()end)
local snapAngle=field(editPage,'Angle step',.75,40,.25,'15',function(t)local n=number(t);assert(n and n>0 and n<=180,'Angle step must be 1–180');angleStep=n;refresh()end)
label(editPage,'POSITION  X / Y / Z',80)
for i=1,3 do
 fields['pos'..i]=field(editPage,'Position'..i,(i-1)/3,105,1/3,'',function(t)local n=number(t);assert(n and math.abs(n)<=1e7,'Invalid position');local pivot=groupBounds();assert(pivot,'Select a piece first');local a=list(pivot.Position);a[i]=n;moveGroup(vector(a)-pivot.Position)end)
end
groupSizeLabel=label(editPage,'SIZE  X / Y / Z',144)
for i=1,3 do fields['size'..i]=field(editPage,'Size'..i,(i-1)/3,169,1/3,'',function(t)local n=number(t);assert(n and n>=MIN and n<=MAX,'Size must be 0.05–2048');local parts=selectionParts();assert(#parts>0,'Select a piece first');if #parts>1 then local _,size=groupBounds(parts);scaleGroup(n/list(size)[i])else edit(function(p)local a=list(p.Size);a[i]=n;p.Size=vector(a)end)end end)end
label(editPage,'ROTATION  X / Y / Z',208)
for i=1,3 do fields['rot'..i]=field(editPage,'Rotation'..i,(i-1)/3,233,1/3,'',function(t)local n=number(t);assert(n and math.abs(n)<=36000,'Invalid angle');groupEdit(function(parts)local pivot=groupBounds(parts);local a={pivot:ToOrientation()};a[i]=math.rad(n);local target=CFrame.new(pivot.Position)*CFrame.fromOrientation(table.unpack(a));for _,p in ipairs(parts)do p.CFrame=target*pivot:ToObjectSpace(p.CFrame)end end)end)end
label(editPage,'X / Y / Z',272)
for i,name in ipairs({'X','Y','Z'})do
 button(editPage,name..' −',(i-1)/3,298,1/6,function()nudge(i,-1)end)
 button(editPage,name..' +',(i-1)/3+1/6,298,1/6,function()nudge(i,1)end)
end
button(editPage,'DUPLICATE',0,338,.5,duplicate);button(editPage,'DELETE',.5,338,.5,deleteSelected)
button(editPage,'UNDO',0,378,.5,function()historyStep(history,redo,'undo')end);button(editPage,'REDO',.5,378,.5,function()historyStep(redo,history,'redo')end)
local style=pages.Style
label(style,'RGB  0–255',0)
for i=1,3 do fields['rgb'..i]=field(style,'Color'..i,(i-1)/3,26,1/3,'',function(t)local n=number(t);assert(n and n>=0 and n<=255,'Color must be 0–255');edit(function(p)local a={p.Color.R,p.Color.G,p.Color.B};a[i]=n/255;p.Color=Color3.new(table.unpack(a))end)end)end
local palette={{'WHITE',255,255,255},{'GRAY',110,110,110},{'BLACK',20,20,20},{'RED',180,45,45},{'YELLOW',245,190,40},{'GREEN',55,140,80},{'BLUE',45,95,180},{'ORANGE',230,110,30}}
for i,item in ipairs(palette)do
 local col=(i-1)%4;local row=math.floor((i-1)/4)
 local b=button(style,item[1],col/4,68+row*38,1/4,function()edit(function(p)p.Color=Color3.fromRGB(item[2],item[3],item[4])end)end)
 b.TextSize=10
end
label(style,'MATERIAL',152)
fields.material=field(style,'Material',0,178,1,'Concrete',function(t)assert(member(Enum.Material,t),'Use an exact material name');edit(function(p)p.Material=Enum.Material[t]end)end)
local materials={'Concrete','Asphalt','Plastic','Metal','Neon','Glass'}
for i,name in ipairs(materials)do button(style,string.upper(name),(i-1)%3/3,222+math.floor((i-1)/3)*38,1/3,function()edit(function(p)p.Material=Enum.Material[name]end)end).TextSize=10 end
label(style,'TRANSPARENCY / REFLECTANCE (0–1)',308)
fields.transparency=field(style,'Transparency',0,334,.5,'0',function(t)local n=number(t);assert(n and n>=0 and n<=1,'Transparency must be 0–1');edit(function(p)p.Transparency=n end)end)
fields.reflectance=field(style,'Reflectance',.5,334,.5,'0',function(t)local n=number(t);assert(n and n>=0 and n<=1,'Reflectance must be 0–1');edit(function(p)p.Reflectance=n end)end)
local collideButton=button(style,'COLLISION: ON',0,380,.5,function()assert(exists(selected),'Select a piece first');local enabled=not selected.CanCollide;edit(function(p)p.CanCollide=enabled end)end)
local shadowButton=button(style,'SHADOW: ON',.5,380,.5,function()assert(exists(selected),'Select a piece first');local enabled=not selected.CastShadow;edit(function(p)p.CastShadow=enabled end)end)
local circlePage=pages.Circle
label(circlePage,'COPIES / RADIUS / ARC',0)
circleFields.count=field(circlePage,'CircleCopies',0,26,1/3,'24',function(t)local n=number(t);assert(n and n%1==0 and n>=2 and n<=360,'Stations must be 2–360');circle.count=n;refresh()end)
circleFields.radius=field(circlePage,'CircleRadius',1/3,26,1/3,'20',function(t)local n=number(t);assert(n and n>=MIN and n<=100000,'Radius must be 0.05–100000');circle.radius=n;refresh()end)
circleFields.sweep=field(circlePage,'CircleArc',2/3,26,1/3,'360',function(t)local n=number(t);assert(n and math.abs(n)>=.1 and math.abs(n)<=360,'Arc must be 0.1–360 degrees');circle.sweep=n;refresh()end)
circleAxisButton=button(circlePage,'AXIS: Y',0,70,1,function()circle.axis=circle.axis=='Y'and 'X'or circle.axis=='X'and 'Z'or 'Y';refresh()end)
label(circlePage,'CENTER  X / Y / Z',112)
for i=1,3 do circleFields['center'..i]=field(circlePage,'CircleCenter'..i,(i-1)/3,138,1/3,'',function(t)
 local n=number(t);assert(n and math.abs(n)<=1e7,'Invalid center');local pivot=groupBounds();assert(pivot,'Select a piece first')
 local coords=list(circleOrigin(pivot,circle.axis,circle.radius));coords[i]=n;circleCenter=vector(coords);circleManual=true;refresh()
end)end
circleCenterButton=button(circlePage,'CENTER: AUTO',0,180,.5,function()circleCenter=nil;circleManual=false;refresh()end)
button(circlePage,'USE SELECTION',.5,180,.5,function()local pivot=groupBounds();assert(pivot,'Select a piece first');circleCenter=pivot.Position;circleManual=true;refresh()end)
button(circlePage,'CREATE CIRCLE / ARC',0,226,1,function()createCircle()end)
button(circlePage,'UNDO',0,268,.5,function()historyStep(history,redo,'undo')end)
button(circlePage,'REDO',.5,268,.5,function()historyStep(redo,history,'redo')end)
local savePage=pages.Save
label(savePage,'TRACK NAME',0)
local nameBox=field(savePage,'Track name',0,26,1,trackName,function(t)trackName=t:sub(1,80);changed=true;refresh()end)
button(savePage,'SAVE + COPY',0,72,1,save)
button(savePage,'VIEW / IMPORT DATA',0,116,1,function()showTransfer(exportText())end)
button(savePage,'RESTORE LOCAL DRAFT',0,160,1,function()
 local data=_G.HeadLockTrackDraft
 if not data and type(readfile)=='function'and type(isfile)=='function'and isfile(backupFile)then data=readfile(backupFile)end
 assert(data,'No saved draft yet');import(data)
end)
local clearArmed=0
button(savePage,'CLEAR DRAFT',0,204,1,function()
 if os.clock()>clearArmed then clearArmed=os.clock()+3;tell('Press CLEAR DRAFT again to confirm.');return end
 clearArmed=0;clear()
end)
local function setText(box,text)if not box:IsFocused()then box.Text=text end end
refresh=function()
 local chosen=selectionParts();local p=selected;local pivot,extent=groupBounds(chosen)
 selectionText.Text=tostring(count())..' PIECES  /  '..#chosen..' SELECTED'
 groupSizeLabel.Text=#chosen>1 and 'GROUP SIZE'or 'SIZE  X / Y / Z'
 circleAxisButton.Text='AXIS: '..circle.axis
 circleCenterButton.Text=circleManual and 'RESET CENTER'or 'CENTER: AUTO'
 for _,key in ipairs({'count','radius','sweep'})do setText(circleFields[key],tostring(circle[key]))end
 local center=pivot and list(circleOrigin(pivot,circle.axis,circle.radius))or nil
 for i=1,3 do setText(circleFields['center'..i],center and string.format('%.3f',center[i])or '')end
 if p then
  local pos,size=list(pivot.Position),list(extent);local rot={pivot:ToOrientation()};local rgb={p.Color.R*255,p.Color.G*255,p.Color.B*255}
  for i=1,3 do setText(fields['pos'..i],string.format('%.3f',pos[i]));setText(fields['size'..i],string.format('%.3f',size[i]));setText(fields['rot'..i],string.format('%.2f',math.deg(rot[i])));setText(fields['rgb'..i],string.format('%.1f',rgb[i]))end
  setText(fields.material,p.Material.Name);setText(fields.transparency,string.format('%.2f',p.Transparency));setText(fields.reflectance,string.format('%.2f',p.Reflectance))
 else for _,b in pairs(fields)do setText(b,'')end end
 collideButton.Text='COLLISION: '..(p and not p.CanCollide and 'OFF'or 'ON');shadowButton.Text='SHADOW: '..(p and not p.CastShadow and 'OFF'or 'ON')
 spaceButton.Text='AXES: '..(localAxes and 'LOCAL'or 'WORLD')
 setText(nameBox,trackName);setText(snapMove,tostring(moveStep));setText(snapAngle,tostring(angleStep))
 for name,b in pairs(shapeButtons)do b.BackgroundColor3=name==shape and white or black;b.TextColor3=name==shape and black or white end
 for name,b in pairs(modeButtons)do b.BackgroundColor3=name==mode and white or black;b.TextColor3=name==mode and black or white end
 updateGizmos();if ui.refresh then ui.refresh()end
end
selectPart=function(p,additive)
 finishDrag()
 if additive and exists(p)then
  local id=p:GetAttribute('TrackPieceId')
  if selection[id]then selection[id]=nil else selection[id]=p;selected=p end
 else table.clear(selection);selected=exists(p)and p or nil;if selected then selection[selected:GetAttribute('TrackPieceId')]=selected end end
 selectionParts();if mode=='Place'then mode='Move'end;refresh()
end
setTab=function(name)
 finishDrag();tab=name
 for key,page in pairs(pages)do page.Visible=key==name;tabs[key].BackgroundColor3=key==name and white or black;tabs[key].TextColor3=key==name and black or white end
 refresh()
end
for name,b in pairs(tabs)do connect(b.Activated,function()setTab(name)end)end
local function clampPanel()
 local camera=workspace.CurrentCamera;if not camera then return end
 local inset,bottom=GuiService:GetGuiInset();local width,height=camera.ViewportSize.X,camera.ViewportSize.Y-inset.Y-bottom.Y
 local s=math.clamp(math.min(1,(width-20)/330,(height-16)/440),.6,1)
 scale.Scale=s
 local w,h=330*s,(minimized and 36 or 440)*s
 panel.Position=UDim2.fromOffset(math.clamp(panel.Position.X.Offset,0,math.max(0,width-w)),math.clamp(panel.Position.Y.Offset,0,math.max(0,height-h)))
 if ui.layout then ui.layout()end
end
ui.colors={Clone=Color3.fromRGB(0,134,171),Mirror=Color3.fromRGB(245,110,175),Move=Color3.fromRGB(0,134,171),Rotate=Color3.fromRGB(0,134,171),Scale=Color3.fromRGB(172,109,0),Paint=Color3.fromRGB(13,105,172),Delete=Color3.fromRGB(172,0,0),Select=Color3.fromRGB(2,136,0),Place=Color3.fromRGB(207,151,30)}
ui.groupOutline=make('SelectionBox',gui,{Color3=ui.colors.Move,LineThickness=.055,SurfaceTransparency=1})
ui.canvas=make('Frame',gui,{Name='SelectionCanvas',Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Active=false,ZIndex=6})
ui.rectangle=make('ImageLabel',ui.canvas,{Name='DragSelection',Image='rbxassetid://8008696978',ScaleType=Enum.ScaleType.Slice,SliceCenter=Rect.new(1,1,2,2),ImageColor3=Color3.fromRGB(30,151,207),BackgroundColor3=Color3.fromRGB(21,108,145),BackgroundTransparency=.75,Visible=false,ZIndex=7})
function ui.assign(parts)
 table.clear(selection);selected=nil
 for _,part in ipairs(parts)do if exists(part)then selection[part:GetAttribute('TrackPieceId')]=part;selected=part end end
 refresh()
end
function ui.project()
 local camera=workspace.CurrentCamera;local out={}
 if not camera then return out end
 for _,part in pairs(objects)do if exists(part)then
  local loX,loY,hiX,hiY=math.huge,math.huge,-math.huge,-math.huge;local front=false
  for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
   local corner=part.CFrame:PointToWorldSpace(Vector3.new(part.Size.X*x,part.Size.Y*y,part.Size.Z*z)/2)
   local point=camera:WorldToScreenPoint(corner)
   if point.Z>.01 and math.abs(point.X)<1e7 and math.abs(point.Y)<1e7 then
    front=true;loX=math.min(loX,point.X);loY=math.min(loY,point.Y);hiX=math.max(hiX,point.X);hiY=math.max(hiY,point.Y)
   end
  end end end
  if front then table.insert(out,{part=part,x1=loX,y1=loY,x2=hiX,y2=hiY})end
 end end
 return out
end
function ui.boxParts(a,b,projected,base)
 local x1,y1,x2,y2=math.min(a.X,b.X),math.min(a.Y,b.Y),math.max(a.X,b.X),math.max(a.Y,b.Y)
 local out,added={},{}
 for _,part in ipairs(base or{})do if exists(part)then added[part]=true;table.insert(out,part)end end
 for _,r in ipairs(projected or ui.project())do
  if exists(r.part)and not added[r.part]and r.x2>=x1 and r.x1<=x2 and r.y2>=y1 and r.y1<=y2 then added[r.part]=true;table.insert(out,r.part)end
 end
 return out
end
function ui.cancelBox(restore)
 local gesture=ui.boxGesture;if not gesture then return end
 ui.boxGesture=nil;ui.rectangle.Visible=false;unlockCamera('box')
 if restore and gesture.active then ui.assign(gesture.before)end
end
function ui.beginBox(input)
 if ui.boxGesture then return end
 local p=Vector2.new(input.Position.X,input.Position.Y)
 ui.boxGesture={input=input,start=p,point=p,before=selectionParts(),additive=multiSelect or UIS:IsKeyDown(Enum.KeyCode.LeftShift)or UIS:IsKeyDown(Enum.KeyCode.RightShift),active=false,last=-1}
 lockCamera('box')
end
function ui.changeBox(input,force)
 local g=ui.boxGesture;if not g then return end
 if input~=g.input and not(g.input.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseMovement)then return end
 g.point=Vector2.new(input.Position.X,input.Position.Y)
 if not g.active and(g.point-g.start).Magnitude<9 then return end
 if not g.active then g.active=true;g.projected=ui.project()end
 local origin=ui.canvas.AbsolutePosition
 ui.rectangle.Position=UDim2.fromOffset(math.min(g.start.X,g.point.X)-origin.X,math.min(g.start.Y,g.point.Y)-origin.Y)
 ui.rectangle.Size=UDim2.fromOffset(math.abs(g.point.X-g.start.X),math.abs(g.point.Y-g.start.Y));ui.rectangle.Visible=true
 if force or os.clock()-g.last>=.08 then g.last=os.clock();ui.assign(ui.boxParts(g.start,g.point,g.projected,g.additive and g.before or nil))end
end
function ui.endBox(input)
 local g=ui.boxGesture;if not g then return false end
 if g.input.UserInputType==Enum.UserInputType.MouseButton1 and g.active then ui.changeBox({UserInputType=Enum.UserInputType.MouseMovement,Position=g.point},true)else ui.changeBox(input,true)end;local active=g.active
 ui.boxGesture=nil;ui.rectangle.Visible=false;unlockCamera('box')
 if active then blockWorldUntil=os.clock()+.15;tell('Selected '..#selectionParts()..' pieces.')end
 return active
end
function ui.setTrowelMode(name)
 assert(name=='Move'or name=='Rotate'or name=='Clone'or name=='Mirror','Unknown trowel mode')
 ui.trowelMode=name
 if ui.equippedTool==ui.tools.Trowel then setMode(name)end
end
function ui.cycleTrowel()
 local modes={'Move','Rotate','Clone','Mirror'}
 local i=table.find(modes,ui.trowelMode)or 1;ui.setTrowelMode(modes[i%#modes+1])
end
function ui.showMain(page)
 panel.Visible=true;content.Visible=true;minimized=false;panel.Size=UDim2.fromOffset(330,440);minimize.Text='−';setTab(page or'Edit');clampPanel();refresh()
end
function ui.setTool(name)
 ui.cancelBox(true);ui.currentTool=name
 if name~='Paint'and name~='Properties'then panel.Visible=false end
 if ui.materialWindow then ui.materialWindow.Visible=false end
 if name=='Hammer'then setMode('Place');ui.materialWindow.Visible=true;ui.layout();tell('')
 elseif name=='Trowel'then setMode(ui.trowelMode)
 elseif name=='Move'then setMode('Move')
 elseif name=='Scale'then setMode('Scale')
 elseif name=='Rotate'then setMode('Rotate')
 elseif name=='Paint'then setMode('Paint');ui.showMain('Style')
 elseif name=='Delete'then setMode('Delete');tell('')
 elseif name=='Properties'then setMode('Select');ui.showMain('Style')end
 if ui.refresh then ui.refresh()end
end
function ui.setAxes(value)
 assert(type(value)=='boolean','Axes must be true for local or false for world')
 finishDrag();localAxes=value;ui.settings.localAxes=value;refresh()
 tell('')
end
function ui.getAxes()return localAxes and'Local'or'World'end
ui.materialButtons={}
ui.trowelSwitch=make('TextButton',gui,{Name='TrowelMode',Text='MOVE  ›',AnchorPoint=Vector2.new(0,.5),Position=UDim2.new(0,12,.46,0),Size=UDim2.fromOffset(104,38),BackgroundColor3=Color3.fromRGB(35,29,25),TextSize=13,Active=true,Visible=false,ZIndex=10});stroke(ui.trowelSwitch)
connect(ui.trowelSwitch.Activated,safe(ui.cycleTrowel))
ui.switchScale=make('UIScale',ui.trowelSwitch,{Scale=1})
ui.menuButton=make('TextButton',gui,{Name='BuilderMenu',Text='≡',Position=UDim2.new(1,-46,.32,0),Size=UDim2.fromOffset(32,32),BackgroundColor3=Color3.fromRGB(35,29,25),TextSize=23,Active=true,Visible=false,ZIndex=10});stroke(ui.menuButton)
connect(ui.menuButton.Activated,safe(function()if panel.Visible then finishDrag();panel.Visible=false else ui.showMain(tab)end end))
ui.mirrorHandles=make('Handles',gui,{Name='MirrorHandles',Color3=ui.colors.Mirror,Faces=Faces.new(Enum.NormalId.Left,Enum.NormalId.Right,Enum.NormalId.Top,Enum.NormalId.Bottom,Enum.NormalId.Front,Enum.NormalId.Back),Visible=false,Style=Enum.HandlesStyle.Resize})
connect(ui.mirrorHandles.MouseButton1Down,safe(function(face)
 if mode~='Mirror'or not faces[face]then return end
 local ok,err=pcall(beginDrag,faces[face])
 if not ok then finishDrag();error(err,0)end
end))
connect(ui.mirrorHandles.MouseButton1Up,finishDrag)
ui.materialWindow=make('Frame',gui,{Name='MaterialPicker',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(294,322),BackgroundColor3=Color3.fromRGB(35,29,25),Visible=false,Active=true,ZIndex=12});stroke(ui.materialWindow)
ui.materialScale=make('UIScale',ui.materialWindow,{Scale=1})
make('TextLabel',ui.materialWindow,{Text='BLOCKS',Position=UDim2.fromOffset(12,2),Size=UDim2.new(1,-50,0,32),TextXAlignment=Enum.TextXAlignment.Left,BackgroundTransparency=1,TextSize=16,ZIndex=13})
ui.materialClose=make('TextButton',ui.materialWindow,{Text='×',Position=UDim2.new(1,-36,0,0),Size=UDim2.fromOffset(34,34),BackgroundTransparency=1,ZIndex=13})
connect(ui.materialClose.Activated,function()ui.materialWindow.Visible=false end)
ui.materialList=make('ScrollingFrame',ui.materialWindow,{Name='Materials',Position=UDim2.fromOffset(8,38),Size=UDim2.new(1,-16,1,-46),AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(),ScrollBarThickness=3,BackgroundTransparency=1,ZIndex=13})
ui.materials={}
for _,entry in ipairs({{'Concrete','CONCRETE',125,125,125},{'WoodPlanks','WOOD',163,116,65},{'Wood','LOG',140,98,55},{'Brick','BRICK',155,73,54},{'Cobblestone','STONE',120,120,113},{'Slate','SLATE',90,99,109},{'Metal','METAL',155,163,170},{'DiamondPlate','PLATE',140,145,150},{'Asphalt','ASPHALT',42,43,46},{'Grass','GRASS',80,127,50},{'Sand','SAND',209,188,137},{'Ice','ICE',180,220,237},{'Glass','GLASS',190,222,235,.5},{'Plastic','PLASTIC',215,215,215},{'Neon','NEON',170,230,255}})do
 if member(Enum.Material,entry[1])then table.insert(ui.materials,entry)end
end
function ui.chooseMaterial(name)
 local chosen
 for _,entry in ipairs(ui.materials)do if entry[1]==name then chosen=entry;break end end
 assert(chosen,'Choose a listed block material')
 ui.brush={material=name,color=Color3.fromRGB(chosen[3],chosen[4],chosen[5]),transparency=chosen[6]or 0};ui.brushSet=true;shape='Block';ui.currentTool='Hammer'
 ui.materialWindow.Visible=false;setMode('Place');tell('')
end
for i,entry in ipairs(ui.materials)do
 local tile=make('TextButton',ui.materialList,{Name='Material'..entry[1],Text='',Position=UDim2.fromOffset(((i-1)%3)*92,math.floor((i-1)/3)*81),Size=UDim2.fromOffset(87,76),BackgroundColor3=Color3.fromRGB(66,55,44),ZIndex=14});stroke(tile)
 local viewport=make('ViewportFrame',tile,{Name='Preview',Position=UDim2.fromOffset(4,2),Size=UDim2.new(1,-8,1,-20),BackgroundTransparency=1,Ambient=Color3.fromRGB(190,190,190),LightColor=white,LightDirection=Vector3.new(-1,-1,-1),ZIndex=15,Active=false})
 local part=make('Part',viewport,{Name='Cube',Size=Vector3.new(2,2,2),Anchored=true,CanCollide=false,CanTouch=false,Material=Enum.Material[entry[1]],Color=Color3.fromRGB(entry[3],entry[4],entry[5]),Transparency=entry[6]or 0,CFrame=CFrame.new()})
 local camera=make('Camera',viewport,{CFrame=CFrame.lookAt(Vector3.new(3,2,4),Vector3.zero),FieldOfView=38});viewport.CurrentCamera=camera
 make('TextLabel',tile,{Text=entry[2],Position=UDim2.new(0,0,1,-18),Size=UDim2.new(1,0,0,18),BackgroundTransparency=1,TextSize=11,ZIndex=16})
 ui.materialButtons[entry[1]]=tile;connect(tile.Activated,safe(function()ui.chooseMaterial(entry[1])end))
end
function ui.refresh()
 ui.trowelSwitch.Visible=ui.equippedTool~=nil and ui.equippedTool==ui.tools.Trowel
 ui.trowelSwitch.Text=string.upper(ui.trowelMode)..'  ›'
 ui.trowelSwitch.BackgroundColor3=mode=='Mirror'and Color3.fromRGB(100,43,70)or Color3.fromRGB(35,29,25)
 ui.menuButton.Visible=not options.hideShortcut and ui.equippedTool~=nil
 for name,b in pairs(ui.materialButtons)do b.BackgroundColor3=name==ui.brush.material and Color3.fromRGB(143,107,53)or Color3.fromRGB(66,55,44)end
end
function ui.layout()
 local camera=workspace.CurrentCamera;if not camera then return end
 local v=camera.ViewportSize;local inset,bottom=GuiService:GetGuiInset();local height=v.Y-inset.Y-bottom.Y
 ui.switchScale.Scale=math.clamp(height/360,.85,1)
 ui.materialScale.Scale=math.clamp(math.min(1,(v.X-20)/294,(height-20)/322),.6,1)
 ui.materialWindow.Position=UDim2.new(.5,0,.5,0)
end
connect(UIS.InputChanged,safe(function(input)if ui.boxGesture then ui.changeBox(input,false)end end))
connect(Run.Heartbeat,function()local g=ui.boxGesture;if g and g.active then ui.changeBox(g.input.UserInputType==Enum.UserInputType.MouseButton1 and{UserInputType=Enum.UserInputType.MouseMovement,Position=g.point}or g.input,false)end end)

connect(title.InputBegan,function(input)
 if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
  finishDrag();panelDrag={input=input,start=Vector2.new(input.Position.X,input.Position.Y),position=Vector2.new(panel.Position.X.Offset,panel.Position.Y.Offset)}
  lockCamera('panel')
 end
end)
connect(UIS.InputChanged,function(input)
 if panelDrag and (input==panelDrag.input or panelDrag.input.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseMovement)then
  local delta=Vector2.new(input.Position.X,input.Position.Y)-panelDrag.start;panel.Position=UDim2.fromOffset(panelDrag.position.X+delta.X,panelDrag.position.Y+delta.Y);clampPanel()
 end
end)
connect(minimize.Activated,function()finishDrag();panel.Visible=false end)
local function overUI(pos)
 local inset=GuiService:GetGuiInset()
 local ok,list=pcall(function()return pg:GetGuiObjectsAtPosition(pos.X,pos.Y)end)
 if ok then for _,o in ipairs(list)do if o:IsDescendantOf(gui)and o~=ui.canvas and o~=ui.rectangle then return true end end end
 local function inside(frame)
  if not frame or not frame.Visible then return false end
  local p,s=frame.AbsolutePosition,frame.AbsoluteSize
  return pos.X>=p.X and pos.X<=p.X+s.X and pos.Y-inset.Y>=p.Y and pos.Y-inset.Y<=p.Y+s.Y
 end
 return inside(panel)or inside(exportWindow)or inside(ui.trowelSwitch)or inside(ui.menuButton)or inside(ui.materialWindow)
end
local pending={}
connect(UIS.InputBegan,function(input,processed)
 if input.UserInputType==Enum.UserInputType.Touch then
  lastTouch=input;lastTouchAt=os.clock()
  if drag and not drag.input then drag.input=input end
  if overUI(input.Position)then lockCamera(input)end
 end
 if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
  if mode=='Idle'then return end
  if ui.boxGesture then ui.blocked[input]=true;return end
  if not processed and not overUI(input.Position)and not drag and mode~='Place'then ui.beginBox(input)end
  if not processed and not overUI(input.Position)then pending[input]={pos=Vector2.new(input.Position.X,input.Position.Y),at=os.clock()}end
  return
 end
 if mode=='Idle'or processed or UIS:GetFocusedTextBox()then return end
 local ctrl=UIS:IsKeyDown(Enum.KeyCode.LeftControl)or UIS:IsKeyDown(Enum.KeyCode.RightControl)
 local k=input.KeyCode
 if ctrl and k==Enum.KeyCode.A then local parts={};for _,part in pairs(objects)do if exists(part)then table.insert(parts,part)end end;selectMany(parts)
 elseif ctrl and k==Enum.KeyCode.Z then safe(function()historyStep(history,redo,'undo')end)()
 elseif ctrl and k==Enum.KeyCode.Y then safe(function()historyStep(redo,history,'redo')end)()
 elseif ctrl and k==Enum.KeyCode.D then safe(duplicate)()
 elseif ctrl and k==Enum.KeyCode.S then safe(save)()
 elseif k==Enum.KeyCode.Delete then safe(deleteSelected)()
 elseif k==Enum.KeyCode.Escape then finishDrag();selectPart(nil)
 end
end)
local lastGizmo=0
if handles then connect(handles.MouseButton1Down,function()lastGizmo=os.clock()end)end
if arcs then connect(arcs.MouseButton1Down,function()lastGizmo=os.clock()end)end
connect(ui.mirrorHandles.MouseButton1Down,function()lastGizmo=os.clock()end)
connect(UIS.InputEnded,function(input)
 unlockCamera(input)
 if lastTouch==input then lastTouch=nil end
 if panelDrag and (input==panelDrag.input or input.UserInputType==Enum.UserInputType.MouseButton1 and panelDrag.input.UserInputType==Enum.UserInputType.MouseButton1)then panelDrag=nil;unlockCamera('panel')end
 if ui.blocked[input]then ui.blocked[input]=nil;pending[input]=nil;return end
 if ui.boxGesture and ui.boxGesture.input==input then local didSelect=ui.endBox(input);if didSelect then pending[input]=nil;return end end
 local touch=pending[input];pending[input]=nil
 local hadDrag=drag~=nil
 if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch and drag and (not drag.input or drag.input==input)then finishDrag()end
 if mode=='Idle'or not touch or hadDrag or os.clock()<blockWorldUntil or os.clock()-lastGizmo<.15 or os.clock()-touch.at>.8 or overUI(input.Position)then return end
 if (Vector2.new(input.Position.X,input.Position.Y)-touch.pos).Magnitude>10 then return end
 safe(function()
  local camera=workspace.CurrentCamera;if not camera then return end
  local ray=camera:ScreenPointToRay(input.Position.X,input.Position.Y)
  local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude
  local _,c=characterRoot();params.FilterDescendantsInstances=c and {c,gizmo}or {gizmo}
  local hit=workspace:Raycast(ray.Origin,ray.Direction*5000,params)
  if mode=='Place'then
   if hit then
    local size=(shape=='Ramp'or shape=='Corner')and Vector3.new(8,4,12)or shape=='Ball'and Vector3.new(4,4,4)or shape=='Cylinder'and Vector3.new(2,4,4)or(ui.brushSet and Vector3.new(2,2,2)or Vector3.new(8,1,8))
    local p=hit.Position;local n=hit.Normal
    local offset=(math.abs(n.X)*size.X+math.abs(n.Y)*size.Y+math.abs(n.Z)*size.Z)/2
    local at=p+n*offset;at=Vector3.new(snap(at.X,moveStep),snap(at.Y,moveStep),snap(at.Z,moveStep))
    spawnAt(CFrame.new(at));mode='Place';refresh()
   else tell('Tap a solid surface to place a piece.')end
  else local part=hit and objects[hit.Instance:GetAttribute('TrackPieceId')]or nil;if mode=='Delete'then if exists(part)then if not selection[part:GetAttribute('TrackPieceId')]then selectPart(part)end;deleteSelected()end;return end;local additive=multiSelect or UIS:IsKeyDown(Enum.KeyCode.LeftShift)or UIS:IsKeyDown(Enum.KeyCode.RightShift);if part or not additive then selectPart(part,additive)end end
 end)()
end)
local function cancelInteraction()
 if ui.cancelBox then ui.cancelBox(true)end;table.clear(ui.blocked)
 panelDrag=nil;lastTouch=nil;table.clear(pending);finishDrag();unlockAllCamera()
end
connect(UIS.WindowFocusReleased,cancelInteraction)
function ui.deactivate()
 cancelInteraction();ui.equippedTool=nil;mode='Idle';ui.materialWindow.Visible=false;panel.Visible=false
 refresh()
end
ui.toolSpecs={
 {'Hammer','846599039','Build blocks: equip to choose a material'},
 {'Trowel','7957079135','Move / Rotate / Clone / Mirror'},
 {'Scale','2783549943','Resize blocks with handles'},
 {'Paint','1198996683','Change selected block colors and materials'},
 {'Delete','846598820','Delete draft blocks; Undo restores them'},
 {'Properties','5107038616','Edit block settings, circles and saved drafts'}
}
function ui.installTools(backpack)
 if closed or ui.toolsEnabled==false then return end
 backpack=backpack or player:FindFirstChildOfClass('Backpack')
 if not backpack then return end
 for _,item in ipairs(ui.toolSpecs)do
  local name=item[1];local tool=ui.tools[name]
  local usable=tool and pcall(function()if tool.Parent~=player.Character and tool.Parent~=backpack then tool.Parent=backpack end end)
  if not usable then
   for _,c in ipairs(ui.toolListeners[name]or{})do c:Disconnect()end
   tool=make('Tool',nil,{Name=name,RequiresHandle=false,CanBeDropped=false,Enabled=true,ManualActivationOnly=false,TextureId='rbxassetid://'..item[2],ToolTip=item[3]})
   tool:SetAttribute('HeadLockTrackBuilderTool',true);ui.tools[name]=tool
   ui.toolListeners[name]={
    connect(tool.Equipped,safe(function()
     if closed or ui.tools[name]~=tool then return end
     cancelInteraction();ui.equippedTool=tool;ui.setTool(name)
    end)),
    connect(tool.Unequipped,function()if ui.equippedTool==tool then ui.deactivate()end end),
    connect(tool.AncestryChanged,function()
     if ui.equippedTool==tool and tool.Parent~=player.Character then ui.deactivate()end
    end)
   }
   tool.Parent=backpack
  end
 end
end
function ui.equip(name)
 if name=='Move'or name=='Rotate'or name=='Clone'or name=='Mirror'then ui.trowelMode=name;name='Trowel'end
 local tool=assert(ui.tools[name],'Unknown builder tool')
 local character=player.Character;local humanoid=character and character:FindFirstChildOfClass('Humanoid')
 assert(humanoid,'Wait for your character to spawn')
 if tool.Parent==character then ui.equippedTool=tool;ui.setTool(name)else humanoid:EquipTool(tool)end
 return tool
end
connect(player.CharacterRemoving,function()
 ui.deactivate()
 local backpack=player:FindFirstChildOfClass('Backpack')
 for _,tool in pairs(ui.tools)do if backpack then pcall(function()tool.Parent=backpack end)end end
end)
connect(player.CharacterAdded,function()
 ui.deactivate()
 task.defer(function()if not closed then ui.installTools()end end)
end)
connect(player.ChildAdded,function(child)
 if child:IsA('Backpack')then task.defer(function()if not closed then ui.installTools(child)end end)end
end)
ui.toolsEnabled=options.enabled~=false
ui.installTools(player:WaitForChild('Backpack'))
local elapsed=0
connect(Run.Heartbeat,function(dt)
 elapsed+=dt
 if elapsed>=5 then elapsed=0;if changed then pcall(draft)end;clampPanel()end
end)
function api.setEnabled(value)
 value=value==true
 if ui.toolsEnabled==value then return end
 ui.toolsEnabled=value
 if value then ui.installTools();ui.showMain('Edit')
 else
  ui.deactivate()
  if exportWindow then exportWindow:Destroy();exportWindow=nil;exportBox=nil end
  for _,listeners in pairs(ui.toolListeners)do for _,connection in ipairs(listeners)do connection:Disconnect()end end
  for _,tool in pairs(ui.tools)do pcall(function()tool:Destroy()end)end
  table.clear(ui.tools);table.clear(ui.toolListeners)
 end
end
api.openMenu=function()if ui.toolsEnabled then ui.showMain('Edit')end end
api.isEnabled=function()return ui.toolsEnabled==true end
api.isBusy=function()return drag~=nil end
api.sync=sync
function api.cleanup()
 if closed then return end
 cancelInteraction();pcall(draft);closed=true
 Run:UnbindFromRenderStep(cameraBinding)
 for _,c in ipairs(connections)do c:Disconnect()end
 for _,tool in pairs(ui.tools)do pcall(function()tool:Destroy()end)end
 table.clear(ui.tools);ui.equippedTool=nil
 gui:Destroy();gizmo:Destroy();_G.HeadLockTrackBuilderCleanup=nil
 if _G.HeadLockTrackBuilder==api then _G.HeadLockTrackBuilder=nil end
end
api.add=function(kind,cf)assert(kind=='Ramp'or kind=='Corner'or shapes[kind],'Unsupported shape');shape=kind;return spawnAt(cf or frontFrame())end
api.select=selectPart;api.selectMany=selectMany;api.selection=selectionParts;api.bounds=groupBounds;api.duplicate=duplicate;api.delete=deleteSelected;api.scale=scaleGroup;api.rotate=rotateGroup;api.edit=edit;api.undo=function()historyStep(history,redo,'undo')end;api.redo=function()historyStep(redo,history,'redo')end
api.clone=ui.cloneBy;api.mirror=function(face)return ui.mirrorBy(typeof(face)=='Vector3'and face or assert(faces[face],'Choose a mirror face'))end;api.tools=ui.tools;api.equip=ui.equip;api.setAxes=ui.setAxes;api.getAxes=ui.getAxes;api.ui=ui;api.circle=createCircle;api.save=save;api.export=exportText;api.import=import;api.normalize=normalize;api.document=document;api.clear=clear;api.parts=objects;api.gui=gui;api.mode=setMode;api.nudge=nudge
_G.HeadLockTrackBuilder=api;_G.HeadLockTrackBuilderCleanup=api.cleanup
connect(close.Activated,function()finishDrag();panel.Visible=false end)
local restored=false
if count()==0 and type(_G.HeadLockTrackDraft)=='table'then restored=pcall(import,_G.HeadLockTrackDraft)end
mode='Idle';setTab('Build');panel.Visible=false;content.Visible=false;minimized=true;panel.Size=UDim2.fromOffset(330,36);minimize.Text='+';clampPanel();ui.layout();refresh()
tell('')

return api
end
