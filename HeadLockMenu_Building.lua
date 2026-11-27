return function(SC,ctx)
local state={enabled=false,saves={},selected=nil,status='',saveBusy=false,listBusy=false}
SC.building=state
local function allowed()return SC.isOwnerAccount(ctx.player)and SC.ownerFeatures and not SC.closing and not SC.paused end
local function update()if state.update then state.update()end;if state.ownerUpdate then state.ownerUpdate()end end
local function report(text)state.status=text or'';update()end
local function api()
 if not state.api then
  assert(SC.isOwnerAccount(ctx.player),'Owner only')
  state.api=ctx.createBuilder({enabled=false,hideShortcut=true})
 end
 return state.api
end
local function localSaves()
 local data=_G.HeadLockNamedBuilds
 if type(data)~='table'and type(readfile)=='function'then local ok,value=pcall(function()return ctx.Http:JSONDecode(readfile('HeadLockNamedBuilds_v1.json'))end);if ok then data=value end end
 if type(data)~='table'then data={}end
 _G.HeadLockNamedBuilds=data;return data
end
local function cacheSave(saved,doc)
 local all=localSaves();local key=tostring(ctx.player.UserId)..':'..tostring(game.PlaceId)
 all[key]=all[key]or{};all[key][saved.id]={id=saved.id,name=saved.name,updatedAt=saved.updatedAt,parts=#doc.parts,doc=doc}
 if type(writefile)=='function'then pcall(writefile,'HeadLockNamedBuilds_v1.json',ctx.Http:JSONEncode(all))end
end
function SC.setBuilding(value)
 value=value==true and allowed()
 if not value then if state.enabled and SC.ownerSync then SC.ownerSync.pendingBuild=true end;state.enabled=false;if state.api then state.api.setEnabled(false)end;if state.prompt then state.prompt:Destroy();state.prompt=nil end;update();return false end
 local ok,why=pcall(function()
  local builder=api();local net=SC.ownerSync;local shared=net and net.docs[tostring(ctx.player.UserId)]
  if shared and(#builder.document().parts==0 or net.publishBlocked)then builder.import(shared)end
  if net then net.publishBlocked=false end
  builder.setEnabled(true);builder.openMenu();state.enabled=true
  if net and shared and net.replicas[tostring(ctx.player.UserId)]then net.replicas[tostring(ctx.player.UserId)].folder:Destroy();net.replicas[tostring(ctx.player.UserId)]=nil end
 end)
 if not ok then report(tostring(why));return false end
 update();return true
end
function state.save(name,saveId)
 if not allowed()or state.saveBusy then return end
 name=tostring(name or''):match('^%s*(.-)%s*$'):gsub('%c',''):sub(1,80)
 if name==''then report('Enter a name');return end
 local net=SC.ownerSync;if not net or not net.owner then report('Private owner access required');return end
 local ok,doc=pcall(function()return api().document()end);if not ok then report(tostring(doc));return end
 doc.name=name;saveId=saveId or ctx.Http:GenerateGUID(false):gsub('[{}%-]','')
 state.saveBusy=true;report('Saving')
 net.enqueue('save',{saveId=saveId,name=name,doc=doc},function(success,data)
  state.saveBusy=false
  if success then cacheSave(data.saved,doc);state.selected=data.saved;report('Saved '..name);if state.prompt then state.prompt:Destroy();state.prompt=nil end;state.list()
  else report('Save failed: '..tostring(data))end
 end)
end
function state.list()
 if not allowed()or state.listBusy then return end
 local net=SC.ownerSync;if not net or not net.owner then report('Private owner access required');return end
 state.listBusy=true
 net.enqueue('list',{},function(success,data)
  state.listBusy=false
  if success then state.saves=data.saves or{};state.status=''else state.status='Saves unavailable: '..tostring(data)end
  update()
 end)
end
function state.load()
 if not allowed()or not state.selected or state.saveBusy then return end
 local chosen=state.selected;local net=SC.ownerSync
 if not net or not net.owner then report('Private owner access required');return end
 state.saveBusy=true;report('Loading')
 net.enqueue('load',{saveId=chosen.id},function(success,data)
  state.saveBusy=false
  if not success then report('Load failed: '..tostring(data));return end
  local ok,why=pcall(function()api().import(data.doc)end)
  if ok then net.pendingBuild=true;report('Loaded '..chosen.name)else report('Load failed: '..tostring(why))end
 end)
end
function state.namePrompt()
 if not allowed()then return end
 if state.prompt then state.prompt:Destroy()end
 local make,button=ctx.make,ctx.button
 local frame=make('Frame',{Name='BuildNamePrompt',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(300,156),BackgroundColor3=ctx.black,ZIndex=25,Active=true},ctx.gui);state.prompt=frame
 make('UIStroke',{Color=ctx.white,Thickness=1},frame)
 make('TextLabel',{Text='Build name',Position=UDim2.fromOffset(12,8),Size=UDim2.new(1,-24,0,26),BackgroundTransparency=1,TextColor3=ctx.white,TextSize=16,Font=Enum.Font.Code,ZIndex=26},frame)
 local name=make('TextBox',{Name='BuildSaveName',Text='',PlaceholderText='Name',ClearTextOnFocus=false,Position=UDim2.fromOffset(12,44),Size=UDim2.new(1,-24,0,34),BackgroundColor3=ctx.black,TextColor3=ctx.white,TextSize=15,Font=Enum.Font.Code,ZIndex=26},frame);make('UIStroke',{Color=ctx.white,Thickness=1},name)
 local save=button('Save',frame);save.Position=UDim2.fromOffset(12,100);save.Size=UDim2.fromOffset(130,34);save.ZIndex=26
 local cancel=button('Cancel',frame);cancel.Position=UDim2.fromOffset(158,100);cancel.Size=UDim2.fromOffset(130,34);cancel.ZIndex=26
 local existing
 name:GetPropertyChangedSignal('Text'):Connect(function()existing=nil;save.Text='Save'end)
 save.Activated:Connect(function()
  local text=name.Text:match('^%s*(.-)%s*$');local match
  for _,item in ipairs(state.saves)do if item.name:lower()==text:lower()then match=item;break end end
  if match and existing~=match.id then existing=match.id;save.Text='Overwrite';return end
  state.save(text,match and match.id or nil)
 end)
 cancel.Activated:Connect(function()frame:Destroy();if state.prompt==frame then state.prompt=nil end end)
 name:CaptureFocus()
end
function SC.drawBuilding(container)
 if not allowed()then return end
 local make,button=ctx.make,ctx.button
 local panel=make('ScrollingFrame',{Name='BuildingSettings',Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,CanvasSize=UDim2.fromOffset(0,500)},container)
 make('TextLabel',{Text='Building',Size=UDim2.new(1,0,0,30),BackgroundTransparency=1,TextColor3=ctx.white,TextSize=20,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left},panel)
 local toggle=button('OFF',panel);toggle.Name='BuildingToggle';toggle.Position=UDim2.fromOffset(0,38);toggle.Size=UDim2.fromOffset(105,36)
 local save=button('Save Build',panel);save.Name='SaveBuild';save.Position=UDim2.fromOffset(0,90);save.Size=UDim2.new(.5,-3,0,34)
 local saves=button('Saves',panel);saves.Position=UDim2.new(.5,3,0,90);saves.Size=UDim2.new(.5,-3,0,34)
 local list=make('ScrollingFrame',{Name='BuildSaves',Position=UDim2.fromOffset(0,134),Size=UDim2.new(1,-3,0,232),CanvasSize=UDim2.new(),BorderSizePixel=0,ScrollBarThickness=3,BackgroundTransparency=1,Visible=false},panel)
 local load=button('Load Build',panel);load.Name='LoadBuild';load.Position=UDim2.fromOffset(0,376);load.Size=UDim2.new(1,0,0,34)
 local status=make('TextLabel',{Name='BuildingStatus',Position=UDim2.fromOffset(0,420),Size=UDim2.new(1,0,0,64),BackgroundTransparency=1,TextWrapped=true,TextColor3=ctx.white,TextSize=13,Font=Enum.Font.Code},panel)
 local rows={};local last=''
 state.update=function()
  if not panel.Parent then state.update=nil;return end
  toggle.Text=state.enabled and'ON'or'OFF';toggle.BackgroundColor3=state.enabled and ctx.white or ctx.black;toggle.TextColor3=state.enabled and ctx.black or ctx.white
  status.Text=state.status~=''and state.status or(SC.ownerSync and SC.ownerSync.error or'')
  local key=ctx.Http:JSONEncode(state.saves)..':'..tostring(state.selected and state.selected.id)
  if key~=last then
   last=key;for _,row in ipairs(rows)do row:Destroy()end;rows={}
   for i,item in ipairs(state.saves)do
    local row=button(item.name,list);row.Name='BuildSave_'..item.id;row.Position=UDim2.fromOffset(0,(i-1)*38);row.Size=UDim2.new(1,-6,0,34);row.TextXAlignment=Enum.TextXAlignment.Left;row.TextTruncate=Enum.TextTruncate.AtEnd
    local selected=state.selected and state.selected.id==item.id;row.BackgroundColor3=selected and ctx.white or ctx.black;row.TextColor3=selected and ctx.black or ctx.white
    row.Activated:Connect(function()state.selected=item;update()end);table.insert(rows,row)
   end
   list.CanvasSize=UDim2.fromOffset(0,#state.saves*38)
  end
 end
 toggle.Activated:Connect(function()SC.setBuilding(not state.enabled)end)
 save.Activated:Connect(function()state.namePrompt()end)
 saves.Activated:Connect(function()list.Visible=not list.Visible;if list.Visible then state.list()end end)
 load.Activated:Connect(state.load)
 state.update();if state.enabled and state.api then state.api.openMenu()end
end
function SC.drawOwnerPanel(container)
 if not allowed()then return end
 local make,button=ctx.make,ctx.button
 local panel=make('Frame',{Size=UDim2.fromScale(1,1),BackgroundTransparency=1},container)
 make('TextLabel',{Text='Owner Panel',Size=UDim2.new(1,0,0,30),BackgroundTransparency=1,TextColor3=ctx.white,TextSize=20,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left},panel)
 local status=make('TextLabel',{Name='OwnerStatus',Position=UDim2.fromOffset(0,34),Size=UDim2.new(1,0,0,38),TextWrapped=true,BackgroundTransparency=1,TextColor3=ctx.white,TextSize=12,Font=Enum.Font.Code},panel)
 local list=make('ScrollingFrame',{Name='OwnerUsers',Position=UDim2.fromOffset(0,80),Size=UDim2.new(1,0,1,-80),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,CanvasSize=UDim2.new()},panel)
 local last='';local rows={}
 state.ownerUpdate=function()
  if not panel.Parent then state.ownerUpdate=nil;return end
  local net=SC.ownerSync;status.Text=net and net.error or'Connecting'
  local users=net and net.roster or{};local visible={}
  for _,user in ipairs(users)do table.insert(visible,{user.session,user.username,user.owner,user.actual.paused,user.actual.soundsPaused,user.pending})end
  local fingerprint=ctx.Http:JSONEncode(visible)
  if fingerprint==last then return end;last=fingerprint
  for _,row in ipairs(rows)do row:Destroy()end;rows={}
  local count=0
  for _,user in ipairs(users)do if not user.owner then
   local frame=make('Frame',{Name='OwnerUser_'..user.session,Position=UDim2.fromOffset(0,count*92),Size=UDim2.new(1,-6,0,86),BackgroundTransparency=1},list);table.insert(rows,frame);count+=1
   make('TextLabel',{Text=user.username,Position=UDim2.fromOffset(0,0),Size=UDim2.new(.62,0,0,28),TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,BackgroundTransparency=1,TextColor3=ctx.white,TextSize=14,Font=Enum.Font.Code},frame)
   local flags=(user.actual.paused and'Paused'or'Active')..(user.actual.soundsPaused and' / Muted'or'')..(user.pending and' …'or'')
   make('TextLabel',{Text=flags,Position=UDim2.new(.62,0,0,0),Size=UDim2.new(.38,0,0,28),BackgroundTransparency=1,TextColor3=ctx.white,TextSize=10,Font=Enum.Font.Code},frame)
   for i,item in ipairs({{'Pause','pause'},{'Resume','resume'},{'Mute','mute'},{'Unmute','unmute'},{'Kick','kick'}})do
    local b=button(item[1],frame);b.Name='Owner_'..item[2];b.Position=UDim2.new((i-1)/5,0,0,36);b.Size=UDim2.new(.2,-3,0,34);b.TextSize=11
    b.Activated:Connect(function()if allowed()and net then net.command(user.session,item[2])end end)
   end
  end end
  list.CanvasSize=UDim2.fromOffset(0,count*92)
 end
 state.ownerUpdate()
end
function state.cleanup()
 state.update=nil;state.ownerUpdate=nil
 if state.prompt then state.prompt:Destroy();state.prompt=nil end
 if state.api then state.api.cleanup();state.api=nil end
end
return state
end
